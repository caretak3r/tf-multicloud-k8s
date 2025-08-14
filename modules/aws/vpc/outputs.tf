output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_route_table_ids" {
  description = "IDs of the private route tables"
  value       = aws_route_table.private[*].id
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = var.enable_public_subnets ? aws_route_table.public[0].id : null
}

output "internet_gateway_id" {
  description = "ID of the internet gateway"
  value       = var.enable_public_subnets ? aws_internet_gateway.main[0].id : null
}

output "nat_gateway_ids" {
  description = "IDs of the NAT gateways"
  value       = aws_nat_gateway.main[*].id
}

output "vpc_endpoints_security_group_id" {
  description = "Security group ID for VPC endpoints"
  value       = var.enable_vpc_endpoints ? aws_security_group.vpc_endpoints[0].id : null
}

output "availability_zones" {
  description = "List of availability zones used"
  value       = slice(data.aws_availability_zones.available.names, 0, var.availability_zones_count)
}