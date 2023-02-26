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

{{/*Get the resource name appended with the resource name
Usage:
include "resource.name" (dict "name" "$name" "context" .)*/}}
{{- define "resource.name" }}
    {{- if eq .name "" }}
        {{- include "lineblocs.fullname" .context }}
    {{- else }}
{{- /*    Lower required here for ingress backends later on*/}}
        {{- printf "%s-%s" (include "lineblocs.fullname" .context) (lower .name) }}
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


{{- define "lineblocs.etcd.host" }}
    {{- ne .Values.externalEtcdHost "" | ternary .Values.externalEtcdHost (printf "%s-etcd-headless.%s.cluster.local" .Release.Name .Release.Namespace) }}
{{- end }}

{{- define "lineblocs.etcd.env" }}
- name: ETCD_ENDPOINT
  value: {{ include "lineblocs.etcd.host" . | quote }}
- name: ETCD_USERNAME
  value: "root"
- name: ETCD_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Values.etcd.enabled | ternary (printf "%s-etcd" .Release.Name) (include "lineblocs.fullname" .) }}
      key: etcd-root-password
      optional: false
{{- end }}

{{- define "lineblocs.mysql.image" }}
    {{- if .Values.mysql.enabled }}
        {{ printf "%s/%s:%s" .Values.mysql.image.registry .Values.mysql.image.repository (ne .Values.mysql.image.digest "" | ternary .Values.mysql.image.digest .Values.mysql.image.tag) }}
    {{- else }}
        {{ printf "docker.io/mysql:%s" (required "external mysql database version is required" .Values.externalMysqlVersion) }}
    {{- end }}
{{- end }}

{{- define "lineblocs.mysql.host" }}
    {{- if not .Values.mysql.enabled }}
        {{- required "external mysql host name is required" .Values.externalMysqlHost }}
    {{- else }}
        {{- printf "%s-mysql-headless.%s.svc.cluster.local" .Release.Name .Release.Namespace }}
    {{- end }}
{{- end }}

{{- define "lineblocs.mysql.user" }}
    {{- if not .Values.mysql.enabled }}
        {{- required "external mysql username required" .Values.externalMysqlUser }}
    {{- else }}
        {{- .Values.mysql.auth.password }}
    {{- end }}
{{- end }}

{{- define "lineblocs.mysql.database" }}
    {{- if not .Values.mysql.enabled }}
        {{- required "external mysql database name required" .Values.externalMysqlDatabase }}
    {{- else }}
        {{- .Values.mysql.auth.database }}
    {{- end }}
{{- end }}

{{- define "lineblocs.mysql.env" }}
- name: DB_HOST
  value: {{ include "lineblocs.mysql.host" . | quote }}
- name: DB_USER
  value: {{ include "lineblocs.mysql.user" $ }}
- name: DB_PASS
  valueFrom:
    secretKeyRef:
      name: {{ ternary (printf "%s-mysql" .Release.Name) (include "lineblocs.fullname" $) .Values.mysql.enabled }}
      key: mysql-password
      optional: false
- name: DB_NAME
  value: {{ include "lineblocs.mysql.database" $ }}
{{- end }}

{{- define "lineblocs.mysql.env.withRoot" }}
    {{- include "lineblocs.mysql.env" . }}
- name: DB_ROOT_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ ternary (printf "%s-mysql" .Release.Name) (include "lineblocs.fullname" $) .Values.mysql.enabled }}
      key: mysql-root-password
      optional: false
{{- end }}

{{- define "lineblocs.mysql.env.all" }}
    {{- include "lineblocs.mysql.env.withRoot" . }}
- name: DB_OPENSIPS_DATABASE
  value: {{ required "opensipsDatabase is a required parameter" .Values.opensipsDatabase }}
{{- end }}

{{- define "lineblocs.deploymentDomain" }}
    {{- required "deploymentDomain is a required parameter" .Values.deploymentDomain | quote }}
{{- end }}

{{/*Usage:*/}}
{{/*  include "lineblocs.databaseWaitInitContainers" (dict "key" "path-to-key-in-values" "context" $)*/}}
{{- define "lineblocs.databaseWaitInitContainers" }}
    {{- $name := .key | splitList "." | last | lower }}
    {{- $key := .key }}
    {{- with .context }}
- name: {{ include "resource.name" (dict "name" $name "context" .) }}
  image: {{ include "lineblocs.mysql.image" . }}
  command:
    - bash
    - -c
    - |
      sleep 60 # waiting a little bit for initialization to complete
      while ((MAX_RETRY_COUNT > 0)); do
        mysqladmin status -h$DB_HOST -u$DB_USER -p$DB_PASS && exit 0
        MAX_RETRY_COUNT=$((MAX_RETRY_COUNT-1))
        sleep 10
      done
      exit 1
  env:
    {{- include "lineblocs.mysql.env" . | indent 4 }}
    - name: MAX_RETRY_COUNT
      value: {{ include "common.utils.getValueFromKey" (dict "key" (join "." (list $key "maxRetryCount")) "context" .) | default 10 | quote }}
    {{- end }}
{{- end }}


{{- define "lineblocs.ingress.hosts" }}
    {{- $hosts := list }}
    {{- range $key, $value := .Values }}
        {{- if and (typeIsLike "map[string]interface {}" $value) (hasKey $value "domain") }}
            {{- $hosts = append $hosts $value.domain }}
        {{- end }}
    {{- end }}
    {{- uniq $hosts | join ", " }}
{{- end }}

{{- define "lineblocs.ingress.rules" }}
    {{- range $key, $value := .Values }}
        {{- if and (typeIsLike "map[string]interface {}" $value) (hasKey $value "domain") }}
- host: {{ $value.domain | quote }}
  http:
    paths:
      - backend:
          serviceName: {{ include "resource.name" (dict "name" $key "context" $) | quote }}
          servicePort: 80
        {{- end }}
    {{- end }}
{{- end }}
