resource "aws_lb_target_group" "gateway_tg" {
  name        = "gateway-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/healthz"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Name = "finstack-gateway-tg"
  }
}

resource "aws_lb_listener_rule" "gateway_rule" {
  listener_arn = aws_lb_listener.frontend_listener.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gateway_tg.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

resource "aws_ecs_task_definition" "gateway" {
  family                   = "gateway"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name  = "gateway"
      image = "gitopssoftinator/finstack-gateway:latest"

      portMappings = [
        {
          containerPort = 3000
        }
      ]

      environment = [
        {
          name  = "AUTH_SERVICE_URL"
          value = "http://auth-service.finstack.local:4000"
        },
        {
          name  = "USER_SERVICE_URL"
          value = "http://user-service.finstack.local:4001"
        },
        {
          name  = "PAYMENT_SERVICE_URL"
          value = "http://payment-service.finstack.local:4002"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/gateway"
          "awslogs-region"        = "eu-north-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "finstack-gateway-task"
  }
}

resource "aws_ecs_service" "gateway" {
  name            = "gateway-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.gateway.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.private.id, aws_subnet.private_2.id]
    security_groups = [aws_security_group.gateway_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.gateway_tg.arn
    container_name   = "gateway"
    container_port   = 3000
  }

  tags = {
    Name = "finstack-gateway-service"
  }

  depends_on = [aws_lb_listener.frontend_listener]
}
