# Definitions

All definitions in this directory must follow the exact same structure. Do not change anything in the YAML definition except for the names, which must match across the system.

## Naming Convention

The **RGD Name** (ResourceGraphDefinition Name), **Helm Chart Name**, and **Software Template Name** must all match exactly.

For example, if the service is `postgres` or `full-stack`:
- **RGD Name**: `postgres` (in `metadata.name`) or `full-stack` (in `metadata.name`)
- **Kind**: `Postgres` (in `spec.schema.kind`, matching the RGD name but capitalized) or `FullStack` (in `spec.schema.kind`, matching the RGD name but capitalized)
- **Helm Chart Name**: `postgres` (located in `charts/postgres`) or `full-stack` (located in `charts/full-stack`)
- **Software Template Name**: `postgres` (in `software-templates/postgres.yaml` and `metadata.name`) or `full-stack` (in `software-templates/full-stack.yaml` and `metadata.name`)

**Do not change anything else.**

```yaml
apiVersion: kro.run/v1alpha1
kind: ResourceGraphDefinition
metadata:
  name: <service> # <--- REPLACE with Service Name (e.g. redis)
spec:
  schema:
    apiVersion: v1alpha1
    group: managedservices.thecodingsheikh.io
    kind: <Service> # <--- REPLACE with Service Kind (e.g. Redis)
    spec:
      values: object
  resources:
    - id: release
      readyWhen:
        - ${release.status.conditions.exists(c, c.type == 'Ready' && c.status == 'True')}
      template:
        apiVersion: helm.toolkit.fluxcd.io/v2beta2
        kind: HelmRelease
        metadata:
          name: ${schema.metadata.name}
          namespace: ${schema.metadata.namespace}
          ownerReferences:
            - apiVersion: ${schema.apiVersion}
              kind: ${schema.kind}
              name: ${schema.metadata.name}
              uid: ${schema.metadata.uid}
              blockOwnerDeletion: true
              controller: false
          annotations:
            argocd.argoproj.io/tracking-id: ${schema.metadata.?annotations["argocd.argoproj.io/tracking-id"]}
        spec:
          releaseName: ${schema.metadata.name}
          targetNamespace: ${schema.metadata.namespace}
          chart:
            spec:
              reconcileStrategy: Revision
              chart: charts/${schema.metadata.?annotations["managedservices.thecodingsheikh.io/type"]}
              sourceRef:
                kind: GitRepository
                name: managed-services
                namespace: managed-services
              interval: 5m
          interval: 15m
          values: ${schema.spec.values}
          install:
            remediation:
              retries: 3
          upgrade:
            remediation:
              retries: 3
              remediateLastFailure: true
          timeout: 10m
```
