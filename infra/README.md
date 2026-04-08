# Finstack Infrastructure Guide (AWS EKS)

This directory contains the **Infrastructure as Code (IaC)** for the Finstack platform on AWS. The system is built on **AWS EKS (Elastic Kubernetes Service)** using **Managed Node Groups** (EC2-based worker nodes).

## Infrastructure Overview

The infrastructure provides a highly available, secure, and scalable environment for microservices.

### Core Components
- **EKS Cluster**: Managed Kubernetes control plane (v1.31).
- **Managed Node Group**: EC2-based worker nodes (`t3.medium` by default) with auto-scaling (1-4 nodes).
- **VPC Networking**: Custom VPC with Public/Private subnets across 2 Availability Zones.
- **ALB Ingress Controller**: Automated AWS Application Load Balancer management via the **AWS Load Balancer Controller**.
- **Security (IRSA)**: IAM Roles for Service Accounts to provide fine-grained permissions to Kubernetes Pods.
- **EFS Storage**: Encrypted EFS for persistent storage (Prometheus, Grafana, Alertmanager).

---

## 🛠️ Infrastructure Setup

To provision the entire environment, follow these steps:

1.  **Initialize Terraform**:
    ```bash
    cd infra
    terraform init
    ```

2.  **Apply Configuration**:
    ```bash
    terraform apply "finstack_eks_deployment.plan"
    ```
    *This will create the VPC, EKS Cluster, Managed Node Group, and install the Load Balancer Controller via Helm.*

3.  **Update Kubeconfig**:
    Connect your local `kubectl` to the new cluster:
    ```bash
    aws eks update-kubeconfig --name finstack-cluster --region eu-north-1
    ```

---

## 🚀 Application Deployment

Once the infrastructure is ready, deploy the microservices using the organized manifests in the `../k8s` directory.

### Deployment Steps

1.  **Create Namespace**:
    ```bash
    kubectl apply -f ../k8s/finstack-namespace.yaml
    ```

2.  **Deploy Everything (Recursive)**:
    ```bash
    kubectl apply -R -f ../k8s/
    ```
    *This will automatically deploy all microservices from the `deployments/`, `services/`, and `ingress/` subdirectories.*

---

## 🔍 Verification & Monitoring

### Check Cluster Status
```bash
kubectl get nodes           # Should show EC2 worker nodes
kubectl get pods -n finstack # All services should be Running
```

### Check Ingress (External URL)
```bash
kubectl get ingress -n finstack
```
*Wait for the **ADDRESS** field to populate with the ALB DNS name. It may take 2-3 minutes for the ALB to become active.*

### Logs
Centralized logs are available in **AWS CloudWatch** under the prefix `/aws/eks/finstack-cluster`.

---

## 📂 File Structure

- **`vpc.tf`**: Networking, Subnets, and NAT Gateway.
- **`eks.tf`**: EKS Cluster and Managed Node Group.
- **`irsa.tf`**: IAM Roles for Service Accounts (Security).
- **`efs.tf`**: EFS File System and Access Points for monitoring.
- **`security.tf`**: ALB and EKS Cluster Security Groups.
- **`provider.tf`**: AWS and TLS provider configurations.
- **`variables.tf`**: Configurable variables (region, instance type, scaling).
- **`output.tf`**: Infrastructure outputs (cluster info, role ARNs, VPC ID).
- **`backend.tf`**: S3 remote state configuration.
