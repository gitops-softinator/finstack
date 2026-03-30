resource "aws_vpc" "main" {
	cidr_block = "10.0.0.0/16"
}

# Public subnets for ALB
resource "aws_subnet" "public" {
	vpc_id = aws_vpc.main.id
	cidr_block = "10.0.1.0/24"
	availability_zone = "eu-north-1a"
	map_public_ip_on_launch = true
}

resource "aws_subnet" "public_2" {
	vpc_id = aws_vpc.main.id
	cidr_block = "10.0.2.0/24"
	availability_zone = "eu-north-1b"
	map_public_ip_on_launch = true
}

# Private subnets for ECS services
resource "aws_subnet" "private" {
	vpc_id = aws_vpc.main.id
	cidr_block = "10.0.10.0/24"
	availability_zone = "eu-north-1a"
	map_public_ip_on_launch = false
}

resource "aws_subnet" "private_2" {
	vpc_id = aws_vpc.main.id
	cidr_block = "10.0.11.0/24"
	availability_zone = "eu-north-1b"
	map_public_ip_on_launch = false
}

resource "aws_internet_gateway" "gw" {
	vpc_id = aws_vpc.main.id
}

# Route table for public subnets
resource "aws_route_table" "public_rt" {
	vpc_id = aws_vpc.main.id
}

resource "aws_route" "public_internet" {
	route_table_id = aws_route_table.public_rt.id
	destination_cidr_block = "0.0.0.0/0"
	gateway_id = aws_internet_gateway.gw.id
}

resource "aws_route_table_association" "public_assoc" {
	subnet_id = aws_subnet.public.id
	route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_assoc_2" {
	subnet_id = aws_subnet.public_2.id
	route_table_id = aws_route_table.public_rt.id
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
	domain = "vpc"
	depends_on = [aws_internet_gateway.gw]
	tags = {
		Name = "finstack-nat-eip"
	}
}

# NAT Gateway in public subnet for private subnet egress
resource "aws_nat_gateway" "nat" {
	allocation_id = aws_eip.nat.id
	subnet_id = aws_subnet.public.id
	depends_on = [aws_internet_gateway.gw]
	tags = {
		Name = "finstack-nat-gateway"
	}
}

# Route table for private subnets
resource "aws_route_table" "private_rt" {
	vpc_id = aws_vpc.main.id
}

resource "aws_route" "private_internet" {
	route_table_id = aws_route_table.private_rt.id
	destination_cidr_block = "0.0.0.0/0"
	nat_gateway_id = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_assoc" {
	subnet_id = aws_subnet.private.id
	route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_assoc_2" {
	subnet_id = aws_subnet.private_2.id
	route_table_id = aws_route_table.private_rt.id
}
