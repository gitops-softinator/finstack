resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "finstack.local"
  description = "Private DNS namespace for Finstack microservices"
  vpc         = aws_vpc.main.id
}
