# Finstack Platform Engineer Interview Cheat Sheet

This document contains a comprehensive breakdown of the Finstack architecture and the technical rationale behind every SRE/DevOps decision. Use this to articulate your system design in a Senior Cloud/Platform Engineering interview.

## 1. Infrastructure as Code (Terraform)
**Q: Why did you decouple your Terraform code into Two Tiers (`infra` and `k8s-addons`)?**
* **Answer:** Initially, using a monolithic approach caused "Kubernetes cluster unreachable" errors. This is the classic "chicken-and-egg" problem: Terraform tried to initialize the Helm/Kubernetes providers before the AWS EKS cluster was even successfully created. By decoupling them, Phase 1 (`infra`) builds the VPC and EKS, and Phase 2 (`k8s-addons`) uses `data.terraform_remote_state` to read the cluster endpoint and apply Helm charts safely.

**Q: How do you handle Terraform state in a team?**
* **Answer:** I migrated the local state to an S3 bucket with DynamoDB state locking. This ensures that multiple developers cannot run `terraform apply` concurrently, preventing state corruption and maintaining a Single Source of Truth.

## 2. Compute (EKS & Fargate)
**Q: Why did you choose AWS Fargate over managed EC2 Node Groups?**
* **Answer:** Fargate provides serverless compute for containers. It eliminates the operational overhead of patching, scaling, and managing EC2 instances. You only pay for the exact CPU/RAM standard requested by the Pod, which is heavily optimized for microservices with variable workloads like Finstack.

## 3. Storage (EFS & SQLite)
**Q: How did you solve the persistent storage challenge for your database?**
* **Answer:** Originally, using EBS volumes caused issues because EBS is tied to a single Availability Zone and doesn't inherently support `ReadWriteMany`. Additionally, Fargate does not natively support EBS scaling the same way. I implemented the **EFS CSI Driver** using AWS Elastic File System. EFS is an NFS-based distributed filesystem that allows Fargate pods to mount persistent storage across multiple AZs flexibly, solving file-locking issues with databases.

## 4. Security & Secrets Management
**Q: Are your database passwords stored in Kubernetes YAMLs?**
* **Answer:** Absolutely not. I implemented the **External Secrets Operator (ESO)**. Instead of hardcoding secrets or managing HashiCorp Vault (which adds massive operational cost and complexity), ESO uses an IAM Role for Service Accounts (IRSA) to authenticate with AWS. It retrieves credentials securely from **AWS Secrets Manager** and dynamically injects them as native Kubernetes `Secret` objects into the cluster (Least-privilege design).

## 5. Continuous Deployment & GitOps
**Q: How do applications get deployed into your EKS cluster?**
* **Answer:** I utilize a GitOps approach using **ArgoCD**. Instead of running `kubectl apply` from a CI pipeline (which requires giving external systems administrative access to the cluster), ArgoCD lives *inside* the cluster. It constantly monitors the GitHub deployment repository. If there's a drift between the Git repository and the cluster state, ArgoCD automatically syncs and heals the cluster.

## 6. Observability (Metrics vs Logs)
**Q: What is your observability strategy for Fargate?**
* **Answer:** I employ a dual-pillar strategy:
  1. **Metrics (The "WHAT"):** Prometheus and Grafana are used to monitor time-series data like CPU, RAM, and request rates to trigger automated alerts.
  2. **Logs (The "WHY"):** Since Fargate doesn't have node-level storage for DaemonSets, I enabled AWS's native Fargate Logging by creating an `aws-observability` namespace and ConfigMap. This seamlessly instructs the underlying **FluentBit** router to ship all standard output container logs to **Amazon CloudWatch Logs** for root-cause analysis without consuming our own pod resources.

## 7. Cost Operations (FinOps)
**Q: How do you ensure infrastructure changes don't blow up the cloud budget?**
* **Answer:** I integrated **Infracost** directly into the GitHub Actions CI/CD pipeline. Whenever a developer raises a Pull Request modifying the Terraform code, the pipeline runs a `terraform plan` and Infracost parses the JSON output to generate a highly accurate, table-formatted monthly cost estimate as a PR comment. This empowers the team to catch expensive misconfigurations *before* they are applied to production.
