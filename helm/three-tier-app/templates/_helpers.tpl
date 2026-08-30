{{/*
Full name of the chart (truncated to 63 chars, Helm standard).
*/}}
{{- define "three-tier-app.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Labels used on all resources.
*/}}
{{- define "three-tier-app.labels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end -}}

{{/*
Compute the frontend service name that nginx should proxy /api to.
Uses the backend host override if set, otherwise the generated backend service name.
*/}}
{{- define "three-tier-app.backendHost" -}}
{{- if .Values.frontend.backendHost -}}
{{- .Values.frontend.backendHost -}}
{{- else -}}
{{- printf "%s-backend" (include "three-tier-app.fullname" .) -}}
{{- end -}}
{{- end -}}
