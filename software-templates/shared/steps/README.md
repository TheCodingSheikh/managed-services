# Shared Steps

Reusable Backstage scaffolder steps. Templates include them with `$yaml:` references so one change propagates everywhere.

## The two steps

| Step | Backstage action | What it does |
|---|---|---|
| `fetch-template` | `fetch:template`              | Renders `skeleton/manifest.yaml` with form parameters + the resolved short tenant name. |
| `push-manifest`  | `publish:github:pull-request` | Opens a PR on the releases repo. |

## Order

```yaml
steps:
  - $yaml: <repo>/software-templates/shared/steps/fetch-template.yaml
  - $yaml: <repo>/software-templates/shared/steps/push-manifest.yaml
```

## Owners

Service skeletons do **not** set `lab.backstage.io/owners`. The tenant chart writes the annotation onto Capsule's `namespaceOptions.additionalMetadataList`, so every namespace under the tenant inherits it. The Backstage Kubernetes ingestor resolves owners from the namespace when the workload itself doesn't carry the annotation, which means tenant owner edits propagate to all services automatically — no per-service manifest update needed.

This requires the `inheritOwnerFromNamespace: true` flag on the Kubernetes catalog provider in `app-config.yaml`.

## Target paths in the releases repo

- Tenant: `<tenant>/manifest.yaml`
- Service: `<tenant>/<service>/<instance>/manifest.yaml`
