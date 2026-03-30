resource "aws_security_group" "alb_sg" {
	name = "alb-sg"
	vpc_id = aws_vpc.main.id

	ingress {
		from_port = 80
		to_port = 80
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
}

resource "aws_lb" "frontend_alb" {
	name = "frontend-alb"
	load_balancer_type = "application"
	subnets = [aws_subnet.public.id, aws_subnet.public_2.id]
	security_groups = [aws_security_group.alb_sg.id]
}

resource "aws_lb_target_group" "frontend_tg" {
	name = "frontend-tg"
	port = 80
	protocol = "HTTP"
	vpc_id = aws_vpc.main.id
	target_type = "ip"

	health_check {
		path = "/"
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
