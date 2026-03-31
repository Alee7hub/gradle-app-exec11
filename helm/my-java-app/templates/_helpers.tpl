{{/*
Expand the name of the chart.
*/}}
{{- define "my-java-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a fully-qualified app name.
If Release.Name already contains the chart name the chart name is omitted to
avoid duplicates like "my-release-my-java-app-my-java-app".
*/}}
{{- define "my-java-app.fullname" -}}
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
Chart label  (name-version, e.g. my-java-app-0.1.0)
*/}}
{{- define "my-java-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels applied to every resource.
*/}}
{{- define "my-java-app.labels" -}}
helm.sh/chart: {{ include "my-java-app.chart" . }}
{{ include "my-java-app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels used by Deployment / Service.
*/}}
{{- define "my-java-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "my-java-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Name of the ConfigMap created by this chart.
*/}}
{{- define "my-java-app.configmapName" -}}
{{- printf "%s-configmap" (include "my-java-app.fullname" .) }}
{{- end }}

{{/*
Name of the Secret created by this chart.
*/}}
{{- define "my-java-app.secretName" -}}
{{- printf "%s-secret" (include "my-java-app.fullname" .) }}
{{- end }}
