# EKS Cluster Module

Terraform module for creating an Amazon EKS (Elastic Kubernetes Service) cluster.

## Features

- Creates EKS cluster with configurable Kubernetes version
- Configurable cluster endpoint access (private/public)
- Cluster logging configuration
- Cluster security group management
- OIDC issuer URL for IRSA integration
- Support for custom cluster security group rules

## Usage

```hcl
module "eks" {
  source = "./terraform-modules/eks"
  
  create                          = true
  cluster_name                    = "my-eks-cluster"
  cluster_version                 = "1.29"
  cluster_enabled_log_types       = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  cluster_role = module.eks_cluster_role.iam_role_arn
  
  create_cluster_security_group = true
  create_node_sg                = true
  
  mandatory_tags = {
    TEAM        = "DevOps"
    DEPARTMENT  = "Engineering"
    OWNER       = "DevOps Team"
    FUNCTION    = "Kubernetes"
    PRODUCT     = "AI Chatbot"
    ENVIRONMENT = "production"
  }
  
  region = "us-east-1"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| create | Controls if EKS resources should be created | bool | true | no |
| cluster_name | Name of the EKS cluster | string | - | yes |
| cluster_version | Kubernetes version for the EKS cluster | string | null | no |
| cluster_enabled_log_types | List of control plane logs to enable | list(string) | [] | no |
| cluster_endpoint_private_access | Indicates whether or not the Amazon EKS private API server endpoint is enabled | bool | false | no |
| cluster_endpoint_public_access | Indicates whether or not the Amazon EKS public API server endpoint is enabled | bool | true | no |
| vpc_id | ID of the VPC where the cluster and its nodes will be provisioned | string | - | yes |
| subnet_ids | List of subnet IDs where the EKS cluster endpoint will be accessible | list(string) | - | yes |
| cluster_role | IAM role ARN that is associated with the EKS cluster | string | - | yes |
| create_cluster_security_group | Determines if a security group is created for the cluster | bool | false | no |
| create_node_sg | Determines if a node security group is created | bool | false | no |
| mandatory_tags | Mandatory tags for all resources | object | - | yes |
| custom_tags | Custom tags for all resources | map(string) | {} | no |
| region | AWS region | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | EKS cluster ID |
| cluster_name | EKS cluster name |
| cluster_version | Kubernetes version of the EKS cluster |
| cluster_endpoint | Endpoint for EKS control plane |
| cluster_certificate_authority_data | Base64 encoded certificate data required to communicate with the cluster |
| cluster_oidc_issuer_url | The URL on the EKS cluster OIDC Issuer |
| cluster_security_group_id | Security group ID attached to the EKS cluster |

## Prerequisites

- VPC and subnets must exist before creating the EKS cluster
- IAM role for the EKS cluster must be created with appropriate permissions
- The IAM role must have the `AmazonEKSClusterPolicy` attached

## Notes

- Cluster creation takes approximately 10-15 minutes
- The cluster endpoint can be configured for private-only, public-only, or both
- Enable cluster logging for audit and troubleshooting purposes
- The OIDC issuer URL is required for IRSA (IAM Roles for Service Accounts) setup

