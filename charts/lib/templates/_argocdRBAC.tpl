{{/*
lib.argocdRBAC — 3 ArgoCD roles (admin/edit/view) per tenant.

Each role's objects match every Application whose name starts with the tenant
release name, so one role covers the tenant app and every service under it.
Bindings' sso subjects are the Keycloak client roles of the same name.
*/}}

{{- define "lib.argocdRBAC" -}}
{{- $perms := dict
    "admin" (list "get" "create" "update" "delete" "sync" "override" "action")
    "edit"  (list "get" "update" "sync" "action")
    "view"  (list "get")
}}
{{- range $role, $verbs := $perms }}
{{- $name := printf "%s-%s" $.Release.Name $role }}
---
apiVersion: rbac-operator.argoproj-labs.io/v1alpha1
kind: ArgoCDRole
metadata:
  name: {{ $name }}
  annotations:
    {{- include "lib.argocdAnnotations" $ | nindent 4 }}
spec:
  rules:
    - resource: applications
      verbs: {{ $verbs | toJson }}
      objects: ["managed-services/{{ $.Release.Name }}*"]
    - resource: logs
      verbs: ["get"]
      objects: ["managed-services/{{ $.Release.Name }}*"]
---
apiVersion: rbac-operator.argoproj-labs.io/v1alpha1
kind: ArgoCDRoleBinding
metadata:
  name: {{ $name }}
  annotations:
    {{- include "lib.argocdAnnotations" $ | nindent 4 }}
spec:
  subjects:
    - kind: sso
      name: {{ $name }}
  argocdRoleRef:
    name: {{ $name }}
{{- end }}
{{- end }}
