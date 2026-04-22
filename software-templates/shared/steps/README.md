# Shared Steps

Reusable Backstage scaffolder steps. Templates include them with `$yaml:` references so one change propagates everywhere.

## The three steps

| Step | Backstage action | What it does |
|---|---|---|
| `fetch-tenant`   | `catalog:fetch`               | Loads the tenant entity picked in the form and exposes its `spec.owners`. |
| `fetch-template` | `fetch:template`              | Renders `skeleton/manifest.yaml` with form parameters + the tenant's owners. |
| `push-manifest`  | `publish:github:pull-request` | Opens a PR on the releases repo. |

## Order

```yaml
steps:
  - $yaml: <repo>/software-templates/shared/steps/fetch-tenant.yaml
  - $yaml: <repo>/software-templates/shared/steps/fetch-template.yaml
  - $yaml: <repo>/software-templates/shared/steps/push-manifest.yaml
```

The tenant template skips `fetch-tenant` (there's no owning tenant to look up).

## Target paths in the releases repo

- Tenant: `<tenant>/manifest.yaml`
- Service: `<tenant>/<service>/<instance>/manifest.yaml`
