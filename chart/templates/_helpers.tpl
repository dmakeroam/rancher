{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "rancher.name" -}}
  {{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "rancher.fullname" -}}
  {{- $name := default .Chart.Name .Values.nameOverride -}}
  {{- if contains $name .Release.Name -}}
    {{- .Release.Name | trunc 63 | trimSuffix "-" -}}
  {{- else -}}
    {{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
  {{- end -}}
{{- end -}}

{{/*
Create a default fully qualified chart name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "rancher.chartname" -}}
  {{- printf "%s-%s" .Chart.Name .Chart.Version | trunc 63 | trimSuffix "-" -}}
{{- end -}}

# Render Values in configurationSnippet
{{- define "configurationSnippet" -}}
  {{- tpl (.Values.ingress.configurationSnippet) . | nindent 6 -}}
{{- end -}}

{{/*
Generate the labels.
*/}}
{{- define "rancher.labels" -}}
app: {{ template "rancher.fullname" . }}
chart: {{ template "rancher.chartname" . }}
heritage: {{ .Release.Service }}
release: {{ .Release.Name }}
{{- end }}

# Windows Support

{{/*
Windows cluster will add default taint for linux nodes,
add below linux tolerations to workloads could be scheduled to those linux nodes
*/}}

{{- define "linux-node-tolerations" -}}
- key: "cattle.io/os"
  value: "linux"
  effect: "NoSchedule"
  operator: "Equal"
{{- end -}}

{{- define "node-tolerations-with-default" -}}
{{ include "linux-node-tolerations" . | nindent 8 }}
{{- with .Values.tolerations }}
{{- toYaml . | nindent 8 }}
{{- end -}}
{{- end -}}

{{- define "linux-node-selector-terms" -}}
{{- $key := "kubernetes.io/os" -}}
{{- if semverCompare "<1.14-0" .Capabilities.KubeVersion.GitVersion }}
{{- $key := "beta.kubernetes.io/os" -}}
{{- end -}}
- matchExpressions:
  - key: {{ $key }}
    operator: NotIn
    values:
    - windows
{{- end -}}


{{- define "required-scheduling-node-selector-terms" -}}
requiredDuringSchedulingIgnoredDuringExecution:
           nodeSelectorTerms: {{ include "linux-node-selector-terms" . | nindent 14 }}
{{- end -}}

{{- define "node-affinity-with-default" -}}
{{- if .Values.nodeAffinity }}
{{- $nodeAffinity := .Values.nodeAffinity | nindent 10 -}}
{{- $requiredSchedulingNodeSelectorTerms := include "required-scheduling-node-selector-terms" . -}}
{{- $result := merge $nodeAffinity $requiredSchedulingNodeSelectorTerms }}
{{- else -}}
{{- include "required-scheduling-node-selector-terms" . -}}
{{- end -}}
{{- end -}}

{{- define "system_default_registry" -}}
{{- if .Values.systemDefaultRegistry -}}
  {{- if hasSuffix "/" .Values.systemDefaultRegistry -}}
    {{- printf "%s" .Values.systemDefaultRegistry -}}
  {{- else -}}
    {{- printf "%s/" .Values.systemDefaultRegistry -}}
{{- end -}}
{{- end -}}
{{- end -}}

