#!/usr/bin/env python3
"""Scaffold a new managed service: definition + chart + software template."""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TEMPLATES_DIR = os.path.join(ROOT, 'scripts', 'templates')


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
    return content


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


def main():
    if len(sys.argv) < 2:
        print("Usage: make new SERVICE=<name>")
        sys.exit(1)

    name = sys.argv[1].lower()
    kind = to_kind(name)
    title = to_title(name)
    plural = name + 's'

    replacements = {
        '__SERVICE_NAME__': name,
        '__SERVICE_KIND__': kind,
        '__SERVICE_PLURAL__': plural,
        '__SERVICE_TITLE__': title,
        '__TIMEOUT__': '10m',
        '__API_GROUP__': 'managedservices.thecodingsheikh.io',
        '__REPO_NAME__': 'managed-services',
        '__REPO_URL__': 'https://github.com/thecodingsheikh/managed-services',
        '__TEMPLATE_BASE_URL__': 'https://github.com/thecodingsheikh/managed-services/blob/main',
    }

    # Definition
    out = strip_header_comments(render('rgd.yaml.tpl', replacements))
    defn_path = os.path.join(ROOT, 'definitions', f"{name}.yaml")
    write(defn_path, out)
    print(f"  → definitions/{name}.yaml")

    # Chart
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

    # Software template
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


if __name__ == '__main__':
    main()
