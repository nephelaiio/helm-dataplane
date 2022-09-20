{{/*
Expand the name of the chart.
*/}}
{{- define "metabase.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "metabase.fullname" -}}
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
{{- define "metabase.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "metabase.labels" -}}
helm.sh/chart: {{ include "metabase.chart" . }}
{{ include "metabase.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "metabase.selectorLabels" -}}
app.kubernetes.io/name: {{ include "metabase.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "metabase.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "metabase.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
DB name
*/}}
{{- define "metabase.db.name" -}}
{{- (printf "%s-%s" (include "metabase.fullname" .) "db") -}}
{{- end }}

{{/*
DB team name
*/}}
{{- define "metabase.db.team" -}}
{{- include "metabase.fullname" . -}}
{{- end }}

{{/*
TLS secret name
*/}}
{{- define "metabase.ingress.secretName" -}}
{{- if .Values.ingress.secretName }}
{{- .Values.ingress.secretName }}
{{- else }}
{{- (printf "%s-%s" (include "metabase.fullname" .) "tls") -}}
{{- end }}
{{- end }}

{{/*
API secret name
*/}}
{{- define "metabase.apiSecretName" -}}
{{- (printf "%s-%s" (include "metabase.fullname" .) "api-token") -}}
{{- end }}

{{/*
Stable API secret data
*/}}
{{- define "api.secret" -}}
{{- $secret := lookup "v1" "Secret" .Release.Namespace (include "metabase.apiSecretName" .) -}}
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
