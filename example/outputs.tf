output "vpc_id" {
  description = "VPC ID from the network module"
  value       = module.nx-networking.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs from the network module"
  value       = module.nx-networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs from the network module"
  value       = module.nx-networking.private_subnet_ids
}

output "nat_gateway_ips" {
  description = "NAT Gateway public IPs from the network module"
  value       = module.nx-networking.nat_gateway_ips
}

