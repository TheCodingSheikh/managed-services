# Helm Charts

One deployable chart per managed service. The chart is what Flux ultimately renders into the cluster.

## Layout

```
charts/
├── lib/        # Library chart — helpers only, never deployed standalone
└── tenant/     # The tenant chart (multi-tenancy, RBAC)
```

Every service chart depends on `lib` via `file://../lib`.

## What `lib` provides

Helpers included by every service chart:

| Helper                | Purpose                                                                 |
|-----------------------|-------------------------------------------------------------------------|
| `lib.name` / `lib.fullname` / `lib.chart` | Standard naming.                                            |
| `lib.labels`          | Common labels (`app.kubernetes.io/*`, `part-of: managed-services`).     |
| `lib.selectorLabels`  | Immutable selector labels.                                              |
| `lib.argocdAnnotations` | ArgoCD tracking annotation for Flux-managed resources.                |
| `lib.argocdRBAC`      | 3 ArgoCD roles (`admin`/`edit`/`view`) + 3 bindings. Objects match `managed-services/<release>*`, so the tenant's roles also cover every service released under it. |
| `lib.vaultRBAC`       | 3 Vault policies (same levels) granting access under `<release>/*`. Uses Crossplane's Vault provider by default — adjust the `apiVersion` if you use a different one. |
| `lib.keycloakRBAC`    | 6 Keycloak client roles (3 per client: `lab-argo-cd-client`, `lab-vault-client`), plus one Roles mapping per owner per client that links their user/group to the role matching their role field. |

Use them from a chart's `rbac.yaml`:

```yaml
{{- include "lib.argocdRBAC"   . }}
---
{{- include "lib.keycloakRBAC" . }}
---
{{- include "lib.vaultRBAC"    . }}
```

Only the tenant chart needs this today — the wildcard matching in ArgoCD objects and Vault paths means the tenant's role set automatically covers every service inside it.

## Adding a chart

```bash
make new SERVICE=postgres
```

Then:

1. Add properties to `charts/postgres/values.schema.json`.
2. Add Kubernetes templates under `charts/postgres/templates/`.
3. `make lint` to validate.

## Composite services

If a service bundles others (e.g. `fullstack` = `postgres` + `redis`), **don't** use Helm sub-chart dependencies — instead, emit the constituent CRs (`kind: Postgres`, `kind: Redis`) from your chart's templates. KRO picks them up the same way it picks up user-created ones, so composition stays uniform.
