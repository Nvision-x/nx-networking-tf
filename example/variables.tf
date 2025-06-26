variable "aws_region" {
  description = "The AWS region where the infrastructure will be deployed (e.g., us-east-2)"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC (e.g., 10.0.0.0/16)"
}

variable "vpc_name" {
  description = "The name to assign to the VPC and associated resources for tagging purposes"
}

variable "public_subnets" {
  description = "A map of public subnets with their CIDR blocks, availability zones, and names"
  type = map(object({
    cidr = string
    az   = string
    name = string
  }))
}

variable "private_subnets" {
  description = "A map of private subnets with their CIDR blocks, availability zones, and names"
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

variable "vpc_endpoint_subnet_ids" {
  description = "List of subnet IDs (one per AZ) to attach to the VPC Interface Endpoint"
  type        = list(string)
}

variable "enable_vpc_endpoints" {
  description = "Whether to create VPC interface endpoints"
  type        = bool
  default     = false
}

variable "vpc_interface_service_names" {
  description = "List of AWS service names for VPC interface endpoints (e.g., com.amazonaws.us-east-2.eks-auth)"
  type        = list(string)
}

variable "create_networking_resources" {
  description = "Whether to create VPC, subnets, IGW, NAT, etc."
  type        = bool
  default     = false
}


