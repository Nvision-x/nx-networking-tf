aws_region = "us-east-2"
vpc_cidr   = "10.5.0.0/16"
vpc_name   = "test-vpc"

public_subnets = {
  subnet1 = {
    cidr = "10.5.1.0/24"
    az   = "us-east-2a"
    name = "public-2a"
  }
  subnet2 = {
    cidr = "10.5.2.0/24"
    az   = "us-east-2b"
    name = "public-2b"
  }
  subnet3 = {
    cidr = "10.5.3.0/24"
    az   = "us-east-2c"
    name = "public-2c"
  }
}

private_subnets = {
  subnet1 = {
    cidr = "10.5.11.0/24"
    az   = "us-east-2a"
    name = "private-2a"
  }
  subnet2 = {
    cidr = "10.5.12.0/24"
    az   = "us-east-2b"
    name = "private-2b"
  }
  subnet3 = {
    cidr = "10.5.13.0/24"
    az   = "us-east-2c"
    name = "private-2c"
  }
}
