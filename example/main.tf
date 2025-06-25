module "nx-networking" {
  source = "./.."
  # source = "git::https://github.com/Nvision-x/nx-networking-tf.git"
  region                      = var.aws_region
  vpc_cidr                    = var.vpc_cidr
  vpc_name                    = var.vpc_name
  public_subnets              = var.public_subnets
  private_subnets             = var.private_subnets
  create_networking_resources = false

  existing_vpc_id    = var.existing_vpc_id
  bastion_subnet_id  = var.bastion_subnet_id

}

