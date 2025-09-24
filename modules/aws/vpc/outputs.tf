output "vpc_id" {
  description = "ID of the VPC"
  value       = var.create_vpc ? aws_vpc.main[0].id : var.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = var.create_vpc ? aws_vpc.main[0].cidr_block : (var.vpc_id != "" ? data.aws_vpc.existing[0].cidr_block : "")
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = var.create_vpc ? aws_subnet.private[*].id : var.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = var.create_vpc ? aws_subnet.public[*].id : var.public_subnet_ids
}

output "private_route_table_ids" {
  description = "IDs of the private route tables"
  value       = var.create_vpc ? aws_route_table.private[*].id : []
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = var.create_vpc && var.enable_public_subnets ? aws_route_table.public[0].id : null
}

output "internet_gateway_id" {
  description = "ID of the internet gateway"
  value       = var.create_vpc && var.enable_public_subnets ? aws_internet_gateway.main[0].id : null
}

output "nat_gateway_ids" {
  description = "IDs of the NAT gateways"
  value       = var.create_vpc ? aws_nat_gateway.main[*].id : []
}

output "vpc_endpoints_security_group_id" {
  description = "Security group ID for VPC endpoints"
  value       = var.create_vpc && var.enable_vpc_endpoints ? aws_security_group.vpc_endpoints[0].id : null
}

output "availability_zones" {
  description = "List of availability zones used"
  value       = var.create_vpc ? slice(data.aws_availability_zones.available.names, 0, var.availability_zones_count) : []
}

output "created_vpc" {
  description = "Whether a new VPC was created"
  value       = var.create_vpc
}