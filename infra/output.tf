# Outputs for accessing deployed resources

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

output "efs_csi_driver_role_arn" {
  description = "The ARN of the IAM role for the EFS CSI driver"
  value       = aws_iam_role.efs_csi_driver.arn
}

output "vpc_id" {
  description = "VPC ID needed for ALB Controller"
  value       = aws_vpc.main.id
}

output "lb_controller_role_arn" {
  description = "IAM Role ARN for AWS Load Balancer Controller"
  value       = aws_iam_role.lb_controller.arn
}

output "eks_cluster_ca_data" {
  description = "EKS Cluster CA Data for Helm Provider"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "eso_role_arn" {
  description = "IAM Role ARN for External Secrets Operator"
  value       = aws_iam_role.external_secrets.arn
}

output "node_group_name" {
  description = "Name of the EKS managed node group"
  value       = aws_eks_node_group.main.node_group_name
}

output "node_role_arn" {
  description = "IAM Role ARN for EKS worker nodes"
  value       = aws_iam_role.eks_nodes.arn
}
