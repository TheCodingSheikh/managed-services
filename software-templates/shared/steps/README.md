# Shared Steps

Reusable step definitions for non-tenant software templates, referenced via `$yaml:`.

## Usage

```yaml
steps:
  - $yaml: https://github.com/<org>/managed-services/blob/main/software-templates/shared/steps/fetch-template.yaml
  - $yaml: https://github.com/<org>/managed-services/blob/main/software-templates/shared/steps/push-manifest.yaml
```

## Push Flow

The push step places the manifest at releases repo, targeted by ArgoCD ApplicationSet:
```
<tenant>/<service>/<name>/manifest.yaml
```
for tenants:
```
<tenant>/manifest.yaml
```

This is my preffered way to manage my services.