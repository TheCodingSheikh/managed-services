apiVersion: v2
name: __SERVICE_NAME__
description: Managed __SERVICE_TITLE__ service
type: application
version: 0.1.0
appVersion: "0.1.0"
keywords:
  - __SERVICE_NAME__
  - managed-service
home: __REPO_URL__
sources:
  - __REPO_URL__
maintainers:
  - name: Platform Team
dependencies:
  - name: lib
    version: "0.0.0"
    repository: "file://../lib"
