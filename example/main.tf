module "nx-networking" {
  source = "./.."
  # source = "git::https://github.com/Nvision-x/nx-networking-tf.git"
  aws_region      = var.aws_region
  vpc_cidr        = var.vpc_cidr
  vpc_name        = var.vpc_name
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
}

