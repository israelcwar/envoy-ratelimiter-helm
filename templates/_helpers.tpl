{{/* vim: set filetype=mustache: */}}

{{/* Expand the name of the chart. */}}
{{- define "ratelimiter.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "ratelimiter.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/* Create chart name and version as used by the chart label. */}}
{{- define "ratelimiter.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Helm labels */}}
{{- define "ratelimiter.helmLabels" -}}
helm.sh/chart: {{ template "ratelimiter.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/* Version labels */}}
{{- define "ratelimiter.versionLabels" -}}
app.kubernetes.io/version: {{ .Chart.Version | replace "+" "_" }}
{{- end -}}

{{/* Helm required labels */}}
{{- define "ratelimiter.labels" -}}
app.kubernetes.io/component: ratelimiter
{{- with (include "ratelimiter.helmLabels" .) }}
{{ . }}
{{- end }}
{{- with (include "ratelimiter.matchLabels" .) }}
{{ . }}
{{- end }}
app.kubernetes.io/part-of: {{ template "ratelimiter.name" . }}
{{- with (include "ratelimiter.versionLabels" .) }}
{{ . }}
{{- end }}
{{- if .Values.customLabels }}
{{ toYaml .Values.customLabels }}
{{- end }}
{{- end -}}

{{/* Helm required labels */}}
{{- define "ratelimiter.test-labels" -}}
app: ratelimiter
app.kubernetes.io/component: ratelimiter
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/name: {{ template "ratelimiter.name" . }}-test
app.kubernetes.io/part-of: {{ template "ratelimiter.name" . }}
app.kubernetes.io/version: "{{ .Chart.Version | replace "+" "_" }}"
{{- end -}}

{{/* matchLabels */}}
{{- define "ratelimiter.matchLabels" -}}
app.kubernetes.io/name: {{ template "ratelimiter.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}


{{/* Create the name of the service to use */}}
{{- define "ratelimiter.serviceName" -}}
{{- printf "%s-svc" (include "ratelimiter.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "ratelimiter.image" -}}
  {{- if .image.registry -}}
{{ .image.registry }}/{{ required "An image repository is required" .image.repository }}:{{ default .defaultTag .image.tag }}
  {{- else -}}
{{ required "An image repository is required" .image.repository }}:{{ default .defaultTag .image.tag }}
  {{- end -}}
{{- end }}

{{/* Create the default PodDisruptionBudget to use */}}
{{- define "ratelimiter.podDisruptionBudget.spec" -}}
{{- if and .Values.podDisruptionBudget.minAvailable .Values.podDisruptionBudget.maxUnavailable }}
{{- fail "Cannot set both .Values.podDisruptionBudget.minAvailable and .Values.podDisruptionBudget.maxUnavailable" -}}
{{- end }}
{{- if not .Values.podDisruptionBudget.maxUnavailable }}
minAvailable: {{ default 1 .Values.podDisruptionBudget.minAvailable }}
{{- end }}
{{- if .Values.podDisruptionBudget.maxUnavailable }}
maxUnavailable: {{ .Values.podDisruptionBudget.maxUnavailable }}
{{- end }}
{{- end }}

{{/* Create the name of the service account to use */}}
{{- define "ratelimiter.serviceAccountName" -}}
{{- if .Values.rbac.serviceAccount.create -}}
    {{ default (include "ratelimiter.fullname" .) .Values.rbac.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.rbac.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/* Get the namespace name. */}}
{{- define "ratelimiter.namespace" -}}
{{- if .Values.namespace -}}
    {{- .Values.namespace -}}
{{- else -}}
    {{- .Release.Namespace -}}
{{- end -}}
{{- end -}}

{{/*
Calculate the config from structured and unstructred text input
*/}}
{{- define "ratelimiter.calculatedConfig" -}}
{{ tpl (mergeOverwrite (include "ratelimiter.unstructuredConfig" . | fromYaml) .Values.ratelimiter.structuredConfig | toYaml) . }}
{{- end -}}

{{/*
Calculate the config from the unstructred text input
*/}}
{{- define "ratelimiter.unstructuredConfig" -}}
{{ include (print $.Template.BasePath "/_config-render.tpl") . }}
{{- end -}}

{{/* Create the name of the service to use */}}
{{- define "ratelimiter.configMapName" -}}
{{- printf "%s-svc" (include "ratelimiter.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "ratelimiter.securityContext" -}}
{{- if semverCompare "<1.19" .Capabilities.KubeVersion.Version }}
{{ toYaml (omit .Values.securityContext "seccompProfile") }}
{{- else }}
{{ toYaml .Values.securityContext }}
{{- end }}
{{- end }}
