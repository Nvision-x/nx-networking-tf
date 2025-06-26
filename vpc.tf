locals {
  vpc_id = var.create_networking_resources ? aws_vpc.main[0].id : var.existing_vpc_id
}

resource "aws_vpc" "main" {
  count      = var.create_networking_resources ? 1 : 0
  cidr_block = var.vpc_cidr
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
    Name = each.value.name
  }
}

resource "aws_subnet" "private" {
  for_each          = var.create_networking_resources ? var.private_subnets : {}
  vpc_id            = local.vpc_id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name = each.value.name
  }
}

resource "aws_eip" "nat" {
  for_each = var.create_networking_resources ? aws_subnet.public : {}
}

resource "aws_nat_gateway" "nat" {
  for_each      = var.create_networking_resources ? aws_subnet.public : {}
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = each.value.id

  tags = {
    Name = "${each.value.tags["Name"]}-natgw"
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
  for_each       = var.create_networking_resources ? aws_subnet.public : {}
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table" "private" {
  for_each = var.create_networking_resources ? aws_subnet.private : {}
  vpc_id   = local.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[each.key].id
  }

  tags = {
    Name = "${each.value.tags["Name"]}-rt"
  }
}

resource "aws_route_table_association" "private" {
  for_each       = var.create_networking_resources ? aws_subnet.private : {}
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

# VPC Endpoints & SG
resource "aws_security_group" "eks_vpce_sg" {
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
  security_group_ids  = [aws_security_group.eks_vpce_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "vpc-endpoint-${replace(each.value, ".", "-")}"
  }
}



