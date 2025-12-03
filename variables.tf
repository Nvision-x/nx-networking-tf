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

variable "vpc_endpoint_subnet_ids" {
  description = "List of subnet IDs (one per AZ) to attach to the VPC Interface Endpoint"
  type        = list(string)
  default     = []
}

variable "enable_vpc_endpoints" {
  description = "Whether to create VPC interface endpoints"
  type        = bool
  default     = true
}

variable "vpc_interface_service_names" {
  description = "List of AWS service names for VPC interface endpoints (e.g., com.amazonaws.us-east-2.eks-auth)"
  type        = list(string)
  default     = []
}

variable "environment" {
  description = "Environment name like prod/staging/dev"
  type        = string
}

variable "enable_vpc_flow_logs" {
  description = "Whether to enable VPC flow logs"
  type        = bool
  default     = true
}

variable "vpc_flow_logs_retention_days" {
  description = "Number of days to retain VPC flow logs in CloudWatch"
  type        = number
  default     = 30
}

variable "vpc_flow_logs_role_arn" {
  description = "IAM Role ARN for VPC flow logs (created in nx-iam-tf module)"
  type        = string
  default     = ""
}





