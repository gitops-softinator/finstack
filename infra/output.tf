# Outputs for accessing deployed resources
output "alb_dns_name" {
	description = "DNS name of the load balancer"
	value = aws_lb.frontend_alb.dns_name
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
}
