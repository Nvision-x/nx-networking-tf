variable "aws_region" {
  description = "The AWS region where resources will be deployed"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "vpc_name" {
  description = "Name tag for the VPC"
  type        = string
}

variable "public_subnets" {
  description = "Map of public subnets with CIDR, Availability Zone, and name"
  type = map(object({
    cidr = string
    az   = string
    name = string
  }))
}

variable "private_subnets" {
  description = "Map of private subnets with CIDR, Availability Zone, and name"
  type = map(object({
    cidr = string
    az   = string
    name = string
  }))
}
