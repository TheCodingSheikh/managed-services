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
| `lib.argocdRBAC`      | 3 fixed ArgoCD roles (`admin`/`edit`/`view`) + 3 bindings per release. Bindings' subjects are the matching Keycloak client role of the same name. |
| `lib.keycloakRBAC`    | 3 fixed Keycloak client roles (matching the ArgoCD role names) + one Roles mapping per owner, linking their user/group to their role's client role. |

Use them from a chart's `rbac.yaml`:

```yaml
{{- include "lib.argocdRBAC"   . }}
---
{{- include "lib.keycloakRBAC" . }}
```

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
