resource "aws_lb" "frontend_alb" {
	name = "frontend-alb"
	load_balancer_type = "application"
	subnets = [aws_subnet.public.id, aws_subnet.public_2.id]
	security_groups = [aws_security_group.alb_sg.id]
	tags = {
		Name = "finstack-alb"
	}
}

resource "aws_lb_target_group" "frontend_tg" {
	name = "frontend-tg"
	port = 80
	protocol = "HTTP"
	vpc_id = aws_vpc.main.id
	target_type = "ip"

	health_check {
		path = "/"
		healthy_threshold = 2
		unhealthy_threshold = 2
		timeout = 3
		interval = 30
		matcher = "200"
	}

	tags = {
		Name = "finstack-frontend-tg"
	}
}

resource "aws_lb_listener" "frontend_listener" {
	load_balancer_arn = aws_lb.frontend_alb.arn
	port = 80
	protocol = "HTTP"
	
	default_action {
		type = "forward"
		target_group_arn = aws_lb_target_group.frontend_tg.arn
	}
}
