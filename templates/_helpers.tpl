{{/*
Return customized or generic app metadata
metadata: {{- include "app.metadata" (dict "customName" .Values.someObject.name "customNamespace" .Values.someObject.namespace "customAnnotations" .Values.someObject.annotations "context" .) | nindent 2 }}
metadata: {{- include "app.metadata" . | nindent 2 }}
*/}}
{{- define "app.metadata" -}}
{{- $context := (hasKey . "context" | ternary .context .) -}}
name: {{ default (include "common.names.fullname" $context) .customName }}
namespace: {{ default (include "common.names.namespace" $context) .customNamespace | quote }}
labels: {{- include "common.labels.standard" ( dict "customLabels" $context.Values.commonLabels "context" $context ) | nindent 2 }}
{{- if or .customAnnotations $context.Values.commonAnnotations }}
{{- $annotations := include "common.tplvalues.merge" ( dict "values" ( list .customAnnotations $context.Values.commonAnnotations ) "context" $context ) }}
annotations: {{- include "common.tplvalues.render" ( dict "value" $annotations "context" $context) | nindent 2 }}
{{- end }}
{{- end -}}

{{/*
Return the name of the Service Account
*/}}
{{- define "app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
  {{- default (include "common.names.fullname" .) .Values.serviceAccount.name }}
{{- else }}
  {{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Return the app image name
*/}}
{{- define "app.image" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.app.image "global" .Values.global) -}}
{{- end -}}

{{/*
Return the proper Docker Image Registry Secret names
*/}}
{{- define "app.imagePullSecrets" -}}
{{- include "common.images.pullSecrets" (dict "images" (list .Values.app.image) "global" .Values.global) -}}
{{- end -}}
