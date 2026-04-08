# Finstack Platform Engineer Interview Cheat Sheet

This document contains a comprehensive breakdown of the Finstack architecture and the technical rationale behind every SRE/DevOps decision. Use this to articulate your system design in a Senior Cloud/Platform Engineering interview.

## 1. Infrastructure as Code (Terraform)
**Q: Why did you decouple your Terraform code into Two Tiers (`infra` and `k8s-addons`)?**
* **Answer:** Initially, using a monolithic approach caused "Kubernetes cluster unreachable" errors. This is the classic "chicken-and-egg" problem: Terraform tried to initialize the Helm/Kubernetes providers before the AWS EKS cluster was even successfully created. By decoupling them, Phase 1 (`infra`) builds the VPC and EKS, and Phase 2 (`k8s-addons`) uses `data.terraform_remote_state` to read the cluster endpoint and apply Helm charts safely.

**Q: How do you handle Terraform state in a team?**
* **Answer:** I migrated the local state to an S3 bucket with DynamoDB state locking. This ensures that multiple developers cannot run `terraform apply` concurrently, preventing state corruption and maintaining a Single Source of Truth.

## 2. Compute — The ECS to EKS Migration
**Q: Why did you migrate from ECS (Fargate) to EKS (Managed Node Groups)?**
* **Answer:** Our application was running on ECS with Fargate, which is AWS's proprietary container orchestration. We migrated to EKS for several strategic reasons:
  - **Portability:** ECS locks you into AWS. Kubernetes is an open-source industry standard — the same manifests work on Google Cloud, Azure, or on-premise.
  - **Ecosystem:** Kubernetes has a vastly richer ecosystem — Helm charts, ArgoCD for GitOps, Prometheus for monitoring, FluentBit DaemonSets for logging, External Secrets Operator for secrets management. These tools either don't exist or are very limited in the ECS world.
  - **DaemonSets & EC2 capabilities:** ECS Fargate doesn't support DaemonSets, EBS volumes, or privileged containers. With EKS Managed Node Groups, we get full EC2 flexibility while AWS still manages provisioning, patching, and AMI upgrades.
  - **Industry skillset:** Kubernetes expertise is highly transferable and in-demand across the industry, unlike ECS which is an AWS-only skill.

**Q: Why Managed Node Groups specifically instead of self-managed nodes?**
* **Answer:** Managed Node Groups provide the best balance — AWS handles node provisioning, AMI updates, and lifecycle management automatically, while we retain full control over instance types, scaling policies, and Kubernetes configurations. We configured `t3.medium` instances with auto-scaling from 1 to 4 nodes.

## 3. Storage (EFS & SQLite)
**Q: How did you solve the persistent storage challenge?**
* **Answer:** EBS is AZ-locked and doesn't support `ReadWriteMany`. I implemented the **EFS CSI Driver** with Amazon EFS — an NFS-based distributed filesystem for multi-AZ shared storage. The CSI driver runs as a DaemonSet on each worker node, handling volume mounting seamlessly. We also created dedicated EFS Access Points with POSIX ownership for Prometheus (65534:65534) and Grafana (472:472).

**Q: What was the SQLite locking issue?**
* **Answer:** Grafana uses SQLite internally. During a `RollingUpdate`, two pods simultaneously accessed the same EFS-mounted SQLite file, causing `Database locked` crashes. SQLite doesn't support concurrent writers over NFS. The fix was changing the deployment strategy to `Recreate` — ensuring the old pod terminates completely before the new one starts.

## 4. Security & Secrets Management
**Q: Are your database passwords stored in Kubernetes YAMLs?**
* **Answer:** Absolutely not. I implemented the **External Secrets Operator (ESO)**. ESO uses IRSA to authenticate with AWS and retrieves credentials from **AWS Secrets Manager**, injecting them as native Kubernetes Secrets. This was a major upgrade from ECS where we were using ECS Task Definition environment variables and SSM Parameter Store — ESO provides a more Kubernetes-native and GitOps-friendly approach.

## 5. Continuous Deployment & GitOps
**Q: How do applications get deployed into your EKS cluster?**
* **Answer:** I utilize a GitOps approach using **ArgoCD**. ArgoCD lives inside the cluster and monitors the GitHub repository. If there's drift between Git and cluster state, ArgoCD automatically syncs and heals. This was one of the key drivers for the ECS → EKS migration — proper GitOps wasn't achievable on ECS.

## 6. Observability (Metrics vs Logs)
**Q: What is your observability strategy?**
* **Answer:** On ECS we were limited to CloudWatch metrics and basic logging. After migrating to EKS, I built a dual-pillar strategy:
  1. **Metrics (The "WHAT"):** Prometheus and Grafana monitor time-series data (CPU, RAM, request rates) to trigger alerts. Both use EFS-backed persistent storage with dedicated Access Points.
  2. **Logs (The "WHY"):** **FluentBit** runs as a DaemonSet on every managed node, collecting container logs and shipping them to **Amazon CloudWatch Logs** with custom parsing and filtering — something impossible on ECS Fargate where you were limited to basic CloudWatch log drivers.

## 7. Cost Operations (FinOps)
**Q: How do you ensure infrastructure changes don't blow up the cloud budget?**
* **Answer:** I integrated **Infracost** directly into the GitHub Actions CI/CD pipeline. Whenever a developer raises a Pull Request modifying the Terraform code, the pipeline runs a `terraform plan` and Infracost parses the JSON output to generate a table-formatted monthly cost estimate as a PR comment. This empowers the team to catch expensive misconfigurations *before* they are applied to production.

## 8. Architecture Evolution
**Q: What's the biggest architectural lesson from this project?**
* **Answer:** The ECS → EKS migration taught me that **choosing industry-standard open-source tools over proprietary services pays dividends long-term.** ECS was simpler initially, but it limited our ability to use the rich Kubernetes ecosystem. After migrating to EKS, we could implement ArgoCD, Prometheus, FluentBit DaemonSets, and External Secrets Operator — all industry-standard tools that would have been impossible or severely limited on ECS.
