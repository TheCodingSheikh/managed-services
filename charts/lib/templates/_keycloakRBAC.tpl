{{/*
lib.keycloakRBAC — Keycloak client roles + owner mappings.

Creates 3 client roles (admin/edit/view) in each of the ArgoCD and Vault
clients (6 total), all named "<release>-<level>" so ArgoCD's SSO bindings
and Vault's OIDC can match them 1:1. Then, per owner, emits one mapping per
client that links their user or group to the role matching owner.role.

Subject may be "user:<n>", "group:<n>", "group:<path>/<n>", or a bare name
(treated as user).
*/}}

{{- define "lib.keycloakRBAC" -}}
{{- $clients := dict
    "argocd" "lab-argo-cd-client"
    "vault"  "lab-vault-client"
}}
{{- range $system, $clientRef := $clients }}
{{- range $role := list "admin" "edit" "view" }}
{{- $roleName := printf "%s-%s" $.Release.Name $role }}
---
apiVersion: role.keycloak.crossplane.io/v1alpha1
kind: Role
metadata:
  name: {{ $.Release.Name }}-{{ $system }}-{{ $role }}
  annotations:
    {{- include "lib.argocdAnnotations" $ | nindent 4 }}
spec:
  forProvider:
    name: {{ $roleName }}
    clientIdRef: {name: {{ $clientRef }}}
    realmIdRef: {name: lab-realm}
  providerConfigRef: {name: keycloak-provider-config}
{{- end }}
{{- end }}
{{- range $owner := .Values.owners }}
{{- $kind := ternary "group" "user" (hasPrefix "group:" $owner.subject) }}
{{- $name := regexReplaceAll "^[^:]+:" $owner.subject "" | splitList "/" | last }}
{{- range $system := list "argocd" "vault" }}
---
apiVersion: {{ $kind }}.keycloak.crossplane.io/v1alpha1
kind: Roles
metadata:
  name: {{ $.Release.Name }}-{{ $name }}-{{ $system }}
  annotations:
    {{- include "lib.argocdAnnotations" $ | nindent 4 }}
spec:
  forProvider:
    realmIdRef: {name: lab-realm}
    roleIdsRefs:
      - name: {{ $.Release.Name }}-{{ $system }}-{{ $owner.role }}
    {{ $kind }}IdRef:
      name: lab-{{ $name }}-{{ $kind }}
  providerConfigRef: {name: keycloak-provider-config}
{{- end }}
{{- end }}
{{- end }}
