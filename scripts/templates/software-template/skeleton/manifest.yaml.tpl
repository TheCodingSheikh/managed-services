apiVersion: __API_GROUP__/v1alpha1
kind: __SERVICE_KIND__
metadata:
  name: "${{ values.tenant }}-tenant-${{ values.params.name }}-__SERVICE_NAME__"
  annotations:
    # Backstage catalog discovery through Terasky kubernetes ingestor plugin
    lab.backstage.io/add-to-catalog: "true"
    lab.backstage.io/system-type: app
    lab.backstage.io/component-type: service
    lab.backstage.io/lifecycle: managed
    lab.backstage.io/dependsOn: component:default/${{ values.tenant }}-tenant
    lab.backstage.io/title: ${{ values.tenant | replace("-", " ") | title }} Tenant ${{ values.params.name | replace("-", " ") | title }} __SERVICE_TITLE__
    lab.backstage.io/name: ${{ values.tenant }}-tenant-${{ values.params.name }}-__SERVICE_NAME__
    lab.backstage.io/system: __SERVICE_NAME__
    lab.backstage.io/owners: '{% for owner in values.owners %}${{ owner.subject }}:${{ owner.role }}{% if not loop.last %},{% endif %}{%- endfor %}'
    lab.backstage.io/kubernetes-label-selector: 'app.kubernetes.io/instance=${{ values.tenant }}-tenant-${{ values.params.name }}-__SERVICE_NAME__'
    # TODO: optional — surface the running endpoint(s) in the Backstage entity.
    # YAML "|-" block style keeps the JSON readable; "{%- if ... %}" blocks add
    # links conditionally. Service hosts are <release>.<namespace>.svc.cluster.local
    # where release = <tenant>-tenant-<instance>-<service> and namespace =
    # <tenant>-tenant-<service>-<instance> (note the swapped ordering).
    # lab.backstage.io/links: |-
    #   [
    #     {
    #       "url": "http://${{ values.tenant }}-tenant-${{ values.params.name }}-__SERVICE_NAME__.${{ values.tenant }}-tenant-__SERVICE_NAME__-${{ values.params.name }}.svc.cluster.local",
    #       "title": "Internal Service",
    #       "icon": "web"
    #     }
    #   ]
    # Backstage entity scaffolder plugin
    backstage.io/last-applied-configuration: '${{ values.params | dump }}'
    backstage.io/scaffolder-template: template:default/__SERVICE_NAME__
    backstage.io/immutable-fields: 'tenant,name'
  label:
    app.kubernetes.io/instance: '${{ values.tenant }}-tenant-${{ values.params.name }}-__SERVICE_NAME__'
spec:
  values:
    # ALWAYS quote string-typed substitutions ("${{ ... }}") so values like "1"
    # don't get YAML-coerced to int and fail values.schema.json validation.
    # Leave numbers/booleans unquoted (e.g. replicas: ${{ values.params.replicas }}).
    # `values.tenant` is the resolved short tenant name (set by fetch-template.yaml);
    # `values.params.tenant` is still the raw EntityPicker ref — don't use it here.
    tenant: "${{ values.tenant }}"
    name: "${{ values.params.name }}"
    # TODO: add fields matching charts/__SERVICE_NAME__/values.schema.json
