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
{{- $name := include "lineblocs.name" . }}
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

{{- define "toBool" -}}
    {{- not (eq . "") -}}
{{- end -}}

{{/*Get the resource name appended with the resource name
Usage:
include "resource.name" (dict "name" "$name" "context" .)*/}}
{{- define "resource.name" }}
    {{- if eq .name "" }}
        {{- include "lineblocs.fullname" .context }}
    {{- else }}
        {{- printf "%s-%s" (include "lineblocs.fullname" .context) .name }}
    {{- end }}
{{- end }}

{{/*Generate metadata depending on resource name*/}}
{{/*Usage:*/}}
{{/*include "resource.metadata" (dict "name" "$name" "context" .)*/}}
{{- define "resource.metadata" }}
  name: {{ include "resource.name" (dict "name" .name "context" .context) | quote }}
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


{{- define "etcd.host" }}
    {{- ne .Values.externalEtcdHost "" | ternary .Values.externalEtcdHost (printf "%s-etcd-headless.%s.cluster.local" .Release.Name .Release.Namespace) }}
{{- end }}

{{- define "etcd.env" }}
- name: ETCD_ENDPOINT
  value: {{ include "etcd.host" . | quote }}
- name: ETCD_USERNAME
  value: "root"
- name: ETCD_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Values.etcd.enabled | ternary (printf "%s-etcd" .Release.Name) (include "lineblocs.fullname" .) }}
      key: etcd-root-password
      optional: false
{{- end }}

{{- define "mysql.host" }}
    {{- if .Values.externalMysqlHost }}
        {{- .Values.externalMysqlHost }}
    {{- else }}
        {{- printf "%s-mysql-headless.%s.cluster.local" .Release.Name .Release.Namespace }}
    {{- end }}
{{- end }}

{{- define "mysql.user" }}
    {{- if .Values.externalMysqlUser }}
        {{- .Values.externalMysqlUser }}
    {{- else }}
        {{- .Values.mysql.auth.password }}
    {{- end }}
{{- end }}

{{- define "mysql.database" }}
    {{- if .Values.externalMysqlPassword }}
        {{- .Values.externalMysqlDatabase }}
    {{- else }}
        {{- .Values.mysql.auth.database }}
    {{- end }}
{{- end }}

{{- define "mysql.env" }}
- name: DB_HOST
  value: {{ include "mysql.host" . | quote }}
- name: DB_USER
{{- /*    {{- $username := ne .Values.externalMysqlUser "" | ternary .Values.externalMysqlUser (include "common.utils.getValueFromKey" (dict "key" ".Values.mysql.auth.username" "context" .)) }}*/}}
  value: {{ include "mysql.user" $ }}
- name: DB_PASS
  valueFrom:
    secretKeyRef:
{{- /*    Uses own secret if external mysql is being used*/}}
      name: {{ ternary (printf "%s-mysql" .Release.Name) (include "lineblocs.fullname" .) .Values.mysql.enabled }}
      key: mysql-password
      optional: false
- name: DB_NAME
  value: {{ include "mysql.database" $ }}
{{- end }}