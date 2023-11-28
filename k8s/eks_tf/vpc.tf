locals {
  tags = {
    Name = "demo-k8s"
  }

  azs = formatlist("${var.aws_provider_default_region}%s", ["b", "c"])
}

# https://github.com/terraform-aws-modules/terraform-aws-vpc/blob/master/examples/complete/main.tf
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = local.tags.Name
  cidr = "10.0.0.0/16"

  azs             = local.azs
  private_subnets = ["10.0.0.0/19", "10.0.32.0/19", "10.0.64.0/19"]
  public_subnets  = ["10.0.96.0/19", "10.0.128.0/19", "10.0.160.0/19"]

  map_public_ip_on_launch = true
  enable_dns_hostnames    = true
  enable_dns_support      = true

  enable_nat_gateway = false
  enable_vpn_gateway = false

  public_subnet_tags = {
    "Name"                   = "${local.tags.Name}-public"
    "kubernetes.io/role/elb" = 1
    "karpenter.sh/discovery" = local.tags.Name
  }

  private_subnet_tags = {
    "Name"                            = "${local.tags.Name}-private"
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = local.tags
}
