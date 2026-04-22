# Managed Services Framework

A self-service platform for running multi-tenant managed services on Kubernetes. Developers create services from a Backstage form; GitOps takes care of the rest.

> **One schema per service.** `values.schema.json` drives the Helm chart, the KRO-generated Kubernetes API, and the Backstage form — no duplication.

## How it works

Two repos, two roles:

- **This repo (`managed-services`)** — the *platform*: Helm charts, KRO definitions, Backstage templates, scaffolder. Rarely changes per tenant.
- **`managed-services-releases`** — the *state*: one manifest per live tenant or service. Backstage PRs land here; ArgoCD reconciles from here.

And three layers inside the cluster:

1. **Domain CR** (`Tenant`, `Postgres`, …) — what users create. Shape defined by `values.schema.json`.
2. **KRO ResourceGraphDefinition** — watches the CR and emits a Flux `HelmRelease`.
3. **Helm chart** — renders the actual Kubernetes resources.

## Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         Developer Portal (Backstage)                    │
│                                                                         │
│   Software Template (parameters from values.schema.json)                │
│     ├─ scaffolder-field-validator  "is this name already taken?"        │
│     └─ entity-scaffolder           edit an existing CR via the form     │
│                                                                         │
│   Catalog (ingested from the cluster)                                   │
│     ├─ catalog-backend-module-kubernetes   CRs → Backstage entities     │
│     └─ multi-owner (+ processor)           multiple owners, with roles  │
└───────────────────────────────────┬─────────────────────────────────────┘
                                    │ pull request
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    managed-services-releases (Git)                      │
│                                                                         │
│   <tenant>/manifest.yaml                      ← Tenant CR               │
│   <tenant>/<service>/<name>/manifest.yaml     ← Service CR              │
└───────────────────────────────────┬─────────────────────────────────────┘
                                    │ ArgoCD syncs
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          Kubernetes Cluster                             │
│                                                                         │
│   Domain CR  ──▶  KRO RGD  ──▶  Flux HelmRelease  ──▶  Helm chart       │
│                                                          │              │
│                                                          ▼              │
│                                           Capsule Tenant (isolation)    │
│                                           ArgoCD roles   (per owner)    │
│                                           Keycloak roles (per owner)    │
│                                           …your workloads               │
└─────────────────────────────────────────────────────────────────────────┘
```

## Backstage plugins

All four live in [TheCodingSheikh/backstage-plugins](https://github.com/TheCodingSheikh/backstage-plugins) and are required:

| Plugin | Role |
|---|---|
| [`scaffolder-field-validator`](https://github.com/TheCodingSheikh/backstage-plugins/tree/main/plugins/scaffolder-field-validator) | Validates form fields against a backend API before submission (e.g. *"tenant name already in use"*). Used via `ui:field: ScaffolderFieldValidator` in templates. |
| [`entity-scaffolder`](https://github.com/TheCodingSheikh/backstage-plugins/tree/main/plugins/entity-scaffolder/entity-scaffolder) | Embeds the scaffolder workflow inside an entity page so a CR can be edited with the same form that created it. Activated by the `backstage.io/scaffolder-template` + `last-applied-configuration` annotations we emit on every CR. |
| [`multi-owner`](https://github.com/TheCodingSheikh/backstage-plugins/tree/main/plugins/multi-owner/multi-owner) + [`…-multi-owner-processor`](https://github.com/TheCodingSheikh/backstage-plugins/tree/main/plugins/multi-owner/catalog-backend-module-multi-owner-processor) | Lets an entity have several owners, each with a role. Backend processor turns `spec.owners` into proper `ownedBy`/`ownerOf` relations; frontend card displays them. This is what makes the `owners` array meaningful in the catalog. |
| [`catalog-backend-module-kubernetes`](https://github.com/TheCodingSheikh/backstage-plugins/tree/main/plugins/catalog-backend-module-kubernetes) | Ingests Kubernetes CRs as Backstage entities (Components, Systems). The `lab.backstage.io/*` annotations on our skeleton manifests tell it what to create. |

## Project layout

```
managed-services/
├── argocd/                # ArgoCD bootstrap
│   └── applicationset.yaml #   Generates one Application per manifest in the releases repo
├── charts/                # Helm charts
│   ├── lib/               #   Shared helpers (labels, argocd + keycloak RBAC)
│   └── tenant/            #   The only hand-written chart today
├── definitions/           # KRO ResourceGraphDefinitions (auto-generated)
│   ├── gitrepository.yaml #   Flux source pointing at this repo
│   └── tenant.yaml        #   Regenerate with `make regen-defs`
├── software-templates/
│   ├── shared/            #   Shared parameters + steps used by every template
│   └── tenant/            #   Tenant template (special: no owning tenant to fetch)
├── scripts/
│   └── generate.py        # Scaffolds a new service
└── Makefile
```

## Commands

```bash
make new SERVICE=postgres   # Scaffold a new service (chart + RGD + template)
make regen-defs             # Regenerate every definitions/*.yaml from its chart
make lint                   # helm lint every chart
make template               # helm template (dry-run render) every chart
make validate               # Validate values.yaml against values.schema.json
make all                    # lint + validate
```

## Adding a new service

```bash
make new SERVICE=postgres
```

This writes:
- `charts/postgres/` — chart skeleton (depends on `lib`)
- `definitions/postgres.yaml` — the RGD
- `software-templates/postgres/` — Backstage template + skeleton, registered in `all.yaml`

Naming: `postgres` → `Postgres`, `full-stack` → `FullStack`. Kebab-case input, PascalCase Kubernetes kind.

Then customize four files in sync:

| File | Add |
|---|---|
| `charts/postgres/values.schema.json` | Properties for `spec.values` |
| `charts/postgres/templates/` | Kubernetes resources that consume those values |
| `software-templates/postgres/template.yaml` | Form parameters matching the schema |
| `software-templates/postgres/skeleton/manifest.yaml` | Map form input → CR body |

## Forking

Fork-specific values (API group, GitHub org, repo name, RGD timeout) live in one place: the **fork config block** at the top of [`scripts/generate.py`](scripts/generate.py). Edit once, commit, done.

After changing `API_GROUP`, run `make regen-defs` so every `definitions/*.yaml` picks up the new value.

A few handwritten files still reference these values directly — update them on a fresh fork:

| What              | Where                                                                                             |
|-------------------|---------------------------------------------------------------------------------------------------|
| API group         | `software-templates/tenant/template.yaml`                                                         |
| GitHub org/repo   | `software-templates/tenant/template.yaml`                                                         |
| Releases repo     | `software-templates/shared/steps/push-manifest.yaml`, `argocd/applicationset.yaml` (2 `repoURL`s) |
