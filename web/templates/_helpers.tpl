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
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "lineblocs.labels" -}}
helm.sh/chart: {{ include "lineblocs.chart" . }}
{{ include "lineblocs.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "lineblocs.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lineblocs.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "lineblocs.web.serviceAccountName" -}}
{{- if .Values.common.serviceAccount.create }}
{{- default (include "lineblocs.web.fullname" .) .Values.common.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.common.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*Percona hostname*/}}
{{- define "db.hostname" -}}
    {{- $fullname := printf "%s-db" .Release.Name }}
    {{- $namespace := .Release.Namespace }}
    {{- if .Values.db.proxysql.enabled }}
        {{- printf "%s-proxysql.%s.svc.cluster.local" $fullname $namespace }}
    {{- else }}
        {{- printf "%s-haproxy.%s.svc.cluster.local" $fullname $namespace }}
    {{- end }}
{{- end }}


{{/*Get com/backend image name*/}}
{{- define "lineblocs.web.image" }}
    {{ $image := .Values.com.image.repository }}
    {{ $tag := .Values.com.image.tag }}
    {{ printf "%s:%s" $image $tag }}
{{- end }}

{{- define "lineblocs.etcd.fullname" }}
    {{- printf "%s-%s-headless" .Release.Name "etcd" | trunc 63 -}}
{{- end }}

{{- define "lineblocs.etcd.host" }}
    {{- printf "http://%s:%0.f" (include "lineblocs.etcd.fullname" .) .Values.etcd.service.ports.client }}
{{- end }}