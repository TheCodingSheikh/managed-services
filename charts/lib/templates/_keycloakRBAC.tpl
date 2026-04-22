{{/*
lib.keycloakRBAC — always emits 3 Keycloak client roles (admin / edit / view)
matching the ArgoCD roles from lib.argocdRBAC, then one mapping per owner
that assigns their user or group to their role's client role.

Subject may be "user:<n>", "group:<n>", "group:<path>/<n>", or a bare name
(treated as user).
*/}}

{{- define "lib.keycloakRBAC" -}}
{{- range $role := list "admin" "edit" "view" }}
{{- $name := printf "%s-%s" $.Release.Name $role }}
---
apiVersion: role.keycloak.crossplane.io/v1alpha1
kind: Role
metadata:
  name: {{ $name }}
spec:
  forProvider:
    name: {{ $name }}
    clientIdRef: {name: lab-argo-cd-client}
    realmIdRef: {name: lab-realm}
  providerConfigRef: {name: keycloak-provider-config}
{{- end }}
{{- range .Values.owners }}
{{- $kind := ternary "group" "user" (hasPrefix "group:" .subject) }}
{{- $name := regexReplaceAll "^[^:]+:" .subject "" | splitList "/" | last }}
---
apiVersion: {{ $kind }}.keycloak.crossplane.io/v1alpha1
kind: Roles
metadata:
  name: {{ $.Release.Name }}-{{ $name }}
spec:
  forProvider:
    realmIdRef: {name: lab-realm}
    roleIdsRefs:
      - name: {{ $.Release.Name }}-{{ .role }}
    {{ $kind }}IdRef:
      name: lab-{{ $name }}-{{ $kind }}
  providerConfigRef: {name: keycloak-provider-config}
{{- end }}
{{- end }}
