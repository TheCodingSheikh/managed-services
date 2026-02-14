# Placeholders: __SERVICE_NAME__, __SERVICE_KIND__, __TIMEOUT__, __API_GROUP__, __REPO_NAME__
apiVersion: kro.run/v1alpha1
kind: ResourceGraphDefinition
metadata:
  name: __SERVICE_NAME__
spec:
  schema:
    apiVersion: v1alpha1
    group: __API_GROUP__
    kind: __SERVICE_KIND__
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
              chart: charts/__SERVICE_NAME__
              sourceRef:
                kind: GitRepository
                name: __REPO_NAME__
                namespace: __REPO_NAME__
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
          timeout: __TIMEOUT__
