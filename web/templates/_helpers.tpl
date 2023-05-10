{{- define "lineblocs.mysql.image" }}
    {{- if and (.Values.global.mysql) (.Values.global.mysql.enabled) }}
        {{ printf "%s/%s:%s" .Values.global.mysql.image.registry .Values.global.mysql.image.repository (ne .Values.global.mysql.image.digest "" | ternary .Values.global.mysql.image.digest .Values.global.mysql.image.tag) }}
    {{- else }}
        {{ printf "docker.io/mysql:%s" (required "external mysql database version is required" $.Values.global.externalMysqlVersion) }}
    {{- end }}
{{- end }}

{{- define "lineblocs.mysql.host" }}
    {{- if not .Values.global.mysql.enabled }}
        {{- required "external mysql host name is required" .Values.externalMysqlHost }}
    {{- else }}
        {{- printf "%s-mysql-headless.%s.svc.cluster.local" .Release.Name .Release.Namespace }}
    {{- end }}
{{- end }}

{{- define "lineblocs.mysql.user" }}
    {{- if not .Values.global.mysql.enabled }}
        {{- required "external mysql username required" .Values.externalMysqlUser }}
    {{- else }}
        {{- .Values.global.mysql.auth.password }}
    {{- end }}
{{- end }}

{{- define "lineblocs.mysql.database" }}
    {{- if not .Values.global.mysql.enabled }}
        {{- required "external mysql database name required" .Values.externalMysqlDatabase }}
    {{- else }}
        {{- .Values.global.mysql.auth.database }}
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
      name: {{ ternary (printf "%s-mysql" .Release.Name) (include "lineblocs.fullname" $) .Values.global.mysql.enabled }}
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
      name: {{ ternary (printf "%s-mysql" .Release.Name) (include "lineblocs.fullname" $) .Values.global.mysql.enabled }}
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
{{- define "lineblocs.databaseWaitInitContainers" -}}
    {{- $name := .key | splitList "." | last | lower -}}
    {{- $key := .key -}}
    {{- with .context -}}
- name: {{ include "resource.name" (dict "name" (printf "%s-init" $name) "context" .) }}
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
  envFrom:
    - configMapRef:
        {{- /* using $ instead of a dot because we are in a range loop and . is redefined */}}
        name: {{ include "libs.fullname" . }}-config
  env:
    - name: MAX_RETRY_COUNT
      value: "10"
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
          service:
            name: {{ include "resource.name" (dict "name" $key "context" $) | quote }}
            port:
              number: 80
        pathType: ImplementationSpecific
        path: /
        {{- end }}
    {{- end }}
{{- end }}
