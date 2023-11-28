terraform {
  required_version = "= 1.5.6"

  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
  }
}

provider "aws" {
  region  = var.aws_provider_default_region
  profile = var.aws_provider_profile
  default_tags {
    tags = local.tags
  }
}

provider "kubernetes" {
  ## without this black EKS module will not succeed on the auth config modifications
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--profile", var.aws_provider_profile]
    command     = "aws"
  }
}

# data "aws_ecrpublic_authorization_token" "token" {
#   provider = aws.virginia
# }

provider "helm" {
  # registry {
  #   url      = "oci://public.ecr.aws"
  #   username = data.aws_ecrpublic_authorization_token.token.user_name
  #   password = data.aws_ecrpublic_authorization_token.token.password
  # }

  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--profile", var.aws_provider_profile]
    }
    # token                  = module.eks.aws_eks_cluster_auth.cluster.token
  }
}

provider "kubectl" {
  apply_retry_count      = 3
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--profile", var.aws_provider_profile]
  }
}
