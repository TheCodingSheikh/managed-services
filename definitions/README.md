# Definitions

KRO `ResourceGraphDefinition`s that turn each domain CR into a Flux `HelmRelease`.

## What they do

When a user creates a `Tenant` (or `Postgres`, etc.) in the cluster:

1. KRO sees the CR (because the RGD registered its kind).
2. KRO renders a `HelmRelease` pointing at the matching chart in this repo, passing `spec.values` through.
3. Flux pulls the chart and deploys it.
4. KRO reports the CR as Ready once the `HelmRelease` is Ready.

## Files

- `gitrepository.yaml` — Flux `GitRepository` source pointing at this repo.
- `<service>.yaml` — one RGD per chart under `charts/`.

## They are auto-generated

Every RGD is pure boilerplate derived from the chart name. Don't hand-edit them — regenerate:

```bash
make regen-defs
```

This rebuilds `definitions/<svc>.yaml` for every chart under `charts/` (except `lib`). It's idempotent and safe to run at any time.

`make new SERVICE=<name>` calls the same code path, so a scaffolded service's definition is always in sync with its chart.
