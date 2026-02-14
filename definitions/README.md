# Definitions

KRO ResourceGraphDefinitions that create custom Kubernetes APIs for each managed service.

## How It Works

When a custom resource (e.g., `kind: Postgres`) is created:

1. KRO detects it via the ResourceGraphDefinition
2. KRO creates a Flux HelmRelease with values from `spec.values`
3. Flux pulls the Helm chart from the GitRepository and deploys it
4. KRO reports readiness once the HelmRelease reaches `Ready: True`

## Files

- `gitrepository.yaml` — Flux GitRepository pointing to this repo
- `tenant.yaml` — Tenant RGD (Core)

## Generation

Definitions are generated from `scripts/templates/rgd.yaml.tpl`:

```bash
make new SERVICE=postgres   # generates definitions/postgres.yaml
```

Every RGD is structurally identical — only the name, kind and chart location differ.

