{{/*
lib.vaultRBAC — 3 Vault policies (admin/edit/view) per tenant.

Each policy grants its capabilities on every secret path under
"<release>/*", so one policy covers the tenant and every service under it.
Uses upbound's Vault provider (vault.vault.upbound.io). If you use a
different provider, adjust the apiVersion and spec shape — the naming
convention is the same as lib.argocdRBAC and lib.keycloakRBAC so everything
lines up.
*/}}

{{- define "lib.vaultRBAC" -}}
{{- $caps := dict
    "admin" (list "create" "read" "update" "delete" "list" "sudo")
    "edit"  (list "create" "read" "update" "list")
    "view"  (list "read" "list")
}}
{{- range $role, $capList := $caps }}
{{- $name := printf "%s-%s" $.Release.Name $role }}
---
apiVersion: vault.vault.upbound.io/v1alpha1
kind: Policy
metadata:
  name: {{ $name }}
  annotations:
    {{- include "lib.argocdAnnotations" $ | nindent 4 }}
spec:
  forProvider:
    name: {{ $name }}
    policy: |
      path "{{ $.Release.Name }}/*" {
        capabilities = [{{ range $i, $c := $capList }}{{ if $i }}, {{ end }}"{{ $c }}"{{ end }}]
      }
  providerConfigRef: {name: vault-provider-config}
{{- end }}
{{- end }}
