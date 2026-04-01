# AWS Observability Namespace for Fargate Native Logging (FluentBit)
resource "kubernetes_namespace" "aws_observability" {
  metadata {
    name = "aws-observability"
    labels = {
      aws-observability = "enabled"
    }
  }
}

# ConfigMap configuring the FluentBit Engine to send logs to CloudWatch
resource "kubernetes_config_map" "aws_logging" {
  metadata {
    name      = "aws-logging"
    namespace = kubernetes_namespace.aws_observability.metadata[0].name
  }

  data = {
    "output.conf" = <<EOF
[OUTPUT]
    Name cloudwatch_logs
    Match *
    region eu-north-1
    log_group_name /eks/finstack-fargate-logs
    log_stream_prefix fargate-
    auto_create_group true
EOF
  }
}
