{{/*
Expand the name of the chart.
*/}}
{{- define "evolution-api.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "evolution-api.fullname" -}}
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
{{- define "evolution-api.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "evolution-api.labels" -}}
helm.sh/chart: {{ include "evolution-api.chart" . }}
{{ include "evolution-api.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "evolution-api.selectorLabels" -}}
app.kubernetes.io/name: {{ include "evolution-api.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "evolution-api.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "evolution-api.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
PostgreSQL labels
*/}}
{{- define "evolution-api.postgresql.labels" -}}
helm.sh/chart: {{ include "evolution-api.chart" . }}
app.kubernetes.io/name: {{ include "evolution-api.name" . }}-postgresql
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: database
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
PostgreSQL selector labels
*/}}
{{- define "evolution-api.postgresql.selectorLabels" -}}
app.kubernetes.io/name: {{ include "evolution-api.name" . }}-postgresql
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: database
{{- end }}

{{/*
Redis labels
*/}}
{{- define "evolution-api.redis.labels" -}}
helm.sh/chart: {{ include "evolution-api.chart" . }}
app.kubernetes.io/name: {{ include "evolution-api.name" . }}-redis
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: cache
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Redis selector labels
*/}}
{{- define "evolution-api.redis.selectorLabels" -}}
app.kubernetes.io/name: {{ include "evolution-api.name" . }}-redis
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: cache
{{- end }}

{{/*
Database connection string
*/}}
{{- define "evolution-api.databaseUri" -}}
{{- if .Values.postgresql.enabled }}
{{- printf "postgresql://%s:%s@%s-postgresql:%d/%s?schema=%s" .Values.postgresql.auth.username .Values.postgresql.auth.password (include "evolution-api.fullname" .) (int .Values.postgresql.service.port) .Values.postgresql.auth.database "evolution_api" }}
{{- else if .Values.externalDatabase.enabled }}
{{- printf "postgresql://%s:%s@%s:%d/%s?schema=%s" .Values.externalDatabase.username .Values.externalDatabase.password .Values.externalDatabase.host (int .Values.externalDatabase.port) .Values.externalDatabase.database .Values.externalDatabase.schema }}
{{- else }}
{{- printf "" }}
{{- end }}
{{- end }}

{{/*
Redis URI
*/}}
{{- define "evolution-api.redisUri" -}}
{{- if .Values.redis.enabled }}
{{- printf "redis://%s-redis:%d/%d" (include "evolution-api.fullname" .) (int .Values.redis.service.port) 6 }}
{{- else if .Values.externalRedis.enabled }}
{{- printf "redis://%s:%d/%d" .Values.externalRedis.host (int .Values.externalRedis.port) (int .Values.externalRedis.database) }}
{{- else }}
{{- printf "" }}
{{- end }}
{{- end }}
