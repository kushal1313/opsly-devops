# IAM Role Module

Terraform module for creating IAM roles with assume role policies and attached policies.

## Features

- Creates IAM roles with custom assume role policies
- Supports AWS managed policies and custom inline policies
- IRSA (IAM Roles for Service Accounts) support for EKS
- Configurable role name and description
- Tagging support

## Usage

### Standard IAM Role

```hcl
module "eks_cluster_role" {
  source = "./terraform-modules/iam-role"
  
  create_role = true
  role_name   = "my-eks-cluster-role"
  
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
      arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    }
  ]
  
  mandatory_tags = {
    TEAM        = "DevOps"
    DEPARTMENT  = "Engineering"
    OWNER       = "DevOps Team"
    FUNCTION    = "IAM"
    PRODUCT     = "AI Chatbot"
    ENVIRONMENT = "production"
  }
  
  region = "us-east-1"
}
```

### IRSA Role for EKS Service Account

```hcl
module "ebs_csi_irsa_role" {
  source = "./terraform-modules/iam-role"
  
  create_role = true
  role_name   = "ebs-csi-driver-role"
  
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
      arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
    }
  ]
  
  mandatory_tags = {
    TEAM        = "DevOps"
    DEPARTMENT  = "Engineering"
    OWNER       = "DevOps Team"
    FUNCTION    = "IAM"
    PRODUCT     = "AI Chatbot"
    ENVIRONMENT = "production"
  }
  
  region = "us-east-1"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| create_role | Controls if IAM role should be created | bool | true | no |
| role_name | Name of the IAM role | string | - | yes |
| assume_role_policy | JSON policy document for assume role policy | string | - | yes |
| aws_policy_arns | List of AWS managed policy ARNs to attach | list(object) | [] | no |
| inline_policies | List of inline policy documents | list(object) | [] | no |
| mandatory_tags | Mandatory tags for all resources | object | - | yes |
| custom_tags | Custom tags for all resources | map(string) | {} | no |
| region | AWS region | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| iam_role_arn | ARN of the IAM role |
| iam_role_name | Name of the IAM role |
| iam_role_id | ID of the IAM role |

## Prerequisites

- For IRSA roles, OIDC provider must be created for the EKS cluster
- AWS managed policies must exist (they are provided by AWS)

## Notes

- IRSA roles use `sts:AssumeRoleWithWebIdentity` for EKS service accounts
- Standard IAM roles use `sts:AssumeRole` for AWS services
- Inline policies are useful for custom permissions not covered by managed policies
- Role names must be unique within the AWS account
- IRSA is the recommended way to grant AWS permissions to Kubernetes service accounts

