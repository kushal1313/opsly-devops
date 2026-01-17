################################################################################
# Provider Configuration
################################################################################

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

################################################################################
# Data Sources
################################################################################

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

################################################################################
# VPC Module
################################################################################

module "vpc" {
  source              = "./terraform-modules/aws-vpc"
  create_vpc          = true
  cidr                = var.vpc_cidr
  azs                 = var.availability_zones
  region              = var.aws_region
  public_subnets      = [for k, v in var.availability_zones : cidrsubnet(var.vpc_cidr, 8, k)]
  Private_App_Subnets = [for k, v in var.availability_zones : cidrsubnet(var.vpc_cidr, 8, k + 10)]

  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true
  enable_dns_hostnames   = true
  enable_dns_support     = true
  public_associated_nat  = true

  mandatory_tags = var.mandatory_tags
  custom_tags    = var.custom_tags
}

################################################################################
# EKS Cluster IAM Role
################################################################################

module "eks_cluster_role" {
  source = "./terraform-modules/iam-role"

  create_role = true
  role_name   = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  aws_policy_arns = [
    {
      arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSClusterPolicy"
    }
  ]

  mandatory_tags = var.mandatory_tags
  custom_tags    = var.custom_tags
  region         = var.aws_region
}

################################################################################
# EKS Cluster
################################################################################

module "eks" {
  source = "./terraform-modules/eks"

  create                          = true
  cluster_name                    = var.cluster_name
  cluster_version                 = var.cluster_version
  cluster_enabled_log_types       = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  create_cluster_security_group = true
  create_node_sg                = true

  cluster_role = module.eks_cluster_role.iam_role_arn

  mandatory_tags = var.mandatory_tags
  custom_tags    = var.custom_tags
  region         = var.aws_region
}

################################################################################
# EKS Node Group - General Workloads
################################################################################

module "eks_node_group_general" {
  source = "./terraform-modules/eks-managed-nodegroup"

  name           = "${var.cluster_name}-general"
  cluster_name   = module.eks.cluster_name
  subnet_ids     = module.vpc.private_subnets
  instance_types = var.general_node_instance_types
  capacity_type  = "ON_DEMAND"

  min_size     = var.general_node_min_size
  max_size     = var.general_node_max_size
  desired_size = var.general_node_desired_size

  create_iam_role                 = true
  create_launch_template          = false
  create_separate_launch_template = false

  labels = {
    workload-type = "general"
  }

  mandatory_tags = var.mandatory_tags
  custom_tags    = var.custom_tags
  region         = var.aws_region
}

################################################################################
# EKS Node Group - ML Workloads
################################################################################

module "eks_node_group_ml" {
  source = "./terraform-modules/eks-managed-nodegroup"

  name           = "${var.cluster_name}-ml"
  cluster_name   = module.eks.cluster_name
  subnet_ids     = module.vpc.private_subnets
  instance_types = var.ml_node_instance_types
  capacity_type  = "ON_DEMAND"

  min_size     = var.ml_node_min_size
  max_size     = var.ml_node_max_size
  desired_size = var.ml_node_desired_size

  create_iam_role                 = true
  create_launch_template          = false
  create_separate_launch_template = false

  labels = {
    workload-type = "ml"
  }

  taints = [
    {
      key    = "workload-type"
      value  = "ml"
      effect = "NO_SCHEDULE"
    }
  ]

  mandatory_tags = var.mandatory_tags
  custom_tags    = var.custom_tags
  region         = var.aws_region
}

################################################################################
# EKS Add-ons
################################################################################

module "eks_addons" {
  source = "./terraform-modules/eks-managed-addons"

  create          = true
  cluster_name    = module.eks.cluster_name
  cluster_version = module.eks.cluster_version

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
    }
  }

  mandatory_tags = var.mandatory_tags
  custom_tags    = var.custom_tags
  region         = var.aws_region
}

################################################################################
# OIDC Provider for IRSA
################################################################################

data "tls_certificate" "eks" {
  url        = module.eks.cluster_oidc_issuer_url
  depends_on = [module.eks]
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = module.eks.cluster_oidc_issuer_url

  tags = merge(
    var.mandatory_tags,
    var.custom_tags,
    {
      Name = "${var.cluster_name}-oidc-provider"
    }
  )
}

################################################################################
# IRSA for EBS CSI Driver
################################################################################

module "ebs_csi_irsa_role" {
  source = "./terraform-modules/iam-role"

  create_role = true
  role_name   = "${var.cluster_name}-ebs-csi-driver"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  aws_policy_arns = [
    {
      arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
    }
  ]

  mandatory_tags = var.mandatory_tags
  custom_tags    = var.custom_tags
  region         = var.aws_region
}

################################################################################
# IRSA for Cluster Autoscaler
################################################################################

module "cluster_autoscaler_irsa_role" {
  source = "./terraform-modules/iam-role"

  create_role = true
  role_name   = "${var.cluster_name}-cluster-autoscaler"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:cluster-autoscaler"
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  inline_policies = [
    {
      name = "ClusterAutoscalerPolicy"
      json = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "autoscaling:DescribeAutoScalingGroups",
              "autoscaling:DescribeAutoScalingInstances",
              "autoscaling:DescribeLaunchConfigurations",
              "autoscaling:DescribeScalingActivities",
              "autoscaling:DescribeTags",
              "ec2:DescribeInstanceTypes",
              "ec2:DescribeLaunchTemplateVersions"
            ]
            Resource = "*"
          },
          {
            Effect = "Allow"
            Action = [
              "autoscaling:SetDesiredCapacity",
              "autoscaling:TerminateInstanceInAutoScalingGroup",
              "ec2:DescribeImages",
              "ec2:GetInstanceTypesFromInstanceRequirements",
              "eks:DescribeNodegroup"
            ]
            Resource = "*"
          }
        ]
      })
    }
  ]

  mandatory_tags = var.mandatory_tags
  custom_tags    = var.custom_tags
  region         = var.aws_region
}

################################################################################
# IRSA for AWS Load Balancer Controller
################################################################################

module "aws_lb_controller_irsa_role" {
  source = "./terraform-modules/iam-role"

  create_role = true
  role_name   = "${var.cluster_name}-aws-load-balancer-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  aws_policy_arns = [
    {
      arn = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:policy/${var.cluster_name}-AWSLoadBalancerControllerIAMPolicy"
    }
  ]

  mandatory_tags = var.mandatory_tags
  custom_tags    = var.custom_tags
  region         = var.aws_region
}

################################################################################
# IAM Policy for AWS Load Balancer Controller
################################################################################

module "aws_lb_controller_policy" {
  source = "./terraform-modules/iam-policy"

  name = "${var.cluster_name}-AWSLoadBalancerControllerIAMPolicy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:CreateServiceLinkedRole"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "iam:AWSServiceName" = "elasticloadbalancing.amazonaws.com"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeVpcs",
          "ec2:DescribeVpcPeeringConnections",
          "ec2:GetCoipPoolUsage",
          "ec2:DescribeVpcClassicLink",
          "ec2:DescribeVpcClassicLinkDnsSupport",
          "ec2:DescribeSubnets",
          "ec2:DescribeTags",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeRouteTables",
          "ec2:DescribeNetworkAcls",
          "ec2:DescribeManagedPrefixLists",
          "ec2:DescribePrefixLists",
          "ec2:DescribeSecurityGroupRules",
          "ec2:DescribeSpotInstanceRequests",
          "ec2:GetNetworkInsightsAccessScopeAnalysisFindings",
          "ec2:GetNetworkInsightsAccessScopeContent",
          "ec2:DescribeNetworkInsightsAccessScopes",
          "ec2:DescribeNetworkInsightsAccessScopeAnalyses",
          "ec2:DescribeNetworkInsightsPaths",
          "ec2:DescribeNetworkInsightsAnalyses",
          "ec2:DescribeTransitGatewayAttachments",
          "ec2:DescribeTransitGatewayConnectPeers",
          "ec2:DescribeTransitGatewayConnects",
          "ec2:DescribeTransitGatewayMulticastDomains",
          "ec2:DescribeTransitGatewayPeeringAttachments",
          "ec2:DescribeTransitGatewayRouteTables",
          "ec2:DescribeTransitGatewayVpcAttachments",
          "ec2:DescribeTransitGateways",
          "ec2:DescribeVpcEndpointServiceConfigurations",
          "ec2:DescribeVpcEndpointServices",
          "ec2:DescribeVpcEndpoints",
          "ec2:DescribeVpcPeeringConnections",
          "ec2:DescribeVpcs",
          "ec2:DescribeVpnConnections",
          "ec2:DescribeVpnGateways"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeListenerCertificates",
          "elasticloadbalancing:DescribeSSLPolicies",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:DescribeTags"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cognito-idp:DescribeUserPoolClient",
          "acm:ListCertificates",
          "acm:DescribeCertificate",
          "iam:ListServerCertificates",
          "iam:GetServerCertificate",
          "waf-regional:GetWebACL",
          "waf-regional:GetWebACLForResource",
          "waf-regional:AssociateWebACL",
          "waf-regional:DisassociateWebACL",
          "wafv2:GetWebACL",
          "wafv2:GetWebACLForResource",
          "wafv2:AssociateWebACL",
          "wafv2:DisassociateWebACL",
          "shield:GetSubscriptionState",
          "shield:DescribeProtection",
          "shield:CreateProtection",
          "shield:DeleteProtection"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateSecurityGroup"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateTags"
        ]
        Resource = "arn:${data.aws_partition.current.partition}:ec2:*:*:security-group/*"
        Condition = {
          StringEquals = {
            "ec2:CreateAction" = "CreateSecurityGroup"
          }
          Null = {
            "aws:RequestTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateTags",
          "ec2:DeleteTags"
        ]
        Resource = "arn:${data.aws_partition.current.partition}:ec2:*:*:security-group/*"
        Condition = {
          Null = {
            "aws:RequestTag/elbv2.k8s.aws/cluster"  = "true"
            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:DeleteSecurityGroup"
        ]
        Resource = "*"
        Condition = {
          Null = {
            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:CreateTargetGroup"
        ]
        Resource = "*"
        Condition = {
          Null = {
            "aws:RequestTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:CreateRule",
          "elasticloadbalancing:DeleteRule"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags"
        ]
        Resource = [
          "arn:${data.aws_partition.current.partition}:elasticloadbalancing:*:*:targetgroup/*/*",
          "arn:${data.aws_partition.current.partition}:elasticloadbalancing:*:*:loadbalancer/net/*/*",
          "arn:${data.aws_partition.current.partition}:elasticloadbalancing:*:*:loadbalancer/app/*/*"
        ]
        Condition = {
          Null = {
            "aws:RequestTag/elbv2.k8s.aws/cluster"  = "true"
            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags"
        ]
        Resource = [
          "arn:${data.aws_partition.current.partition}:elasticloadbalancing:*:*:listener/net/*/*/*",
          "arn:${data.aws_partition.current.partition}:elasticloadbalancing:*:*:listener/app/*/*/*",
          "arn:${data.aws_partition.current.partition}:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
          "arn:${data.aws_partition.current.partition}:elasticloadbalancing:*:*:listener-rule/app/*/*/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:SetIpAddressType",
          "elasticloadbalancing:SetSecurityGroups",
          "elasticloadbalancing:SetSubnets",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:ModifyTargetGroupAttributes",
          "elasticloadbalancing:DeleteTargetGroup"
        ]
        Resource = "*"
        Condition = {
          Null = {
            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:AddTags"
        ]
        Resource = [
          "arn:${data.aws_partition.current.partition}:elasticloadbalancing:*:*:targetgroup/*/*",
          "arn:${data.aws_partition.current.partition}:elasticloadbalancing:*:*:loadbalancer/net/*/*",
          "arn:${data.aws_partition.current.partition}:elasticloadbalancing:*:*:loadbalancer/app/*/*"
        ]
        Condition = {
          StringEquals = {
            "aws:RequestTag/elbv2.k8s.aws/cluster" = var.cluster_name
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets"
        ]
        Resource = "arn:${data.aws_partition.current.partition}:elasticloadbalancing:*:*:targetgroup/*/*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:SetWebAcl",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:AddListenerCertificates",
          "elasticloadbalancing:RemoveListenerCertificates",
          "elasticloadbalancing:ModifyRule"
        ]
        Resource = "*"
      }
    ]
  })
  description    = "iam policy for ALB created from terraform"
  mandatory_tags = var.mandatory_tags
  custom_tags    = var.custom_tags
  region         = var.aws_region
}

################################################################################
# Kubernetes Provider
################################################################################

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

################################################################################
# Supporting Infrastructure - S3 Buckets
################################################################################

module "s3_chatbot_data" {
  source = "./terraform-modules/s3"

  create_bucket = true
  bucket_name   = "${var.cluster_name}-chatbot-data-${data.aws_caller_identity.current.account_id}"

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  mandatory_tags = {
    TEAM        = var.mandatory_tags.TEAM
    DEPARTMENT  = var.mandatory_tags.DEPARTMENT
    OWNER       = var.mandatory_tags.OWNER
    FUNCTION    = var.mandatory_tags.FUNCTION
    PRODUCT     = var.mandatory_tags.PRODUCT
    ENVIRONMENT = var.mandatory_tags.ENVIRONMENT
  }
  custom_tags = merge(var.custom_tags, {
    Name = "${var.cluster_name}-chatbot-data"
  })
  region = var.aws_region
}

################################################################################
# ECR Repositories
################################################################################

module "ecr_backend" {
  source = "./terraform-modules/ecr"

  repository_name                 = "${var.cluster_name}-backend"
  repository_image_tag_mutability = "MUTABLE"

  mandatory_tags = {
    TEAM        = var.mandatory_tags.TEAM
    DEPARTMENT  = var.mandatory_tags.DEPARTMENT
    OWNER       = var.mandatory_tags.OWNER
    FUNCTION    = var.mandatory_tags.FUNCTION
    PRODUCT     = var.mandatory_tags.PRODUCT
    ENVIRONMENT = var.mandatory_tags.ENVIRONMENT
  }
  custom_tags = merge(var.custom_tags, {
    Name = "${var.cluster_name}-backend"
  })
  region = var.aws_region
}

module "ecr_frontend" {
  source = "./terraform-modules/ecr"

  repository_name                 = "${var.cluster_name}-frontend"
  repository_image_tag_mutability = "MUTABLE"

  mandatory_tags = {
    TEAM        = var.mandatory_tags.TEAM
    DEPARTMENT  = var.mandatory_tags.DEPARTMENT
    OWNER       = var.mandatory_tags.OWNER
    FUNCTION    = var.mandatory_tags.FUNCTION
    PRODUCT     = var.mandatory_tags.PRODUCT
    ENVIRONMENT = var.mandatory_tags.ENVIRONMENT
  }
  custom_tags = merge(var.custom_tags, {
    Name = "${var.cluster_name}-frontend"
  })
  region = var.aws_region
}

################################################################################
# ElastiCache Subnet Group
################################################################################

resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.cluster_name}-redis-subnet-group"
  subnet_ids = module.vpc.private_subnets

  tags = merge(
    var.mandatory_tags,
    var.custom_tags,
    {
      Name = "${var.cluster_name}-redis-subnet-group"
    }
  )
}

################################################################################
# Security Group for Redis
################################################################################

resource "aws_security_group" "redis" {
  name        = "${var.cluster_name}-redis-sg"
  description = "Security group for Redis ElastiCache"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Allow Redis access from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(
    var.mandatory_tags,
    var.custom_tags,
    {
      Name = "${var.cluster_name}-redis-sg"
    }
  )
}

################################################################################
# ElastiCache Redis
################################################################################

module "elasticache_redis" {
  source = "./terraform-modules/elasticache"

  create_cluster_without_replication = true
  cluster_id                         = "${var.cluster_name}-redis"
  engine                             = "redis"
  engine_version                     = "7.0"
  node_type                          = "cache.t3.medium"
  cluster_size                       = 1
  parameter_group_name               = "default.redis7"
  port                               = 6379
  subnet_group_name                  = aws_elasticache_subnet_group.redis.name
  security_group_ids                 = [aws_security_group.redis.id]
  availability_zones                 = var.availability_zones[0]
  vpc_id                             = module.vpc.vpc_id

  mandatory_tags = {
    TEAM        = var.mandatory_tags.TEAM
    DEPARTMENT  = var.mandatory_tags.DEPARTMENT
    OWNER       = var.mandatory_tags.OWNER
    FUNCTION    = var.mandatory_tags.FUNCTION
    PRODUCT     = var.mandatory_tags.PRODUCT
    ENVIRONMENT = var.mandatory_tags.ENVIRONMENT
  }
  custom_tags = merge(var.custom_tags, {
    Name = "${var.cluster_name}-redis"
  })
  region = var.aws_region
}

################################################################################
# SQS Queues
################################################################################

module "sqs_chatbot_queue" {
  source = "./terraform-modules/sqs"

  create = true
  name   = "${var.cluster_name}-chatbot-queue"

  mandatory_tags = {
    TEAM        = var.mandatory_tags.TEAM
    DEPARTMENT  = var.mandatory_tags.DEPARTMENT
    OWNER       = var.mandatory_tags.OWNER
    FUNCTION    = var.mandatory_tags.FUNCTION
    PRODUCT     = var.mandatory_tags.PRODUCT
    ENVIRONMENT = var.mandatory_tags.ENVIRONMENT
  }
  custom_tags = merge(var.custom_tags, {
    Name = "${var.cluster_name}-chatbot-queue"
  })
  region = var.aws_region
}

################################################################################
# Kubernetes Namespace for System Components
################################################################################

resource "kubernetes_namespace" "kube_system" {
  metadata {
    name = "kube-system"
  }
  depends_on = [module.eks]
}

################################################################################
# Cluster Autoscaler Helm Chart
################################################################################

resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = "9.29.0"
  namespace  = "kube-system"

  set {
    name  = "autoDiscovery.clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "aws.region"
    value = var.aws_region
  }

  set {
    name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.cluster_autoscaler_irsa_role.iam_role_arn
  }

  set {
    name  = "rbac.serviceAccount.name"
    value = "cluster-autoscaler"
  }

  set {
    name  = "extraArgs.scan-interval"
    value = "10s"
  }

  set {
    name  = "extraArgs.skip-nodes-with-local-storage"
    value = "false"
  }

  set {
    name  = "extraArgs.skip-nodes-with-system-pods"
    value = "false"
  }

  depends_on = [
    module.eks,
    module.cluster_autoscaler_irsa_role,
    kubernetes_namespace.kube_system
  ]
}

################################################################################
# AWS Load Balancer Controller Helm Chart
################################################################################

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.6.0"
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.aws_lb_controller_irsa_role.iam_role_arn
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "vpcId"
    value = module.vpc.vpc_id
  }

  depends_on = [
    module.eks,
    module.aws_lb_controller_irsa_role,
    module.aws_lb_controller_policy,
    kubernetes_namespace.kube_system
  ]
}

