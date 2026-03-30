# Finstack System Architecture

This document describes the high-level architecture of the Finstack platform, a microservices-based financial application deployed on AWS using Terraform and ECS Fargate.

## 1. High-Level Design

The system follows a **Cloud-Native Microservices** pattern, where each functional area is isolated into its own service. All internal services are deployed in **Private Subnets** for maximum security, with an **API Gateway** acting as the single entry point for backend operations.

### Architecture Diagram

```mermaid
graph TD
    subgraph "External"
        User((User))
    end

    subgraph "AWS VPC (10.0.0.0/16)"
        subgraph "Public Subnets"
            ALB[Application Load Balancer]
            NAT[NAT Gateway]
        end

        subgraph "Private Subnets"
            subgraph "ECS Cluster: finstack-cluster"
                Frontend[Frontend Service]
                Gateway[API Gateway]
                
                subgraph "Backend Services"
                    Auth[Auth Service]
                    UserSvc[User Service]
                    Pay[Payment Service]
                    Notif[Notification Service]
                    Trans[Transaction Service]
                end
            end
        end
    end

    %% Inbound Traffic
    User -- "HTTP :80" --> ALB
    ALB -- "Port 80 (Path: /)" --> Frontend
    ALB -- "Port 3000 (Path: /api/*)" --> Gateway
    
    %% Internal Routing
    Gateway -- "Port 4000" --> Auth
    Gateway -- "Port 4001" --> UserSvc
    Gateway -- "Port 4002" --> Pay
    Gateway -- "Port 4003" --> Notif
    Gateway -- "Port 4004" --> Trans

    %% Outbound Traffic (Updates/APIs)
    Backend Services -- "Outbound" --> NAT
    NAT -- "0.0.0.0/0" --> Internet((Internet))
```

---

## 2. Infrastructure Components

### **Networking & Connectivity**
*   **VPC**: Isolated network boundary with a `10.0.0.0/16` CIDR block.
*   **Subnets**:
    *   **Public**: Hosts the ALB and NAT Gateway.
    *   **Private**: Hosts all ECS Fargate tasks (Frontend, Gateway, and Services).
*   **NAT Gateway**: Provides one-way internet egress for private services (to fetch updates or call external APIs) without allowing inbound connections.
*   **Service Discovery**: Uses **AWS Cloud Map** (`finstack.local`) for internal DNS resolution between microservices.

### **Compute (ECS Fargate)**
All services run on **AWS Fargate**, a serverless container engine.
*   **Scaling**: Each service is configured with a `desired_count` (currently 2 for Frontend/Gateway and 1 for others for cost-optimization during dev).
*   **Logging**: Centralized logs for all containers are streamed to **AWS CloudWatch** under the `/ecs/` log group prefix.

---

## 3. Security Model (Production-Grade)

The architecture implements a strict **Least-Privilege Security Group** model:

| Component | Security Group | Ingress Source | Allowed Port |
| :--- | :--- | :--- | :--- |
| **ALB** | `alb_sg` | Everywhere (0.0.0.0/0) | 80, 443 |
| **Frontend** | `frontend_sg` | `alb_sg` | 80 |
| **Gateway** | `gateway_sg` | `alb_sg` | 3000 |
| **Auth Service** | `auth_sg` | `gateway_sg` | 4000 |
| **User Service** | `user_sg` | `gateway_sg` | 4001 |
| **Payment Service** | `payment_sg` | `gateway_sg` | 4002 |
| **Other Backends** | `*_sg` | `gateway_sg` | 4003, 4004 |

> [!IMPORTANT]
> **No direct internet access**: Backend microservices have NO public IP addresses and cannot be reached directly from the internet. They ONLY accept traffic from the API Gateway.

---

## 4. Microservices Catalog

| Service | Port | Responsibilities |
| :--- | :--- | :--- |
| **Frontend** | 80 | User Interface (React/Next.js) |
| **API Gateway** | 3000 | Routing, Auth delegation, Load balancing across services |
| **Auth Service** | 4000 | User Authentication, JWT management, Registration |
| **User Service** | 4001 | Profile management and user metadata |
| **Payment Service** | 4002 | Transaction processing and banking gateway integration |
| **Notification** | 4003 | Email/SMS alerts and push notifications |
| **Transaction** | 4004 | Ledger management and transaction history (MongoDB) |

---

## 5. Deployment & CI/CD
*   **Docker Hub**: Images are stored in the `gitopssoftinator/finstack-*` repository.
*   **GitHub Actions**: Automates building and pushing images to Docker Hub.
*   **Terraform**: Manages all infrastructure as code (IaC), located in the `/infra` directory.
