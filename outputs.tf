output "vpc_id" {
  description = "The ID of the VPC used or created for this environment"
  value       = local.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs created when create_networking_resources is true"
  value       = var.create_networking_resources ? [for s in aws_subnet.public : s.id] : []
}

output "private_subnet_ids" {
  description = "List of private subnet IDs created when create_networking_resources is true"
  value       = var.create_networking_resources ? [for s in aws_subnet.private : s.id] : []
}
