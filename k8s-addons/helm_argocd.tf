# ArgoCD Helm Installation
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "5.46.8"

  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }

  # Redis persistence can be enabled with managed node groups (EBS supported)
  set {
    name  = "redis.persistence.enabled"
    value = "true"
  }
}
