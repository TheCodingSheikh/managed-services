# Software Templates

Backstage software templates for creating managed services via self-service.

## Structure

```
software-templates/
├── shared/
│   ├── parameters/
│   │   └── tenant-selector.yaml   # Tenant picker (used by all services)
│   └── steps/
│       └── ...                    # Shared steps
├── tenant/
│   ├── template.yaml              # Tenant template
│   └── skeleton/manifest.yaml
└── all.yaml                       # Backstage location file
```

## Best Practices

- **services** - other than tenant - use shared steps from `shared/steps/` 

## Adding a Template

Run `make new SERVICE=<name>` to scaffold. Then:
1. Add parameters to `template.yaml` matching `charts/<service>/values.schema.json`
2. Map values in `skeleton/manifest.yaml`

## Template Structure

Each template - other than tenant - has:

1. **Tenant selector** — shared parameter picking the owning tenant
2. **Service configuration** — name + service-specific params from `values.schema.json`
3. **Hidden `serviceType`** — used by the shared steps
4. **Shared steps** — fetch skeleton + push PR or others based on your setup
