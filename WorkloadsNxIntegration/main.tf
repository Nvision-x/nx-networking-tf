module "nx-networking" {
  source = "./.."
  # source = "git::https://github.com/Nvision-x/nx-networking-tf.git"
  region                      = var.aws_region
  vpc_cidr                    = var.vpc_cidr
  vpc_name                    = var.vpc_name
  public_subnets              = var.public_subnets
  private_subnets             = var.private_subnets
  create_networking_resources = var.create_networking_resources

  existing_vpc_id             = var.existing_vpc_id
  vpc_endpoint_subnet_ids     = var.vpc_endpoint_subnet_ids
  vpc_interface_service_names = var.vpc_interface_service_names
  enable_vpc_endpoints        = var.enable_vpc_endpoints
  environment                 = "integration"

}

