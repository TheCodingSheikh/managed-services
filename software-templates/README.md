# Software Templates

Backstage scaffolder templates. Each one produces a CR manifest and opens a PR against the releases repo.

## Layout

```
software-templates/
├── shared/
│   ├── parameters/
│   │   └── tenant-selector.yaml   # Tenant picker (EntityPicker filtered to tenants)
│   └── steps/                      # fetch-template, push-manifest
├── tenant/                         # Tenant template (special — see below)
│   ├── template.yaml
│   └── skeleton/manifest.yaml
├── <service>/                      # One folder per service, scaffolded
└── all.yaml                        # Backstage location file, auto-updated
```

## Where manifests end up

The push step writes to the releases repo at:

```
<releases-repo>/<tenant>/manifest.yaml                          ← Tenant
<releases-repo>/<tenant>/<service>/<instance>/manifest.yaml     ← Service instance
```

ArgoCD reconciles that repo into the cluster.

## Template shape

Every service template follows the same two steps:

1. **`fetch-template`** — render the skeleton with form params and the resolved short tenant name.
2. **`push-manifest`** — open a PR on the releases repo.

Owners are **not** copied into service manifests. The tenant chart writes `lab.backstage.io/owners` onto Capsule's `namespaceOptions.additionalMetadataList`, so every namespace under the tenant carries the annotation; the Backstage Kubernetes ingestor inherits it for any workload that doesn't set its own. Editing a tenant's owners therefore propagates to every service in the tenant without touching service manifests.

The **tenant template** keeps its own `owners` form field — it's the source of truth.

## Adding a template

```bash
make new SERVICE=<name>
```

Then wire three files to each other:

| File | Add |
|---|---|
| `charts/<name>/values.schema.json` | Properties for `spec.values` |
| `software-templates/<name>/template.yaml` | Form parameters matching the schema |
| `software-templates/<name>/skeleton/manifest.yaml` | Map form input → CR body |

A property that exists in the schema but not in the form will silently fail at HelmRelease time — keep them in sync.
