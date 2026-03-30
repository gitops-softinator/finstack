# ALB Security Group
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow inbound HTTP/HTTPS traffic from anywhere"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "finstack-alb-sg"
  }
}

# Frontend Security Group (Only from ALB)
resource "aws_security_group" "frontend_sg" {
  name        = "frontend-sg"
  description = "Allow port 80 from ALB only"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "finstack-frontend-sg"
  }
}

# Gateway Security Group (Only from ALB)
resource "aws_security_group" "gateway_sg" {
  name        = "gateway-sg"
  description = "Allow port 3000 from ALB only"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "finstack-gateway-sg"
  }
}

# Auth Service Security Group (Only from Gateway)
resource "aws_security_group" "auth_sg" {
  name        = "auth-sg"
  description = "Allow port 4000 from Gateway only"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 4000
    to_port         = 4000
    protocol        = "tcp"
    security_groups = [aws_security_group.gateway_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "finstack-auth-sg"
  }
}

# User Service Security Group (Only from Gateway)
resource "aws_security_group" "user_sg" {
  name        = "user-sg"
  description = "Allow port 4001 from Gateway only"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 4001
    to_port         = 4001
    protocol        = "tcp"
    security_groups = [aws_security_group.gateway_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "finstack-user-sg"
  }
}

# Payment Service Security Group (Only from Gateway)
resource "aws_security_group" "payment_sg" {
  name        = "payment-sg"
  description = "Allow port 4002 from Gateway only"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 4002
    to_port         = 4002
    protocol        = "tcp"
    security_groups = [aws_security_group.gateway_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "finstack-payment-sg"
  }
}

# Notification Service Security Group (Only from Gateway)
resource "aws_security_group" "notification_sg" {
  name        = "notification-sg"
  description = "Allow port 4003 from Gateway only"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 4003
    to_port         = 4003
    protocol        = "tcp"
    security_groups = [aws_security_group.gateway_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "finstack-notification-sg"
  }
}

# Transaction Service Security Group (Only from Gateway)
resource "aws_security_group" "transaction_sg" {
  name        = "transaction-sg"
  description = "Allow port 4004 from Gateway only"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 4004
    to_port         = 4004
    protocol        = "tcp"
    security_groups = [aws_security_group.gateway_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "finstack-transaction-sg"
  }
}
