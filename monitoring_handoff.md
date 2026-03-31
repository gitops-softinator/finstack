# Handoff: EKS Fargate Monitoring Setup (Phase 3)

This document summarized the progress of adding a "Top-Tier" observability stack to the Finstack EKS cluster and provides the final steps for Phase 3.

---

## 1. Project Context
- **Cluster**: EKS v1.31 (Fargate-only).
- **Goal**: Implement persistent monitoring (Prometheus + Grafana) using Amazon EFS for a "Top-Tier" resume project.

## 2. Current Architectural State (Phase 1 & 2 Complete)
- **Terraform**: 
  - `infra/efs.tf` created (EFS File System: `fs-0c919cb0f4b5443fd`).
  - `infra/eks.tf` updated (Fargate Profile for `monitoring` namespace).
  - `infra/irsa.tf` updated (IAM Role: `finstack-efs-csi-driver-role` for ServiceAccount `efs-csi-controller-sa` in `kube-system`).
- **Kubernetes**:
  - `monitoring` namespace created.
  - `efs-sc` StorageClass created (Storage Mode: Access Points).
  - **AWS EFS CSI Driver**: Deployed via Helm to `kube-system`.

## 3. Tasks for Phase 3 (Next Model Instructions)

The following steps should be performed to finalize the deployment:

### A. Deploy Prometheus with EFS Persistence
1. Create `k8s/monitoring/prometheus-values.yaml`:
```yaml
server:
  persistentVolume:
    enabled: true
    storageClass: efs-sc
    size: 20Gi
  service:
    type: ClusterIP
```
2. Run Deployment:
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/prometheus \
  --namespace monitoring \
  -f k8s/monitoring/prometheus-values.yaml
```

### B. Deploy Grafana with EFS Persistence
1. Create `k8s/monitoring/grafana-values.yaml`:
```yaml
persistence:
  enabled: true
  storageClass: efs-sc
  size: 5Gi
service:
  type: LoadBalancer
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: nlb
    service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
```
2. Run Deployment:
```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm install grafana grafana/grafana \
  --namespace monitoring \
  -f k8s/monitoring/grafana-values.yaml
```

### C. Final Verification
- Ensure both Prometheus and Grafana pods are `Running`.
- Verify the Grafana LoadBalancer URL.
- Add Prometheus as a Data Source in Grafana (`http://prometheus-server.monitoring.svc.cluster.local`).
