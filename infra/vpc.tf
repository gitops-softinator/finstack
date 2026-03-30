resource "aws_vpc" "main" {
	cidr_block = "10.0.0.0/16"
}

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

resource "aws_internet_gateway" "gw" {
	vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "rt" {
	vpc_id = aws_vpc.main.id
}

resource "aws_route" "internet" {
	route_table_id = aws_route_table.rt.id
	destination_cidr_block = "0.0.0.0/0"
	gateway_id = aws_internet_gateway.gw.id
}

resource "aws_route_table_association" "public_assoc" {
	subnet_id = aws_subnet.public.id
	route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "public_assoc_2" {
	subnet_id = aws_subnet.public_2.id
	route_table_id = aws_route_table.rt.id
}
