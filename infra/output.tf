# Outputs for accessing deployed resources
output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.frontend_alb.dns_name
}

output "alb_arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.frontend_alb.arn
}

output "nat_gateway_ip" {
  description = "Elastic IP of NAT Gateway for private subnet egress"
  value       = aws_eip.nat.public_ip
}

output "eks_cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  description = "The endpoint for the EKS cluster"
  value       = aws_eks_cluster.main.endpoint
}
