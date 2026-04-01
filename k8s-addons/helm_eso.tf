# External Secrets Operator Helm Installation
resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  namespace        = "external-secrets"
  create_namespace = true
  version          = "0.10.4" # Latest stable version

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "webhook.create"
    value = "false" # Fargate clusters often have webhook issues unless specific configurations are used, keeping it simple
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "external-secrets"
  }

  # Link the IAM Role from the "infra" tier remote state to this Kubernetes Service Account
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = data.terraform_remote_state.infra.outputs.eso_role_arn
  }
}
