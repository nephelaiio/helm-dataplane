{{/*
Expand the name of the chart.
*/}}
{{- define "dataplane.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
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
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
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
{{ include "dataplane.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "dataplane.selectorLabels" -}}
app.kubernetes.io/name: {{ include "dataplane.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "dataplane.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "dataplane.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
DB team name
*/}}
{{- define "dataplane.zalando.team" -}}
{{- include "dataplane.name" . -}}
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
Metabase DB user secret
 */}}
{{- define "dataplane.metabase.secret" -}}
{{ .Values.zalando.metabase.user }}-{{- include "dataplane.metabase.cluster" . -}}
{{- end }}

{{/*
Warehouse cluster name
*/}}
{{- define "dataplane.warehouse.cluster" -}}
{{- (printf "%s-%s" (include "dataplane.zalando.team" .) (include "dataplane.zalando.warehouse.db" .)) -}}
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
{{- define "dataplane.ingress.secretName" -}}
{{- if .Values.ingress.secretName }}
{{- .Values.ingress.secretName }}
{{- else }}
{{- (printf "%s-%s" (include "dataplane.fullname" .) "tls") -}}
{{- end }}
{{- end }}

{{/*
API secret name
*/}}
{{- define "dataplane.metabase.api.secret.name" -}}
{{- (printf "%s-%s" (include "dataplane.name" .) "metabase-api-token") -}}
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
