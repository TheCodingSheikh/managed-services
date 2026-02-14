# Managed Services Framework

A Kubernetes-native framework for building self-service managed services using Helm, KRO, and Backstage — deployed via GitOps.

> **One schema. Three systems.** Each service's `values.schema.json` drives Helm validation, generates custom Kubernetes APIs (via KRO), and renders Backstage self-service forms.

## Architecture

```
┌───────────────────────────────────────────────────────────────────────────────┐
│                              Developer Portal                                │
│  ┌─────────────────────────────────────────────────────────────────────────┐  │
│  │  Backstage Software Template                                           │  │
│  │  (parameters derived from values.schema.json)                         │  │
│  └───────────────────────────────┬─────────────────────────────────────────┘  │
└──────────────────────────────────┼────────────────────────────────────────────┘
                                   │ Creates Pull Request
                                   ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                           Releases Git Repository                                    │
│  <tenant>/                                                  │
│    ├── manifest.yaml              (Tenant CR)                               │
│    └── <service>/<name>/                                                    │
│        └── manifest.yaml          (Service CR)                              │
└───────────────────────────────────┼─────────────────────────────────────────┘
                                    │ ArgoCD syncs
                                    ▼
┌───────────────────────────────────────────────────────────────────────────────┐
│                          Kubernetes Cluster                                   │
│                                                                              │
│  KRO ResourceGraphDefinition ──▶ Flux HelmRelease ──▶ Helm Chart deployed   │
│                                                                              │
└───────────────────────────────────────────────────────────────────────────────┘
```

## Project Structure

```
managed-services/
├── Makefile
├── charts/                        # Helm charts
│   ├── lib/                       #   Shared library (helpers, resource mappings)
│   └── tenant/                    #   Multi-tenant isolation (Core)
├── definitions/                   # KRO ResourceGraphDefinitions
│   ├── gitrepository.yaml         #   Flux GitRepository source
│   └── tenant.yaml                #   Tenant RGD (Core)
├── software-templates/
│   ├── shared/                     # Shared parameters & steps
│   └── tenant/                     # Tenant template
└── scripts/
    ├── generate.py                 # Scaffolding script
    └── templates/                  # Scaffold templates
```

### Make Targets

```bash
make help                # Show available targets
make new SERVICE=redis   # Scaffold a new service
make lint                # Lint all Helm charts
make template            # Render charts (dry-run)
make validate            # Validate values against JSON schemas
make clean               # Remove build artifacts
make all                 # Run all checks
```

### Adding a New Service

```bash
make new SERVICE=postgres
```

Generates:
- `definitions/postgres.yaml` — KRO ResourceGraphDefinition
- `charts/postgres/` — Helm chart scaffold
- `software-templates/postgres/` — Backstage template + skeleton
- Auto-registers in `software-templates/all.yaml`

The name derives the kind: `postgres` → `Postgres`, `full-stack` → `FullStack`.

Then customize:
- `charts/postgres/values.schema.json` — add properties
- `charts/postgres/templates/` — add K8s resource templates
- `software-templates/postgres/template.yaml` — add parameters
- `software-templates/postgres/skeleton/manifest.yaml` — map values

## Setup

When forking, update these values to match your environment:

| What | Where | Default |
|------|-------|---------|
| API group | `scripts/generate.py`, tenant software template `template.yaml`, tenant definition `tenant.yaml` | `managedservices.thecodingsheikh.io` |
| GitHub org/repo | `scripts/generate.py`, tenant `template.yaml` | `thecodingsheikh/managed-services` |
| Releases Repo | tenant software template `template.yaml`, `push-manifest.yaml` | `thecodingsheikh/managed-services-releases` |