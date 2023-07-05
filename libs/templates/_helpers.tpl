{{/*
It does not include libs.rbac, because it will not be used in subchrats.
libs.rbac will be called from global chart directly and referenced in rbac object in values file.
*/}}
{{- define "libs.all" -}}
{{ include "libs.configmap" . }}
{{ include "libs.cronjob" . }}
{{ include "libs.daemonset" . }}
{{ include "libs.deployment" . }}
{{ include "libs.hpa" . }}
{{ include "libs.service" . }}
{{ include "libs.pvc" . }}
{{- end -}}


{{/*
Expand the name of the chart.
*/}}
{{- define "libs.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "libs.fullname" -}}
    {{- $name := default .Chart.Name .Values.nameOverride }}
    {{- if contains $name .Release.Name }}
        {{- .Release.Name | trunc 63 | trimSuffix "-" }}
    {{- else }}
        {{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
    {{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "libs.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "libs.labels" -}}
helm.sh/chart: {{ include "libs.chart" . }}
{{ include "libs.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "libs.selectorLabels" -}}
app.kubernetes.io/name: {{ include "libs.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}


{{/*
Expand the name of the chart.
*/}}
{{- define "lineblocs.name" -}}
    {{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "lineblocs.fullname" -}}
    {{- $name := default .Chart.Name .Values.nameOverride }}
    {{- if contains $name .Release.Name }}
        {{- .Release.Name | trunc 63 | trimSuffix "-" }}
    {{- else }}
        {{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
    {{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "lineblocs.chart" -}}
    {{- printf "%s-%s" (include "lineblocs.name" .) .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*Get the resource name appended with the resource name
Usage:
include "resource.name" (dict "name" "$name" "context" .)*/}}
{{- define "resource.name" }}
    {{- if .nameSuffix }}
    {{- include "lineblocs.fullname" .context }}-{{ .nameSuffix }}
    {{- else }}
    {{- include "lineblocs.fullname" .context }}
    {{- end }}
{{- end }}

{{/*Generate metadata depending on resource name*/}}
{{/*Usage:*/}}
{{/*include "resource.metadata" (dict "nameSuffix" "$nameSuffix" "context" .)*/}}
{{- define "resource.metadata" }}
  {{- if .trunc }}
  name: {{ include "resource.name" (dict "nameSuffix" .nameSuffix "context" .context) | trunc .trunc | quote }}
  {{- else }}
  name: {{ include "resource.name" (dict "nameSuffix" .nameSuffix "context" .context) | quote }}
  {{- end }}
  labels:
  {{- with .context }}
    app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
    app.kubernetes.io/instance: {{ .Release.Name | quote }}
    app.kubernetes.io/name: {{ include "lineblocs.name" . | quote }}
    helm.sh/chart: {{ include "lineblocs.chart" . | quote }}
  {{- end }}
{{- end }}

{{/*Generate match labels*/}}
{{/*Usage:*/}}
{{/*include "resource.matchLabels" (dict "name" "$name" "context" .)*/}}
{{- define "resource.matchLabels" }}
app.kubernetes.io/name: {{ include "resource.name" (dict "name" .name "context" .context) | quote }}
    {{- with .context }}
app.kubernetes.io/instance: {{ quote .Release.Name }}
    {{- end }}
{{- end }}
