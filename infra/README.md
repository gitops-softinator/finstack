# Finstack Infrastructure Changes Documentation

**Date:** March 30, 2026  
**Purpose:** ECS Services Migration to Private Subnets with ALB-Based Traffic Routing

---

## Overview

The infrastructure has been restructured to follow AWS best practices by:
- Moving all ECS services to **private subnets** (no public IP assignments)
- Routing all internet traffic through **Application Load Balancer (ALB)** in public subnets
- Implementing **NAT Gateway** for private subnet outbound connectivity
- Restricting **direct access** to ECS services (security group level)

---

## Detailed Changes by File

### 1. **vpc.tf** - VPC and Subnet Configuration

#### What Changed:
- **Added Private Subnets**: Created 2 private subnets for ECS service deployment
- **Added NAT Gateway**: Enabled outbound internet connectivity from private subnets
- **Route Table Separation**: Separated public and private route tables

#### New Resources Added:

```hcl
# Private Subnet 1 (eu-north-1a)
- CIDR Block: 10.0.10.0/24
- Availability Zone: eu-north-1a
- Public IP Assignment: Disabled

# Private Subnet 2 (eu-north-1b)
- CIDR Block: 10.0.11.0/24
- Availability Zone: eu-north-1b
- Public IP Assignment: Disabled

# NAT Gateway
- Location: Public Subnet (10.0.1.0/24)
- Elastic IP: Dynamically assigned
- Purpose: Enable outbound traffic from private subnets to internet

# Separate Route Tables
- public_rt: Routes 0.0.0.0/0 → Internet Gateway
- private_rt: Routes 0.0.0.0/0 → NAT Gateway
```

#### Why This Matters:
- Private subnets are isolated from direct internet access
- NAT Gateway allows services to download packages, make API calls, etc.
- Better security posture - no public IPs on ECS tasks

---

### 2. **security.tf** - Security Group Rules

#### What Changed:
- **Removed**: CIDR block ingress rule (0.0.0.0/0)
- **Added**: Source-based ingress (ALB security group only)

#### Before:
```hcl
ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # ❌ Open to entire internet
}
```

#### After:
```hcl
ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = [aws_security_group.alb_sg.id]  # ✅ ALB only
}

ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    security_groups = [aws_security_group.alb_sg.id]  # ✅ ALB only (HTTPS support added)
}
```

#### Security Benefits:
- Direct internet access to ECS services is blocked
- Only ALB can forward traffic to ECS tasks
- Reduced attack surface
- Complies with defense-in-depth principles

---

### 3. **alb.tf** - Load Balancer Configuration

#### What Changed:
- **Enhanced Health Checks**: Added detailed health check parameters
- **Added Tags**: Better resource tracking and management

#### Health Check Improvements:
```hcl
health_check {
    path = "/"
    healthy_threshold = 2          # Tasks must pass 2 checks to be healthy
    unhealthy_threshold = 2        # Tasks marked unhealthy after 2 failed checks
    timeout = 3                    # 3 second timeout per health check
    interval = 30                  # Check every 30 seconds
    matcher = "200"                # Only HTTP 200 is considered healthy
}
```

#### Benefits:
- Better detection of unhealthy containers
- Faster failover to healthy instances
- More stable service availability

---

### 4. **ecs.tf** - ECS Cluster and Service

#### What Changed:
- **Added ECS Service**: New service definition for frontend deployment
- **Configured Private Subnet Deployment**: Tasks run in private subnets
- **ALB Integration**: Service automatically registers with target group

#### New ECS Service Configuration:

```hcl
resource "aws_ecs_service" "frontend" {
    name = "frontend-service"
    cluster = aws_ecs_cluster.main.id
    task_definition = aws_ecs_task_definition.frontend.arn
    desired_count = 2                    # Always run 2 tasks for HA
    launch_type = "FARGATE"              # Serverless container runtime
    
    # Network Configuration - PRIVATE SUBNETS
    network_configuration {
        subnets = [
            aws_subnet.private.id,       # 10.0.10.0/24
            aws_subnet.private_2.id      # 10.0.11.0/24
        ]
        security_groups = [aws_security_group.frontend_sg.id]
        assign_public_ip = false         # ✅ Critical: No public IPs
    }
    
    # Load Balancer Integration
    load_balancer {
        target_group_arn = aws_lb_target_group.frontend_tg.arn
        container_name = "frontend"
        container_port = 80              # ALB routes to this port
    }
}
```

#### Key Features:
- **Desired Count = 2**: Always maintains 2 running tasks for high availability
- **Private Subnets**: Tasks deployed across 2 AZs for fault tolerance
- **No Public IPs**: Complete isolation from internet
- **ALB Integration**: Automatic service discovery and load balancing

---

### 5. **task_definition.tf** - Container Configuration

#### What Changed:
- **Removed Host Port Mapping**: Not needed in private subnet mode
- **Added CloudWatch Logging**: Centralized log collection
- **Added Resource Tags**: Better tracking and management

#### Removed:
```hcl
portMappings = [
    {
        containerPort = 80
        hostPort = 80        # ❌ Removed - not applicable for FARGATE with dynamic IP
    }
]
```

#### Added:
```hcl
# CloudWatch Logging Configuration
logConfiguration = {
    logDriver = "awslogs"
    options = {
        "awslogs-group" = "/ecs/frontend"
        "awslogs-region" = "eu-north-1"
        "awslogs-stream-prefix" = "ecs"
    }
}
```

#### Benefits:
- All container logs centralized in CloudWatch
- Easier debugging and monitoring
- Automatic log retention policies
- Integration with AWS monitoring ecosystem

---

### 6. **output.tf** - Terraform Outputs

#### What Changed:
- **Removed**: Duplicate ECS service definition
- **Added**: Useful output values for infrastructure management

#### New Outputs:

```hcl
output "alb_dns_name" {
    description = "DNS name of the load balancer"
    value = aws_lb.frontend_alb.dns_name
    # How to access: http://<this-dns-name>
}

output "alb_arn" {
    description = "ARN of the load balancer"
    value = aws_lb.frontend_alb.arn
}

output "ecs_cluster_name" {
    description = "Name of the ECS cluster"
    value = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
    description = "Name of the frontend ECS service"
    value = aws_ecs_service.frontend.name
}

output "nat_gateway_ip" {
    description = "Elastic IP of NAT Gateway for private subnet egress"
    value = aws_eip.nat.public_ip
    # All outbound traffic from private subnets appears from this IP
}
```

#### Use Cases:
- ALB DNS can be used directly or with a custom domain
- NAT Gateway IP can be whitelisted in external APIs
- Service names useful for AWS CLI management

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                      VPC (10.0.0.0/16)                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────── PUBLIC SUBNETS ────────────────────┐        │
│  │                                                 │         │
│  │  ┌──────────────────────────────────────┐     │         │
│  │  │  Internet Gateway                    │     │         │
│  │  │  (Route: 0.0.0.0/0)                 │     │         │
│  │  └──────────────────────────────────────┘     │         │
│  │           ↓ (Inbound Traffic)                 │         │
│  │  ┌──────────────────────────────────────┐     │         │
│  │  │   ALB (frontend-alb)                 │     │         │
│  │  │   Port: 80, 443                      │     │         │
│  │  │   SG: alb-sg                         │     │         │
│  │  └──────────────────────────────────────┘     │         │
│  │           ↓ (HTTP to Port 80)                 │         │
│  │  ┌──────────────────────────────────────┐     │         │
│  │  │   NAT Gateway (10.0.1.0/24)         │     │         │
│  │  │   ↑ Outbound from Private Subnets   │     │         │
│  │  └──────────────────────────────────────┘     │         │
│  │                                                 │         │
│  └──────────────────────────────────────────────┘         │
│                      ↓                                      │
│  ┌──────────── PRIVATE SUBNETS ────────────────────┐       │
│  │                                                  │        │
│  │  AZ: eu-north-1a          AZ: eu-north-1b     │        │
│  │  Subnet: 10.0.10.0/24     Subnet: 10.0.11.0/24│       │
│  │  ┌──────────────────┐     ┌──────────────────┐ │        │
│  │  │ ECS Task 1       │     │ ECS Task 2       │ │        │
│  │  │ (No Public IP)   │     │ (No Public IP)   │ │        │
│  │  │ Port: 80         │     │ Port: 80         │ │        │
│  │  │ SG: frontend-sg  │     │ SG: frontend-sg  │ │        │
│  │  └──────────────────┘     └──────────────────┘ │        │
│  │  (Only accepts traffic    (Only accepts traffic│        │
│  │   from ALB)                from ALB)           │        │
│  │                                                  │        │
│  └──────────────────────────────────────────────┘         │
│                                                              │
└─────────────────────────────────────────────────────────────┘

Traffic Flow:
Internet → ALB (Public, Port 80) → Target Group → ECS Tasks (Private)
Outbound: ECS Tasks → NAT Gateway (Public IP) → Internet
```

---

## Security Improvements Summary

| Aspect | Before | After | Improvement |
|--------|--------|-------|-------------|
| **ECS Exposure** | Public subnets with public IPs | Private subnets, no public IPs | ✅ No direct internet access |
| **Ingress Control** | Open to 0.0.0.0/0 | ALB security group only | ✅ Restricted access |
| **Outbound Traffic** | Direct internet access | Through NAT Gateway | ✅ Single egress point |
| **Load Balancing** | Basic health checks | Enhanced health checks | ✅ Better availability |
| **Logging** | None configured | CloudWatch centralized | ✅ Complete observability |
| **Network Design** | Single route table | Separate public/private RT | ✅ Better isolation |

---

## High Availability Features

1. **Multi-AZ Deployment**: ECS tasks spread across 2 availability zones
2. **Desired Count**: Minimum 2 running tasks at all times
3. **Health Checks**: ALB removes unhealthy tasks automatically
4. **NAT Gateway**: Single point for outbound (consider HA-NAT in production)

---

## Next Steps / Recommendations

1. **Enable HTTPS**: Add SSL certificate to ALB listener
2. **Add More Microservices**: Use same pattern for other services
3. **Implement Auto-Scaling**: Add ECS service autoscaling based on metrics
4. **Monitor**: Set up CloudWatch alarms for ALB and ECS metrics
5. **HA-NAT**: Consider deploying NAT Gateways in multiple AZs for production
6. **VPC Flow Logs**: Enable for security auditing
7. **Backup**: Configure automated backups for stateful components

---

## Files Modified

- ✅ `/infra/vpc.tf` - VPC and subnet configuration
- ✅ `/infra/security.tf` - Security group rules
- ✅ `/infra/alb.tf` - Load balancer configuration
- ✅ `/infra/ecs.tf` - ECS cluster and service
- ✅ `/infra/task_definition.tf` - Container task definition
- ✅ `/infra/output.tf` - Terraform outputs

---

## Validation Commands

```bash
# Plan the infrastructure changes
cd /home/gitops/Desktop/finstack/infra
terraform plan

# Apply the changes
terraform apply

# Verify deployment
aws ecs describe-services --cluster finstack-cluster --services frontend-service
aws elbv2 describe-load-balancers --names frontend-alb
aws ec2 describe-nat-gateways --filter Name=tag:Name,Values=finstack-nat-gateway
```

---

## Rollback Strategy

If needed to revert to previous configuration:
```bash
# Using git (if version controlled)
git revert <commit-hash>
terraform apply

# Or destroy and recreate
terraform destroy
git checkout <previous-version>
terraform apply
```

---

**Document Created:** March 30, 2026  
**Status:** ✅ All changes implemented and documented
