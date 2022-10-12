{{/*
Expand the name of the chart.
*/}}
{{- define "dataplane.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Release name
*/}}
{{- define "dataplane.release" -}}
{{- default .Release.Name .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "dataplane.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 30 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 30 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "dataplane.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "dataplane.labels" -}}
helm.sh/chart: {{ include "dataplane.chart" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Common selector labels
*/}}
{{- define "dataplane.selectorLabels" -}}
app.kubernetes.io/name: {{ include "dataplane.name" . }}
app.kubernetes.io/instance: {{ include "dataplane.release" . }}
{{- end }}

{{/*
Metabase labels
*/}}
{{- define "dataplane.metabase.labels" -}}
{{ include "dataplane.labels" . }}
{{ include "dataplane.metabase.selectorLabels" . }}
{{- end }}

{{/*
Metabase selector labels
*/}}
{{- define "dataplane.metabase.selectorLabels" -}}
{{ include "dataplane.selectorLabels" . }}
app.kubernetes.io/component: {{ include "dataplane.name" . }}-metabase
{{- end }}

{{/*
Strimzi labels
*/}}
{{- define "dataplane.strimzi.labels" -}}
{{ include "dataplane.labels" . }}
{{ include "dataplane.strimzi.selectorLabels" . }}
{{- end }}

{{/*
Srimzi selector labels
*/}}
{{- define "dataplane.strimzi.selectorLabels" -}}
{{ include "dataplane.selectorLabels" . }}
app.kubernetes.io/component: {{ include "dataplane.name" . }}-strimzi
{{- end }}

{{/*
Registry labels
*/}}
{{- define "dataplane.registry.labels" -}}
{{ include "dataplane.labels" . }}
{{ include "dataplane.registry.selectorLabels" . }}
{{- end }}

{{/*
Registry selector labels
*/}}
{{- define "dataplane.registry.selectorLabels" -}}
{{ include "dataplane.selectorLabels" . }}
app.kubernetes.io/component: {{ include "dataplane.name" . }}-registry
{{- end }}

{{/*
Create metabase fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "dataplane.metabase.fullname" -}}
{{- printf "%s-%s-%s" (include "dataplane.fullname" .) "metabase" "app"  | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create registry fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "dataplane.registry.fullname" -}}
{{- printf "%s-%s" (include "dataplane.fullname" .) "registry" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create strimzi fully qualified broker name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "dataplane.strimzi.kafka.fullname" -}}
{{- printf "%s-%s" (include "dataplane.fullname" .) "strimzi" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create strimzi fully qualified bootstrap name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "dataplane.strimzi.kafka.bootstrap" -}}
{{- printf "%s-kafka-bootstrap.%s.svc" (include "dataplane.strimzi.kafka.fullname" .) .Release.Namespace }}
{{- end }}

{{/*
Create strimzi fully qualified connect cluster name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "dataplane.strimzi.connect.fullname" -}}
{{- include "dataplane.fullname" . }}
{{- end }}

{{/*
Create strimzi fully qualified connector name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "dataplane.cdc.connector" -}}
{{- printf "%s-%s" (include "dataplane.fullname" .) "connect " | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
DB team name
*/}}
{{- define "dataplane.zalando.team" -}}
{{- include "dataplane.release" . -}}
{{- end }}

{{/*
Metabase cluster name
*/}}
{{- define "dataplane.metabase.cluster" -}}
{{- (printf "%s-%s-%s" (include "dataplane.zalando.team" .) (include "dataplane.zalando.metabase.db" .) "db") -}}
{{- end }}

{{/*
Metabase DB name
*/}}
{{- define "dataplane.zalando.metabase.db" -}}
{{ .Values.zalando.metabase.name }}
{{- end }}

{{/*
Metabase DB user secret
 */}}
{{- define "dataplane.metabase.secret" -}}
{{ .Values.zalando.metabase.user }}-{{- include "dataplane.metabase.cluster" . -}}
{{- end }}

{{/*
Warehouse cluster name
*/}}
{{- define "dataplane.warehouse.cluster" -}}
{{- (printf "%s-%s-%s" (include "dataplane.zalando.team" .) (include "dataplane.zalando.warehouse.db" .) "db") -}}
{{- end }}

{{/*
Warehouse DB name
*/}}
{{- define "dataplane.zalando.warehouse.db" -}}
{{ .Values.zalando.warehouse.name }}
{{- end }}

{{/*
Warehouse DB user secret
 */}}
{{- define "dataplane.warehouse.secret" -}}
{{ .Values.zalando.warehouse.user }}-{{- include "dataplane.warehouse.cluster" . -}}
{{- end }}

{{/*
TLS secret name
*/}}
{{- define "dataplane.metabase.ingress.secretName" -}}
{{- if .Values.metabase.ingress.secretName }}
{{- .Values.metabase.ingress.secretName }}
{{- else }}
{{- (printf "%s-%s" (include "dataplane.fullname" .) "tls") -}}
{{- end }}
{{- end }}

{{/*
API secret name
*/}}
{{- define "dataplane.metabase.api.secret.name" -}}
{{- (printf "%s-%s" (include "dataplane.release" .) "metabase-api-token") -}}
{{- end }}

{{/*
Stable API secret data
*/}}
{{- define "dataplane.metabase.api.secret" -}}
{{- $secret := lookup "v1" "Secret" .Release.Namespace (include "dataplane.metabase.api.secret.name" .) -}}
{{- if $secret -}}
{{/*
   Reusing existing secret data
*/}}
apiKey: {{ $secret.data.apiKey }}
{{- else -}}
{{/*
    Generate new secret
*/}}
apiKey: {{ randAlphaNum 16 | b64enc }}
{{- end -}}
{{- end -}}
