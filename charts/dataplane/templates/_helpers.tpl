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
{{- (printf "%s-%s" (include "dataplane.zalando.team" .) (include "dataplane.zalando.metabase.db" .)) -}}
{{- end }}

{{/*
Metabase DB name
*/}}
{{- define "dataplane.zalando.metabase.db" -}}
{{ .Values.zalando.metabase.name }}
{{- end }}

{{/*
Metabase DB user name
 */}}
{{- define "dataplane.metabase.owner.name" -}}
{{ .Values.zalando.metabase.name }}
{{- end }}

{{/*
Metabase DB owner secret
 */}}
{{- define "dataplane.metabase.owner.secret" -}}
{{ include "dataplane.metabase.owner.name" . }}-{{- include "dataplane.metabase.cluster" . -}}
{{- end }}

{{/*
Warehouse cluster name
*/}}
{{- define "dataplane.warehouse.cluster" -}}
{{- (printf "%s-%s" (include "dataplane.zalando.team" .) (include "dataplane.warehouse.db" .)) -}}
{{- end }}

{{/*
Warehouse DB name
*/}}
{{- define "dataplane.warehouse.db" -}}
{{ .Values.zalando.warehouse.name }}
{{- end }}

{{/*
Warehouse DB owner name
 */}}
{{- define "dataplane.warehouse.owner.name" -}}
{{ .Values.zalando.warehouse.name }}_owner
{{- end }}

{{/*
Warehouse DB owner secret
 */}}
{{- define "dataplane.warehouse.owner.secret" -}}
{{ .Values.zalando.warehouse.name }}-owner-user-{{- include "dataplane.warehouse.cluster" . -}}
{{- end }}

{{/*
Warehouse DB reader secret
 */}}
{{- define "dataplane.warehouse.reader.secret" -}}
{{ .Values.zalando.warehouse.name }}-reader-user-{{- include "dataplane.warehouse.cluster" . -}}
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
Metabase setup secret name
*/}}
{{- define "dataplane.metabase.admin.secret" -}}
{{- (printf "%s-%s" (include "dataplane.release" .) "metabase-admin") -}}
{{- end }}

{{/*
Metabase setup secret data
*/}}
{{- define "dataplane.metabase.admin.secretData" -}}
{{- $secret := lookup "v1" "Secret" .Release.Namespace (include "dataplane.metabase.admin.secret" .) -}}
{{- if $secret -}}
{{/*
   Reuse existing secret data
*/}}
password: {{ $secret.data.password }}
{{- else -}}
{{/*
    Generate new secret
*/}}
password: {{ randAlphaNum 16 | b64enc }}
{{- end -}}
{{- end -}}
