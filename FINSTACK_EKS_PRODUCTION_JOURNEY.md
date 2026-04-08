# Finstack Project: ECS to EKS Migration Journey 🚀

Ye document humari poori Finstack migration journey ki summary hai — AWS ECS (Fargate) se lekar EKS (Managed Node Groups) tak. Humne kya-kya kiya, kyun kiya, aur raste mein aayi hui mushkilon ko kaise solve kiya, sab isme cover kiya gaya hai.

---

## 1. Shuruaat: Humne Migrate Kyun Kiya? (Why ECS → EKS?)

Pehle Finstack **AWS ECS (Fargate)** par chal raha tha. Humne **EKS (Elastic Kubernetes Service)** with **Managed Node Groups** par migrate karne ka faisla liya taaki:
- **Kubernetes Standard:** ECS sirf AWS proprietary hai, jabki Kubernetes ek open-source industry standard hai — Google Cloud, Azure, on-prem kahi bhi portable.
- **Better Ecosystem:** Kubernetes ka ecosystem (Helm, ArgoCD, Prometheus, FluentBit) ECS se kahin zyada mature hai.
- **Managed Compute:** Managed Node Groups mein AWS EC2 nodes ko automatically provision, patch aur upgrade karta hai.
- **Full Flexibility:** DaemonSets, EBS/EFS volumes, privileged containers — sab supported. ECS Fargate mein ye limitations thi.
- **Microservices Architecture:** Kubernetes 8 microservices (auth, gateway, frontend, mongodb, user, payment, transaction, notification) ko behtar tareeke se manage, scale aur self-heal kar sakta hai.

---

## 2. Humne Kya-Kya Kiya? (Architecture & Steps)

### Infrastructure as Code (Terraform)

| Component | Details |
|---|---|
| **VPC** | `10.0.0.0/16` — 2 Public + 2 Private subnets across `eu-north-1a` & `eu-north-1b` |
| **EKS Cluster** | `finstack-cluster` v1.31 |
| **Managed Node Group** | `t3.medium`, auto-scaling min 1, desired 2, max 4 nodes (private subnets) |
| **NAT Gateway** | Public subnet mein, private pods ke internet access ke liye |
| **EFS** | Encrypted filesystem with Access Points — Prometheus, Grafana, Alertmanager |
| **IRSA** | IAM Roles for Service Accounts — ALB Controller, EFS CSI Driver, External Secrets |
| **ALB Controller** | AWS Load Balancer Controller for Ingress-based ALB provisioning |

### Kubernetes Add-ons (Helm via Terraform)
- **ArgoCD** — GitOps (Redis persistence enabled with EBS)
- **External Secrets Operator** — AWS Secrets Manager integration (webhook enabled)
- **FluentBit** — DaemonSet logging → CloudWatch
- **EFS CSI Driver** — DaemonSet on each node for EFS volume mounting

---

## 3. ECS vs EKS — Before & After Comparison

| Aspect | ECS (Fargate) — Before | EKS (Managed Node Groups) — After |
|---|---|---|
| **Compute** | Fargate serverless tasks | EC2 Managed Node Group (auto-scaling) |
| **Orchestration** | ECS proprietary | Kubernetes (portable, industry standard) |
| **DaemonSets** | ❌ Not supported | ✅ FluentBit, EFS CSI, all standard tools |
| **Storage** | EFS only (limited) | EFS + EBS both supported |
| **Logging** | CloudWatch Logs (basic) | FluentBit DaemonSet (full control, custom parsing) |
| **GitOps** | ❌ Not available | ✅ ArgoCD |
| **Secrets** | ECS Task Definitions | External Secrets Operator → AWS Secrets Manager |
| **Monitoring** | CloudWatch metrics only | Prometheus + Grafana (EFS-backed persistent) |
| **Ingress** | ALB Target Groups manually | AWS Load Balancer Controller (automatic) |
| **IaC** | ECS Task/Service Definitions | Kubernetes Manifests + Helm Charts |

---

## 4. Raste Ki Mushkilein Aur Unke Solutions (Problems Faced & Fixed)

Humne EKS migration ke dauran aayi bahut si complex problems ko troubleshoot kiya:

### A. ImagePullBackOff Error 🛠️
- **Problem:** Pods deploy nahi ho pa rahe the kyunki container image tags `:1.1` outdated the.
- **Solution:** Humne saare K8s deployment manifests ko update karke `:latest` tag use kiya, jisse containers smoothly chalne lage.

### B. CoreDNS Configuration 🛠️
- **Problem:** CoreDNS pods initially issues face kar rahe the aur DNS resolution fail ho raha tha (`EAI_AGAIN` error). Services apas mein communicate nahi kar pa rahi thi.
- **Solution:** CoreDNS deployment ko properly configure kiya taaki wo managed nodes par schedule ho sake aur DNS issue resolve ho gaya.

### C. Ingress / ALB Provisioning Failure (AccessDenied) 🛠️
- **Problem:** Ingress resource ALB assign nahi kar pa raha tha. AWS Load Balancer controller logs mein `wafv2:GetWebACLForResource` ki *AccessDenied* errors aa rahi thi.
- **Solution:** Humne Terraform (`irsa.tf`) mein Controller ke IAM role ko update kiya. AWS ki official complete ALB IAM policy document (`iam_policy.json`) lagaye, jisse ALB address successfully populate ho gaya.

### D. EFS DNS Resolution Failure 🛠️
- **Problem:** Monitoring pods ko EFS mount nahi ho raha tha — `FailedMount: Failed to resolve fs-xxx.efs.eu-north... connection refused`.
- **Solution:** VPC mein `EnableDnsHostnames` enable kiya aur EFS Security Group mein NFS traffic (port 2049) ko VPC CIDR (`10.0.0.0/16`) se allow kiya.

### E. Grafana SQLite Database Locked 🛠️
- **Problem:** Grafana baar-baar crash ho raha tha (`CrashLoopBackOff`) — error: `Database locked, sleeping then retrying`.
- **Root Cause:** Grafana internally SQLite use karta hai. `RollingUpdate` strategy mein naya pod purane ke saath simultaneously chalta hai. Dono ek hi EFS file par write lock lagate hain — SQLite NFS par concurrent multi-writers support nahi karta.
- **Solution:** Helm chart mein deployment strategy `RollingUpdate` se **`Recreate`** kiya — purana pod pehle kill, lock release, phir naya pod start.

---

## 5. Current Architecture (Final State) ✅

- **Infrastructure:** VPC (2-AZ), NAT Gateway, EKS v1.31 — all via Terraform
- **Compute:** Managed Node Group (`t3.medium`, auto-scaling 1-4, private subnets)
- **Networking:** ALB via AWS Load Balancer Controller, IRSA-based security
- **Storage:** Amazon EFS with Access Points (Prometheus, Grafana, Alertmanager)
- **Observability:** Prometheus + Grafana (EFS-backed), FluentBit DaemonSet → CloudWatch
- **GitOps:** ArgoCD with Redis persistence (EBS)
- **Secrets:** External Secrets Operator → AWS Secrets Manager (webhook enabled)

---

## 6. Conclusion 🎯

Finstack ko **AWS ECS (Fargate)** se **EKS (Managed Node Groups)** par migrate karke humne:
- ECS ki proprietary limitations se chutkara paaya
- Kubernetes ka full ecosystem (Helm, ArgoCD, Prometheus, FluentBit) leverage kiya
- Production-grade observability stack build kiya
- GitOps-based deployment pipeline setup ki
- Infrastructure as Code se poori infrastructure reproducible banayi

Current setup **Highly Available, Scalable, Observable, aur fully Enterprise-Ready** hai — "Top-Tier" DevOps / SRE standards ke bilkul barabar! 💪
