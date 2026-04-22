{{/*
lib.argocdRBAC — always emits 3 ArgoCD roles (admin / edit / view) with a
matching binding each. The binding's subject is the Keycloak client role of
the same name, so Keycloak role membership drives ArgoCD access.
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
spec:
  rules:
    - resource: applications
      verbs: {{ $verbs | toJson }}
      objects: ["managed-services/{{ $.Release.Name }}"]
---
apiVersion: rbac-operator.argoproj-labs.io/v1alpha1
kind: ArgoCDRoleBinding
metadata:
  name: {{ $name }}
spec:
  subjects:
    - kind: sso
      name: {{ $name }}
  argocdRoleRef:
    name: {{ $name }}
{{- end }}
{{- end }}
