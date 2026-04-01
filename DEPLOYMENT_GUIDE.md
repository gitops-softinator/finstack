# Finstack EKS Fargate Deployment Guide 🚀

Ye document ek step-by-step guide hai jise follow karke koi bhi naya engineer is poore Finstack application ko scratch se AWS EKS Fargate par deploy kar sakta hai.

---

## Pre-requisites
Aapke system ya CI/CD server par ye tools install hone chahiye:
- **AWS CLI** (configured with appropriate Admin credentials)
- **Terraform** (>= 1.5.0)
- **kubectl**
- **Helm**

---

## Step 1: Infrastructure Provisioning (Terraform)
Sabse pehle hume AWS cloud mein foundation (VPC, Subnets, EKS Cluster, Fargate Profiles, IAM Roles, EFS) banani hai.

```bash
# 1. Terraform directory mein jayein
cd infra/

# 2. Terraform plugins download karein
terraform init

# 3. Infrastructure deploy karein (is process mein 15-20 minutes lag sakte hain)
terraform apply -auto-approve
```

> [!IMPORTANT]
> Jab `terraform apply` khatam ho jaye, toh outputs mein `eks_cluster_name` check karein. Ye `finstack-cluster` hona chahiye.

---

## Step 2: Cluster Connection & CoreDNS Patching
Infrastructure banne ke baad, `kubectl` ko aapke naye EKS cluster se connect karna hoga, aur CoreDNS ko Fargate par chalne ke liye patch karna hoga (kyunki by default CoreDNS EC2 dhoondhta hai).

```bash
# 1. Kubeconfig update karein
aws eks update-kubeconfig --region eu-north-1 --name finstack-cluster

# 2. CoreDNS annotation remove karein taaki Fargate par schedule ho sake
kubectl patch deployment coredns -n kube-system --type json -p='[{"op": "remove", "path": "/spec/template/metadata/annotations/eks.amazonaws.com~1compute-type"}]'

# 3. Restarts the CoreDNS Rollout
kubectl rollout restart -n kube-system deployment coredns
```

---

## Step 3: Deploying Finstack Microservices
Ab humare cluster ka base tayar hai. Ab hum Finstack ki services (Auth, Gateway, Frontend, MongoDB, User, Payment, Transaction, Notification) deploy karenge.

```bash
# 1. Main Directory mein wapas aayein
cd ../k8s/

# 2. Finstack Namespace create karein
kubectl apply -f finstack-namespace.yaml

# 3. Internal Services deploy karein
kubectl apply -f services/

# 4. Applications (Pods) deploy karein
kubectl apply -f deployments/
```

> [!TIP]
> `kubectl get pods -n finstack` chalakar verify karein ki sabhi pods `Running` state mein hain. Fargate par pods aane me thoda time lagta hai (`Pending` state).

---

## Step 4: Routing Traffic & Public Access (Ingress)
Humne AWS Load Balancer Controller (ALB) ko Terraform ke zariye install kar diya hai. Ab hum Ingress rule banayenge jo external traffic ko `finstack-gateway` aur `finstack-frontend` par route karega.

```bash
kubectl apply -f ingress/finstack-ingress.yaml

# Ingress ka URL (Address) check karne ke liye run karein:
# (ALB provision hone mein 2-3 minutes lag sakte hain)
kubectl get ingress -n finstack
```

---

## Step 5: Advanced Observability Stack (Optional / Expert)
Monitoring data (Prometheus & Grafana) ko EFS (Elastic File System) ke through permanently save karne ke liye.

```bash
# 1. Monitoring Namespace & Storage Classes apply karein
kubectl apply -f monitoring/efs-setup.yaml

# 2. Helm se EFS CSI Driver Install karein
helm repo add aws-efs-csi-driver https://kubernetes-sigs.github.io/aws-efs-csi-driver/
helm repo update
helm install aws-efs-csi-driver aws-efs-csi-driver/aws-efs-csi-driver \
  --namespace kube-system \
  --set controller.serviceAccount.create=false \
  --set controller.serviceAccount.name=efs-csi-controller-sa

# 3. Helm se Prometheus Install karein (with EFS PVC bindings)
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/prometheus \
  --namespace monitoring \
  -f monitoring/prometheus-values.yaml

# 4. Helm se Grafana Install karein (with EFS PVC bindings)
helm repo add grafana https://grafana.github.io/helm-charts
helm install grafana grafana/grafana \
  --namespace monitoring \
  -f monitoring/grafana-values.yaml
```

---

## 🎉 Verification Complete
Sab kuch set hone ke baad aapka pura Finstack Platform running hoga:
- Browser mein Ingress ka ALB URL open karein (Frontend).
- Grafana ke URL par jaakar (LoadBalancer IP) dashboards check karein.
