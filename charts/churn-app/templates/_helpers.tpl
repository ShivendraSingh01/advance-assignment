{{- define "churn-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "churn-app.fullname" -}}
{{- default (include "churn-app.name" .) .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "churn-app.labels" -}}
app.kubernetes.io/name: {{ include "churn-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app: {{ include "churn-app.name" . }}
environment: {{ .Values.environment | quote }}
strategy: {{ .Values.deploymentStrategy | quote }}
{{- end -}}
