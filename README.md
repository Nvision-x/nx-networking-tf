# AWS VPC and Subnet Module

This Terraform module provisions a complete **VPC networking layer** in AWS. It includes a VPC, public and private subnets across multiple availability zones, internet gateway, NAT gateways, and route tables — all configured with proper tagging and modular inputs.

The module is designed to provide a reusable, scalable, and production-ready network foundation for applications running in AWS.

## 🔧 Features

- Creates a **custom VPC** with user-defined CIDR
- Supports **multiple public and private subnets** with availability zone mapping
- Attaches an **internet gateway** for public subnet access
- Creates **Elastic IPs** and **NAT gateways** in public subnets for private subnet internet access
- Configures **route tables** and automatically associates them with subnets
- Outputs essential network IDs and NAT gateway public IPs for use in downstream modules

## 🚀 Use Cases

- Foundational network setup for EKS, ECS, RDS, or EC2 deployments
- Isolated public/private subnet architecture with internet/NAT routing
- Reusable network layer for staging, dev, or production environments

> This module follows AWS best practices for high availability and modular infrastructure design.

## Requirements

| Name      | Version   |
|-----------|-----------|
| Terraform | >= 1.0    |
| AWS CLI   | >= 2.0    |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_eip.nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_internet_gateway.igw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_nat_gateway.nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region where resources will be deployed | `string` | n/a | yes |
| <a name="input_private_subnets"></a> [private\_subnets](#input\_private\_subnets) | Map of private subnets with CIDR, Availability Zone, and name | <pre>map(object({<br/>    cidr = string<br/>    az   = string<br/>    name = string<br/>  }))</pre> | n/a | yes |
| <a name="input_public_subnets"></a> [public\_subnets](#input\_public\_subnets) | Map of public subnets with CIDR, Availability Zone, and name | <pre>map(object({<br/>    cidr = string<br/>    az   = string<br/>    name = string<br/>  }))</pre> | n/a | yes |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR block for the VPC | `string` | n/a | yes |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | Name tag for the VPC | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_nat_gateway_ips"></a> [nat\_gateway\_ips](#output\_nat\_gateway\_ips) | List of public IP addresses for the NAT Gateways |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | List of private subnet IDs |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | List of public subnet IDs |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The ID of the created VPC |
