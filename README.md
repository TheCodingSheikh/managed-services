# Managed Services Framework

A Kubernetes-native framework for building managed services using **Helm Charts**, **KRO ResourceGraphDefinitions**, and **Backstage Software Templates**.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           Backstage Portal                              │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  Software Template (parameters from values.schema.json)          │   │
│  └──────────────────────────────┬──────────────────────────────────┘   │
└─────────────────────────────────┼───────────────────────────────────────┘
                                  │ Creates
                                  ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        Kubernetes Cluster                               │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  KRO ResourceGraphDefinition                                      │  │
│  │  ┌────────────────────┐     ┌─────────────────────────────────┐  │  │
│  │  │ Custom Resource    │────▶│ HelmRelease (Flux CD)           │  │  │
│  │  │ (ManagedPostgres)  │     │ ┌─────────────────────────────┐ │  │  │
│  │  └────────────────────┘     │ │ Helm Chart (postgres)       │ │  │  │
│  │                             │ │ + Umbrella Chart (common)   │ │  │  │
│  │                             │ └─────────────────────────────┘ │  │  │
│  │                             └─────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

## Project Structure

```
managed-services/
├── charts/                      # Helm charts
│   ├── umbrella/                # Common resources (ServiceAccount, ConfigMap, etc.)
│   └── postgres/                # Example managed service
├── definitions/                 # KRO ResourceGraphDefinitions
│   └── postgres.yaml
└── software-templates/          # Backstage software templates
    └── postgres/
        └── template.yaml
```

## Key Concepts

### values.schema.json as Single Source of Truth

Each Helm chart includes a `values.schema.json` that defines the valid configuration. This schema is used by:
1. **Helm** - Validates `values.yaml` during install/upgrade
2. **KRO** - Derives the custom resource spec schema
3. **Backstage** - Generates form fields for the software template

### Umbrella Chart

The `umbrella` chart provides common Kubernetes resources shared by all managed services:
- ServiceAccount
- ConfigMap (common configuration)
- NetworkPolicy
- ResourceQuota

### KRO ResourceGraphDefinition

Each managed service has a KRO definition that:
1. Creates a custom API (e.g., `ManagedPostgres`)
2. Deploys a Flux CD `HelmRelease` when instantiated
3. Aggregates status from underlying resources

## Prerequisites

- Kubernetes cluster (1.25+)
- [KRO](https://kro.run) installed
- [Flux CD](https://fluxcd.io) Helm controller installed
- [Backstage](https://backstage.io) instance (for templates)

## Usage

### Deploy a Managed Service

```yaml
apiVersion: managedservices.example.com/v1alpha1
kind: ManagedPostgres
metadata:
  name: my-postgres
  namespace: default
spec:
  replicas: 3
  storage:
    size: 10Gi
    storageClass: standard
  resources:
    requests:
      memory: 256Mi
      cpu: 100m
```

## Development

### Validate Helm Charts

```bash
helm lint charts/umbrella
helm lint charts/postgres
helm template my-release charts/postgres
```

### Validate JSON Schemas

```bash
npx ajv validate -s charts/postgres/values.schema.json -d charts/postgres/values.yaml
```
