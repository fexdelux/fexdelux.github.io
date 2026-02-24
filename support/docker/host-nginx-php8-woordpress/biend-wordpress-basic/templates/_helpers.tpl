{{/*
Expand the name of the chart.
*/}}
{{- define "biend-wordpress-basic.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "biend-wordpress-basic.fullname" -}}
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
{{- define "biend-wordpress-basic.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "biend-wordpress-basic.labels" -}}
helm.sh/chart: {{ include "biend-wordpress-basic.chart" . }}
{{ include "biend-wordpress-basic.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "biend-wordpress-basic.selectorLabels" -}}
app.kubernetes.io/name: {{ include "biend-wordpress-basic.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
WordPress labels
*/}}
{{- define "biend-wordpress-basic.wordpress.labels" -}}
{{ include "biend-wordpress-basic.labels" . }}
app.kubernetes.io/component: wordpress
{{- end }}

{{/*
MySQL labels
*/}}
{{- define "biend-wordpress-basic.mysql.labels" -}}
{{ include "biend-wordpress-basic.labels" . }}
app.kubernetes.io/component: mysql
{{- end }}

{{/*
Redis labels
*/}}
{{- define "biend-wordpress-basic.redis.labels" -}}
{{ include "biend-wordpress-basic.labels" . }}
app.kubernetes.io/component: redis
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "biend-wordpress-basic.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "biend-wordpress-basic.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
MySQL connection string
*/}}
{{- define "biend-wordpress-basic.mysql.host" -}}
{{- if .Values.mysql.enabled }}
{{- printf "%s-mysql" (include "biend-wordpress-basic.fullname" .) }}
{{- else }}
{{- .Values.mysql.externalHost | default "mysql" }}
{{- end }}
{{- end }}

{{/*
Redis connection string
*/}}
{{- define "biend-wordpress-basic.redis.host" -}}
{{- if .Values.redis.enabled }}
{{- printf "%s-redis" (include "biend-wordpress-basic.fullname" .) }}
{{- else }}
{{- .Values.redis.externalHost | default "redis" }}
{{- end }}
{{- end }}
