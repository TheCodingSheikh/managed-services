{{/* Expand the name of the chart. */}}
{{- define "lib.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Fully qualified app name. */}}
{{- define "lib.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/* Chart name and version for the chart label. */}}
{{- define "lib.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Selector labels (immutable — used in matchLabels). */}}
{{- define "lib.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lib.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/* Common labels applied to all resources. */}}
{{- define "lib.labels" -}}
helm.sh/chart: {{ include "lib.chart" . }}
{{ include "lib.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: managed-services
{{- end }}

{{/* ArgoCD tracking annotation for Flux-managed resources. */}}
{{- define "lib.argocdAnnotations" -}}
argocd.argoproj.io/tracking-id: {{ .Release.Name }}:helm.toolkit.fluxcd.io/HelmRelease:{{ .Release.Name }}/{{ .Release.Namespace }}
{{- end }}
