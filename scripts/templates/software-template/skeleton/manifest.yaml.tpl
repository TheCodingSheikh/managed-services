apiVersion: __API_GROUP__/v1alpha1
kind: __SERVICE_KIND__
metadata:
  name: "${{ values.params.tenant }}-tenant-${{ values.params.name }}-__SERVICE_NAME__"
  annotations:
    # Backstage catalog discovery through Terasky kubernetes ingestor plugin
    lab.backstage.io/add-to-catalog: "true"
    lab.backstage.io/system-type: app
    lab.backstage.io/component-type: service
    lab.backstage.io/lifecycle: managed
    lab.backstage.io/dependsOn: component:default/${{ values.params.tenant }}-tenant
    lab.backstage.io/title: ${{ values.params.tenant | replace("-", " ") | title }} Tenant ${{ values.params.name | replace("-", " ") | title }} __SERVICE_TITLE__
    lab.backstage.io/name: ${{ values.params.tenant }}-tenant-${{ values.params.name }}-__SERVICE_NAME__
    lab.backstage.io/system: __SERVICE_NAME__
    # Backstage entity scaffolder plugin
    backstage.io/last-applied-configuration: '${{ values.params | dump }}'
    backstage.io/scaffolder-template: template:default/__SERVICE_NAME__
    backstage.io/immutable-fields: 'tenant,name'
spec:
  values:
    tenant: ${{ values.params.tenant }}
    name: ${{ values.params.name }}
    # TODO: add values matching charts/__SERVICE_NAME__/values.schema.json
