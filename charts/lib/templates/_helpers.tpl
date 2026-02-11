{{/*
Expand the name of the chart.
*/}}
{{- define "lib.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
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

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "lib.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "lib.labels" -}}
helm.sh/chart: {{ include "lib.chart" . }}
{{ include "lib.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "lib.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lib.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
ArgoCD tracking annotation
*/}}
{{- define "lib.argocdAnnotations" -}}
{{- $existingService := (lookup "helm.toolkit.fluxcd.io/v2beta2" "HelmRelease" .Release.Namespace .Release.Name) -}}
{{- if $existingService -}}
  argocd.argoproj.io/tracking-id: {{ index $existingService.metadata.annotations "argocd.argoproj.io/tracking-id" }}
{{- else -}}
  argocd.argoproj.io/tracking-id: none
{{- end -}}
{{- end }}

