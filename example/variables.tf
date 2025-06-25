variable "aws_region" {}
variable "vpc_cidr" {}
variable "vpc_name" {}

variable "public_subnets" {
  type = map(object({
    cidr = string
    az   = string
    name = string
  }))
}

variable "private_subnets" {
  type = map(object({
    cidr = string
    az   = string
    name = string
  }))
}

variable "existing_vpc_id" {
  description = "ID of existing VPC"
  type        = string
  default     = ""
}

variable "bastion_subnet_id" {
  description = "The subnet ID where the Bastion EC2 instance will be deployed"
  type        = string
}

