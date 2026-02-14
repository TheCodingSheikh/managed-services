# Generated — customize the "Service Configuration" parameters section.
apiVersion: scaffolder.backstage.io/v1beta3
kind: Template
metadata:
  name: __SERVICE_NAME__
  title: Managed __SERVICE_TITLE__
  description: Create a managed __SERVICE_TITLE__ instance
  tags:
    - __SERVICE_NAME__
    - kubernetes
    - managed-service
spec:
  owner: platform-team
  type: service

  parameters:
    - $yaml: __TEMPLATE_BASE_URL__/software-templates/shared/parameters/tenant-selector.yaml

    - title: __SERVICE_TITLE__ Configuration
      required:
        - name
      properties:
        serviceType:
          type: string
          default: __SERVICE_NAME__
          ui:widget: hidden
        name:
          title: Instance Name
          type: string
          description: Unique name (lowercase, alphanumeric with dashes)
          pattern: "^[a-z][a-z0-9-]*$"
          minLength: 1
          maxLength: 63
          ui:autofocus: true
        nameValidator:
          type: string
          ui:field: ScaffolderFieldValidator
          ui:options:
            watchField: name
            validationType: api
            # CHECK: Check the correct plural name from the CRD
            apiPath: proxy/k8s/__API_GROUP__/v1alpha1/__SERVICE_PLURAL__
            jmesPath: "items[?metadata.name == '{{ value }}']"
            errorMessage: "__SERVICE_TITLE__ '{{ value }}' is already in use"

    # TODO: add service-specific parameters matching charts/__SERVICE_NAME__/values.schema.json

  steps:
    - $yaml: __TEMPLATE_BASE_URL__/software-templates/shared/steps/fetch-template.yaml
    - $yaml: __TEMPLATE_BASE_URL__/software-templates/shared/steps/push-manifest.yaml

  output:
    text:
      - title: __SERVICE_TITLE__ Created
        content: |
          Your __SERVICE_TITLE__ instance is being created.
