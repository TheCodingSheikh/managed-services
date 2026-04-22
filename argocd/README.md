# ArgoCD Bootstrap

`ApplicationSet` that generates:
  - `<tenant>-tenant` Applications from `<tenant>/manifest.yaml`
  - `<tenant>-tenant-<service>-<instance>` Applications from `<tenant>/<service>/<instance>/manifest.yaml`

  Each Application targets its own namespace and is labeled so Capsule enforces tenant isolation.
