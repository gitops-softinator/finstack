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
