# FinStack

FinStack is a production-ready financial microservices platform designed for high availability and security.

## 🚀 Architecture

The application is built using a **Cloud-Native Microservices** approach, orchestrated on **AWS EKS (Elastic Kubernetes Service)** using **Managed Node Groups**.

### Microservices Catalog
- **Frontend (Port 80)**: React-based client application.
- **API Gateway (Port 3000)**: Single entry point using Express, routing requests to internal services.
- **Auth Service (Port 4000)**: Secure user authentication and JWT-based registrations.
- **User Service (Port 4001)**: Comprehensive user profile and metadata management.
- **Payment Service (Port 4002)**: Real-time payment processing simulation.
- **Notification Service (Port 4003)**: Multi-channel system notifications.
- **Transaction Service (Port 4004)**: Ledger records and transaction history with MongoDB.

For a detailed deep-dive into the system design, network topology, and diagrams, please refer to the **[ARCHITECTURE.md](file:///home/gitops/Desktop/finstack/ARCHITECTURE.md)**. For a beginner-friendly conceptual overview, see the **[CONCEPT_GUIDE.md](file:///home/gitops/Desktop/finstack/CONCEPT_GUIDE.md)**.

---

## 🏗️ Infrastructure & Deployment

The platform is fully automated using **Infrastructure as Code (IaC)**.

*   **Cloud Provider**: AWS
*   **Orchestration**: EKS Managed Node Groups (EC2-based Kubernetes)
*   **Networking**: VPC with isolated Private Subnets, NAT Gateway & AWS Load Balancer Controller.
*   **Provisioning**: [Terraform](file:///home/gitops/Desktop/finstack/infra/)
*   **Deployment**: [Kubernetes Manifests](file:///home/gitops/Desktop/finstack/k8s/)

For setup and deployment instructions, see the **[Infrastructure README](file:///home/gitops/Desktop/finstack/infra/README.md)**.

---

## 🛠️ Quick Start (Local Setup)

If you wish to run the stack locally for development:

```bash
# Start all services using Docker Compose
docker-compose up -d
```

*   **Frontend**: `http://localhost:8080`
*   **API Gateway**: `http://localhost:3000`

---

## 📂 Project Structure

- **[`/infra`](file:///home/gitops/Desktop/finstack/infra/)**: Terraform configuration and infrastructure documentation.
- **[`/k8s`](file:///home/gitops/Desktop/finstack/k8s/)**: Kubernetes manifests organized by type (deployments, services, ingress).
- **[`/services`](file:///home/gitops/Desktop/finstack/services/)**: Backend microservices source code.
- **[`/frontend`](file:///home/gitops/Desktop/finstack/frontend/)**: React client application.
- **[`/gateway`](file:///home/gitops/Desktop/finstack/gateway/)**: API Gateway logic.

---

## 💻 Tech Stack

- **Frontend**: React.js
- **Backend**: Node.js & Express
- **Database**: MongoDB (6.0)
- **Infrastructure**: AWS (EKS, ALB, VPC), Terraform
- **CI/CD**: GitHub Actions & Docker Hub