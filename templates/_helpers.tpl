{{- define "valkey-app.labels" -}}
app.kubernetes.io/part-of: valkey-app
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
