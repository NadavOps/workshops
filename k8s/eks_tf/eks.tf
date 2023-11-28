locals {
  initial_node_selectors = {
    workgroup = "k8s-demo"
  }
  taints = {
    0 = {
      key    = "k8s-demo"
      value  = null
      effect = "NO_SCHEDULE" #in k8s will be "NoSchedule", to support other effects require changes
    }
  }
  tolerations_format = [for taint_key, taint_value in local.taints : {
    key      = taint_value.key
    operator = taint_value.value == null ? "Exists" : "Equal"
    value    = taint_value.value != null ? taint_value.value : null
    effect   = taint_value.effect == "NO_SCHEDULE" ? "NoSchedule" : "ErrorCorrectSubtitution"
  }]

  irsa_oidc_provider_url = replace(module.eks.oidc_provider_arn, "/^(.*provider/)/", "")
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.20.0"

  cluster_name    = local.tags.Name
  cluster_version = "1.27"

  cluster_endpoint_public_access = true

  #cluster_enabled_log_types       = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  cluster_addons = {
    coredns = {
      most_recent = true
      timeouts = {
        create = "10m"
        delete = "10m"
      }
      configuration_values = jsonencode({
        nodeSelector = local.initial_node_selectors
        tolerations  = local.tolerations_format
      })
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.public_subnets
  control_plane_subnet_ids = module.vpc.public_subnets

  eks_managed_node_group_defaults = {
    instance_types = ["m6i.large", "m5.large", "m5n.large", "m5zn.large"]
  }

  create_cluster_security_group = true
  create_node_security_group    = true

  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "TCP open to internet"
      protocol    = "TCP"
      from_port   = 30000
      to_port     = 32767
      type        = "ingress"
      cidr_blocks = ["0.0.0.0/0"]
    }
    all_inside = {
      description = "TCP open to VPC"
      protocol    = "TCP"
      from_port   = 0
      to_port     = 65535
      type        = "ingress"
      cidr_blocks = [module.vpc.vpc_cidr_block]
    }
  }
  node_security_group_tags = { "karpenter.sh/discovery" = local.tags.Name }

  eks_managed_node_groups = {
    k8s-demo = {
      min_size     = 2
      max_size     = 10
      desired_size = 2

      instance_types = ["t3a.medium", "t3.medium"]
      capacity_type  = "SPOT"

      labels = local.initial_node_selectors
      taints = local.taints
    }
  }

  # aws-auth configmap
  manage_aws_auth_configmap = true

  ## Don't add the cluster creator here
  ## https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html#aws-auth-configmap, role maps need to be removed until AWS will fix it
  aws_auth_roles = [
    {
      rolearn  = module.karpenter.role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups = [
        "system:bootstrappers",
        "system:nodes",
      ]
    }
  ]

  tags = local.tags
}
