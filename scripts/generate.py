#!/usr/bin/env python3
"""Scaffold a managed service: definition + chart + software template.

Usage:
    python3 scripts/generate.py <name>            # scaffold a new service
    python3 scripts/generate.py --regen-defs      # regenerate every definitions/*.yaml
                                                  #   from the charts that exist
"""
import glob
import os
import re
import sys

# ─────────────────────────────────────────────────────────────────────────────
# Fork config — edit these once when you fork, then commit.
# Every scaffolded chart, RGD, and software template uses these values.
# ─────────────────────────────────────────────────────────────────────────────
API_GROUP   = 'managedservices.thecodingsheikh.io'
REPO_OWNER  = 'thecodingsheikh'
REPO_NAME   = 'managed-services'
RGD_TIMEOUT = '10m'
# ─────────────────────────────────────────────────────────────────────────────

REPO_URL = f'https://github.com/{REPO_OWNER}/{REPO_NAME}'
TEMPLATE_BASE_URL = f'{REPO_URL}/blob/main'

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TEMPLATES_DIR = os.path.join(ROOT, 'scripts', 'templates')


# KRO ResourceGraphDefinition body. Every service's RGD is pure boilerplate
# derived from its chart name — the only per-service inputs are the kind and
# chart path. Keeping this inline (instead of as a .tpl file) removes one file
# and guarantees every definitions/*.yaml stays in sync with its chart.
RGD_TEMPLATE = """\
apiVersion: kro.run/v1alpha1
kind: ResourceGraphDefinition
metadata:
  name: {name}
spec:
  schema:
    apiVersion: v1alpha1
    group: {api_group}
    kind: {kind}
    spec:
      values: object
  resources:
    - id: release
      readyWhen:
        - ${{release.status.conditions.exists(c, c.type == 'Ready' && c.status == 'True')}}
      template:
        apiVersion: helm.toolkit.fluxcd.io/v2beta2
        kind: HelmRelease
        metadata:
          name: ${{schema.metadata.name}}
          namespace: ${{schema.metadata.namespace}}
          ownerReferences:
            - apiVersion: ${{schema.apiVersion}}
              kind: ${{schema.kind}}
              name: ${{schema.metadata.name}}
              uid: ${{schema.metadata.uid}}
              blockOwnerDeletion: true
              controller: false
          annotations:
            argocd.argoproj.io/tracking-id: ${{schema.metadata.?annotations["argocd.argoproj.io/tracking-id"]}}
        spec:
          releaseName: ${{schema.metadata.name}}
          targetNamespace: ${{schema.metadata.namespace}}
          chart:
            spec:
              reconcileStrategy: Revision
              chart: charts/{name}
              sourceRef:
                kind: GitRepository
                name: {repo_name}
                namespace: {repo_name}
              interval: 5m
          interval: 15m
          driftDetection:
            mode: enabled
          values: ${{schema.spec.values}}
          install:
            remediation:
              retries: 3
          upgrade:
            remediation:
              retries: 3
              remediateLastFailure: true
          timeout: {timeout}
"""


def to_kind(name):
    """postgres → Postgres, full-stack → FullStack"""
    return ''.join(w.capitalize() for w in name.split('-'))


def to_title(name):
    """postgres → Postgres, full-stack → Full Stack"""
    return ' '.join(w.capitalize() for w in name.split('-'))


def render(template_path, replacements):
    with open(os.path.join(TEMPLATES_DIR, template_path)) as f:
        content = f.read()
    for token, value in replacements.items():
        content = content.replace(token, value)
    leftover = re.findall(r'__[A-Z0-9_]+__', content)
    if leftover:
        raise RuntimeError(f"{template_path}: unresolved tokens {sorted(set(leftover))}")
    return content


def render_rgd(name):
    return RGD_TEMPLATE.format(
        name=name,
        kind=to_kind(name),
        api_group=API_GROUP,
        repo_name=REPO_NAME,
        timeout=RGD_TIMEOUT,
    )


def strip_header_comments(content):
    lines = [l for l in content.split('\n') if not l.startswith('#')]
    return '\n'.join(lines).strip() + '\n'


def write(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w') as f:
        f.write(content)


def update_all_yaml(name):
    path = os.path.join(ROOT, 'software-templates', 'all.yaml')
    target = f"./{name}/template.yaml"
    if os.path.exists(path):
        with open(path) as f:
            content = f.read()
        if target not in content:
            content = content.rstrip('\n') + f"\n    - {target}\n"
            with open(path, 'w') as f:
                f.write(content)


def list_service_charts():
    """Names of every chart under charts/ that isn't the library chart."""
    names = []
    for chart_yaml in glob.glob(os.path.join(ROOT, 'charts', '*', 'Chart.yaml')):
        name = os.path.basename(os.path.dirname(chart_yaml))
        if name != 'lib':
            names.append(name)
    return sorted(names)


def regen_definitions():
    names = list_service_charts()
    if not names:
        print("No service charts found under charts/.")
        return
    for name in names:
        write(os.path.join(ROOT, 'definitions', f"{name}.yaml"), render_rgd(name))
        print(f"  → definitions/{name}.yaml")
    print(f"✅ Regenerated {len(names)} definition(s)")


def scaffold(name):
    kind = to_kind(name)
    title = to_title(name)
    plural = name + 's'

    replacements = {
        '__SERVICE_NAME__': name,
        '__SERVICE_KIND__': kind,
        '__SERVICE_PLURAL__': plural,
        '__SERVICE_TITLE__': title,
        '__API_GROUP__': API_GROUP,
        '__REPO_NAME__': REPO_NAME,
        '__REPO_URL__': REPO_URL,
        '__TEMPLATE_BASE_URL__': TEMPLATE_BASE_URL,
    }

    write(os.path.join(ROOT, 'definitions', f"{name}.yaml"), render_rgd(name))
    print(f"  → definitions/{name}.yaml")

    chart_dir = os.path.join(ROOT, 'charts', name)
    if os.path.exists(chart_dir):
        print(f"  ⏭ charts/{name}/ exists")
    else:
        write(os.path.join(chart_dir, 'Chart.yaml'), render('chart/Chart.yaml.tpl', replacements))
        write(os.path.join(chart_dir, 'values.yaml'), render('chart/values.yaml.tpl', replacements))
        write(os.path.join(chart_dir, 'values.schema.json'), render('chart/values.schema.json.tpl', replacements))
        write(os.path.join(chart_dir, 'templates', 'NOTES.txt'), render('chart/NOTES.txt.tpl', replacements))
        write(os.path.join(chart_dir, '.helmignore'), ".DS_Store\n.git/\n*.swp\n*.bak\n*.tmp\n")
        print(f"  ✅ charts/{name}/")

    st_dir = os.path.join(ROOT, 'software-templates', name)
    if os.path.exists(st_dir):
        print(f"  ⏭ software-templates/{name}/ exists")
    else:
        tpl = strip_header_comments(render('software-template/template.yaml.tpl', replacements))
        write(os.path.join(st_dir, 'template.yaml'), tpl)
        write(os.path.join(st_dir, 'skeleton', 'manifest.yaml'),
              render('software-template/skeleton/manifest.yaml.tpl', replacements))
        update_all_yaml(name)
        print(f"  ✅ software-templates/{name}/")

    print("✅ Done")


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 scripts/generate.py <name>")
        print("       python3 scripts/generate.py --regen-defs")
        sys.exit(1)

    arg = sys.argv[1]
    if arg == '--regen-defs':
        regen_definitions()
    else:
        scaffold(arg.lower())


if __name__ == '__main__':
    main()
