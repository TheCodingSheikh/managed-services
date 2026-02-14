# Charts

Helm charts for managed services. Each chart represents a deployable service.

## Structure

- `lib/` — shared Helm helpers (labels, selectors, annotations). Every chart depends on this.
- `tenant/` — multi-tenant isolation (Core Service)

## Adding a Chart

Run `make new SERVICE=<name>` to scaffold. Then:
1. Add properties to `values.schema.json`
2. Add K8s templates in `templates/`
3. Run `make lint` to validate

## Composite Services

For services combining multiple managed services:
- Don't use Helm sub-chart dependencies
- Include the Custom Resources (CRs) for constituent services in your templates
- Example: add a `kind: Postgres` resource in your templates instead of depending on the postgres chart
