resource "aws_ecs_cluster" "main" {
	name = "finstack-cluster"

	tags = {
		Name = "finstack-cluster"
	}
}

# ECS Service for Frontend in Private Subnets
resource "aws_ecs_service" "frontend" {
	name = "frontend-service"
	cluster = aws_ecs_cluster.main.id
	task_definition = aws_ecs_task_definition.frontend.arn
	desired_count = 2
	launch_type = "FARGATE"

	network_configuration {
		subnets = [aws_subnet.private.id, aws_subnet.private_2.id]
		security_groups = [aws_security_group.frontend_sg.id]
		assign_public_ip = false
	}

	load_balancer {
		target_group_arn = aws_lb_target_group.frontend_tg.arn
		container_name = "frontend"
		container_port = 80
	}

	tags = {
		Name = "finstack-frontend-service"
	}

	depends_on = [
		aws_lb_listener.frontend_listener
	]
}
