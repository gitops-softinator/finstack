# FluentBit DaemonSet Logging via Helm
# On managed node groups, FluentBit runs as a DaemonSet on each node
resource "helm_release" "fluentbit" {
  name             = "fluent-bit"
  repository       = "https://fluent.github.io/helm-charts"
  chart            = "fluent-bit"
  namespace        = "aws-observability"
  create_namespace = true

  set {
    name  = "config.outputs"
    value = <<-EOF
[OUTPUT]
    Name cloudwatch_logs
    Match *
    region eu-north-1
    log_group_name /eks/finstack-cluster-logs
    log_stream_prefix node-
    auto_create_group true
EOF
  }
}
