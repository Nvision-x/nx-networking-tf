# variables.tf
variable "create_networking_resources" {
  description = "Whether to create VPC, subnets, IGW, NAT, etc."
  type        = bool
  default     = true
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "vpc_name" {
  description = "Name tag for the VPC"
  type        = string
}

variable "existing_vpc_id" {
  description = "ID of existing VPC"
  type        = string
  default     = ""
}

variable "public_subnets" {
  description = "Map of public subnets"
  type = map(object({
    cidr = string
    az   = string
    name = string
  }))
  default = {}
}

variable "private_subnets" {
  description = "Map of private subnets"
  type = map(object({
    cidr = string
    az   = string
    name = string
  }))
  default = {}
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "bastion_subnet_id" {
  description = "The subnet ID where the Bastion EC2 instance will be deployed"
  type        = string
}

