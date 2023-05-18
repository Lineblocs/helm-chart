{{- define "lineblocs.mysql.image" }}
    {{- if and (.Values.global.mysql) (.Values.global.mysql.enabled) }}
        {{ printf "%s/%s:%s" .Values.global.mysql.image.registry .Values.global.mysql.image.repository (ne .Values.global.mysql.image.digest "" | ternary .Values.global.mysql.image.digest .Values.global.mysql.image.tag) }}
    {{- else }}
        {{ printf "docker.io/mysql:%s" (required "external mysql database version is required" $.Values.global.externalMysqlVersion) }}
    {{- end }}
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
    - secretRef:
        name: db-secret
  env:
    - name: MAX_RETRY_COUNT
      value: {{ default "10" .Values.global.mysqlInitMaxRetry | quote }}
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
