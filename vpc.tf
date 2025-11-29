# Add this variable to control environment
data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}

locals {
  vpc_id              = var.create_networking_resources ? aws_vpc.main[0].id : var.existing_vpc_id
  is_prod             = var.environment == "prod"
  single_nat_key      = var.create_networking_resources && !local.is_prod ? keys(var.public_subnets)[0] : null
  nat_gateway_targets = local.is_prod ? var.public_subnets : tomap({ (local.single_nat_key) = var.public_subnets[local.single_nat_key] })
}

resource "aws_vpc" "main" {
  count                = var.create_networking_resources ? 1 : 0
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_internet_gateway" "igw" {
  count  = var.create_networking_resources ? 1 : 0
  vpc_id = aws_vpc.main[0].id
  tags = {
    Name = "${var.vpc_name}-igw"
  }
}

resource "aws_subnet" "public" {
  for_each                = var.create_networking_resources ? var.public_subnets : {}
  vpc_id                  = local.vpc_id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = {
    Name                     = each.value.name
    "kubernetes.io/role/elb" = 1
  }
}

resource "aws_subnet" "private" {
  for_each          = var.create_networking_resources ? var.private_subnets : {}
  vpc_id            = local.vpc_id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name                              = each.value.name
    "kubernetes.io/role/internal-elb" = 1
  }
}

resource "aws_eip" "nat" {
  for_each = var.create_networking_resources ? local.nat_gateway_targets : {}

  tags = {
    Name = "${var.vpc_name}-nat-eip-${each.key}"
  }
}

resource "aws_nat_gateway" "nat" {
  for_each      = var.create_networking_resources ? local.nat_gateway_targets : {}
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = {
    Name = "${each.value.name}-natgw"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "public" {
  count  = var.create_networking_resources ? 1 : 0
  vpc_id = local.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw[0].id
  }

  tags = {
    Name = "${var.vpc_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  for_each       = var.create_networking_resources ? var.public_subnets : {}
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table" "private" {
  for_each = var.create_networking_resources ? var.private_subnets : {}
  vpc_id   = local.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = local.is_prod ? aws_nat_gateway.nat[each.key].id : aws_nat_gateway.nat[local.single_nat_key].id
  }

  tags = {
    Name = "${each.value.name}-rt"
  }
}

resource "aws_route_table_association" "private" {
  for_each       = var.create_networking_resources ? var.private_subnets : {}
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_security_group" "eks_vpce_sg" {
  count  = var.enable_vpc_endpoints ? 1 : 0
  name   = "eks-vpc-endpoint-sg"
  vpc_id = local.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_endpoint" "interface_endpoints" {
  for_each            = var.enable_vpc_endpoints ? toset(var.vpc_interface_service_names) : []
  vpc_id              = local.vpc_id
  service_name        = each.value
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.vpc_endpoint_subnet_ids
  security_group_ids  = [aws_security_group.eks_vpce_sg[0].id]
  private_dns_enabled = true

  timeouts {
    create = "15m"
  }

  tags = {
    Name = "vpc-endpoint-${replace(each.value, ".", "-")}"
  }
}

# VPC Flow Logs - KMS Key for CloudWatch Log Group encryption
resource "aws_kms_key" "vpc_flow_logs" {
  count                   = var.enable_vpc_flow_logs && var.create_networking_resources ? 1 : 0
  description             = "KMS key for VPC Flow Logs CloudWatch Log Group encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${var.region}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/vpc-flow-logs/${var.vpc_name}"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.vpc_name}-flow-logs-kms"
  }
}

resource "aws_kms_alias" "vpc_flow_logs" {
  count         = var.enable_vpc_flow_logs && var.create_networking_resources ? 1 : 0
  name          = "alias/${var.vpc_name}-flow-logs"
  target_key_id = aws_kms_key.vpc_flow_logs[0].key_id
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  count             = var.enable_vpc_flow_logs && var.create_networking_resources ? 1 : 0
  name              = "/aws/vpc-flow-logs/${var.vpc_name}"
  retention_in_days = var.vpc_flow_logs_retention_days
  kms_key_id        = aws_kms_key.vpc_flow_logs[0].arn

  tags = {
    Name = "${var.vpc_name}-flow-logs"
  }
}

resource "aws_flow_log" "vpc" {
  count                = var.enable_vpc_flow_logs && var.create_networking_resources ? 1 : 0
  iam_role_arn         = var.vpc_flow_logs_role_arn
  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs[0].arn
  log_destination_type = "cloud-watch-logs"
  traffic_type         = "ALL"
  vpc_id               = local.vpc_id

  tags = {
    Name = "${var.vpc_name}-flow-log"
  }
}
