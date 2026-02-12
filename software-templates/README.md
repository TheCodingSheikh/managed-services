# Software Templates Guide

This directory contains Backstage software templates for creating managed services.

## Directory Structure

Each managed service should have its own directory matching the service name (e.g., `postgres`, `redis`).

```
software-templates/
├── <service-name>/          # e.g., postgres
│   ├── skeleton/            # Skeleton files for the service
│   │   └── manifest.yaml    # The manifest to be created
│   └── template.yaml        # The Backstage template definition
├── shared/                  # Shared resources
│   ├── parameters/          # Shared parameter definitions
│   └── steps/               # Shared template steps
└── tenant/                  # The tenant creation template
```

## Creating a New Service Template

To create a new managed service template (e.g., for `postgres`), follow these rules:

### 1. Template Definition (`template.yaml`)

Create a `template.yaml` in your service directory.

*   **Name & Type**: The `metadata.name` must match the system-wide service name. The `spec.type` must match the service type.
*   **Parameters**:
    *   **First Section**: Must be a reference to the shared tenant configuration.
    *   **Service Configuration**: subsequent parameters must match the `values.schema.json` of the target Helm chart.
    *   **Service Name**: Must accept a `name` parameter with a `nameValidator` field (using `ScaffolderFieldValidator`) to ensure uniqueness. The `apiPath` should point to the plural form of the service resource (e.g., `postgres` -> `postgreses`).
        *   See `software-templates/tenant/template.yaml` for an implementation reference.
        * In tenant schema, the name key is `tenant` other services use `name`
*   **Steps**: It is best practice to reference shared steps (e.g., using `$yaml: ...`) to unify logic and ensure fault tolerance.

**Example `template.yaml`:**

```yaml
apiVersion: scaffolder.backstage.io/v1beta3
kind: Template
metadata:
  name: &name postgres  # Must match service name
  title: Managed Postgres
  description: Create a managed Postgres instance
  tags:
    - *name
    - kubernetes
    - managed-service
spec:
  owner: platform-team
  type: service

  parameters:
    # 1. Tenant Configuration (Shared Reference)
    - $yaml: https://github.com/thecodingsheikh/managed-services/blob/main/software-templates/shared/parameters/tenant-selector.yaml

    # 2. Service Configuration (Matches charts/postgres/values.schema.json)
    - title: Postgres Configuration
      required:
        - name
        - instanceType
        - storage
      properties:
        # Hidden Service Type
        serviceType:
          type: string
          default: *name
          ui:widget: hidden
        
        # Service Parameters
        name:
          title: Name
          type: string
          description: Postgres instance name
          pattern: "^[a-z][a-z0-9-]*$"
          ui:autofocus: true
        nameValidator:
          type: string
          ui:field: ScaffolderFieldValidator
          ui:options:
            watchField: name
            validationType: api
            # Adjust apiPath to match the plural name of your service resource
            apiPath: proxy/k8s/managedservices.thecodingsheikh.io/v1alpha1/postgreses
            jmesPath: "items[?metadata.name == '{{ value }}']"
            errorMessage: "Postgres '{{ value }}' is already in use"
        
        instanceType:
          title: Instance Type
          type: string
          enum:
            - db.t3.micro
            - db.t3.small
            - db.t3.medium
            - db.m5.large
        
        storage:
          title: Storage
          type: object
          properties:
            size:
              title: Size
              type: string
              default: 10Gi
              pattern: "^\\d+(Gi|Mi)$"

  steps:
    - $yaml: https://github.com/thecodingsheikh/managed-services/blob/main/software-templates/shared/steps/fetch-template.yaml
    - $yaml: https://github.com/thecodingsheikh/managed-services/blob/main/software-templates/shared/steps/push-manifest.yaml

  output:
    text:
      - title: Service Created
        content: |
          Your service is being created. You can view it in the catalog once it is ready.
```

### 2. Skeleton File (`skeleton/manifest.yaml`)

Create a `manifest.yaml` in the `skeleton` directory.

*   **Managed Section**: The section strictly between `####### BEGIN MANAGED #######` and `####### END MANAGED #######` must be kept exactly as is.
*   **Spec Values**: The `spec.values` section should be populated using the template parameters, matching the structure required by the Helm chart.

**Example `skeleton/manifest.yaml`:**

```yaml
apiVersion: managedservices.thecodingsheikh.io/v1alpha1
####### BEGIN MANAGED #######
kind: ${{ values.params.serviceType | replace("-", " ") | title | replace(" ", "")}}
metadata:
  name: "${{ values.params.tenant }}-tenant{% if values.params.serviceType != 'tenant' %}-${{ values.params.name }}-${{ values.params.serviceType }}{% endif %}"
  annotations:
    lab.backstage.io/add-to-catalog: "true"
    lab.backstage.io/system-type: app
    lab.backstage.io/component-type: service
    lab.backstage.io/lifecycle: managed
    lab.backstage.io/links: string
    {% if values.params.serviceType != 'tenant' -%}
    lab.backstage.io/dependsOn: component:default/${{ values.params.tenant }}-tenant
    {%- endif %}
    lab.backstage.io/title: ${{ values.params.tenant | replace("-", " ") | title }} Tenant {% if values.params.serviceType != 'tenant' %} ${{ values.params.name | replace("-", " ") | title }} ${{ values.params.serviceType | replace("-", " ") | title }}{% endif %}
    lab.backstage.io/name: ${{ values.params.tenant }}-tenant{% if values.params.serviceType != 'tenant' %}-${{ values.params.name }}-${{ values.params.serviceType }}{% endif %}
    lab.backstage.io/system: ${{ values.params.serviceType }}
    managedservices.thecodingsheikh.io/type: ${{ values.params.serviceType }}
    backstage.io/last-applied-configuration: '${{ values.params | dump }}'
    backstage.io/scaffolder-template: template:default/${{ values.params.serviceType }}
####### END MANAGED #######
    backstage.io/immutable-fields: 'tenant' # Fields that are not allowed to change after creation
spec:
  values:
    # Map template parameters to Helm values here
    name: ${{ values.params.name }}
    instanceType: ${{ values.params.instanceType }}
    storage: ${{ values.params.storage }}
    # Add other values as needed
```
