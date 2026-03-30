resource "aws_security_group" "frontend_sg" {
	name = "frontend-sg"
	description = "Allow HTTP traffic"
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
