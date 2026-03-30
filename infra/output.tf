resource "aws_ecs_service" "frontend" {
	name = "frontend"
	cluster = aws_ecs_cluster.main.id
	task_definition = aws_ecs_task_definition.frontend.arn
	launch_type = "FARGATE"

	desired_count = 1

	network_configuration {
		subnets = [aws_subnet.public.id]
		assign_public_ip = true
		security_groups = [aws_security_group.frontend_sg.id]
	}

	load_balancer {
		target_group_arn = aws_lb_target_group.frontend_tg.arn
		container_name = "frontend"
		container_port = 80
	}

	depends_on = [aws_lb_listener.frontend_listener]
}
