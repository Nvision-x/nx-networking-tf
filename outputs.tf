output "vpc_id" {
  value = local.vpc_id
}

output "public_subnet_ids" {
  value = var.create_networking_resources ? [for s in aws_subnet.public : s.id] : []
}

output "private_subnet_ids" {
  value = var.create_networking_resources ? [for s in aws_subnet.private : s.id] : []
}

