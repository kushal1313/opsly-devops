# AWS Infrastructure Configuration

This directory contains the main Terraform configuration files for deploying the AI Chatbot Framework infrastructure on AWS.

## Overview

The `aws/` directory includes:
- `main.tf` - Main infrastructure definitions and module calls
- `variables.tf` - Variable definitions and defaults
- `outputs.tf` - Output values for accessing created resources

## Purpose

This configuration orchestrates the creation of:
- VPC with public and private subnets
- EKS cluster with managed node groups
- EKS add-ons (CoreDNS, kube-proxy, VPC CNI, EBS CSI)
- IRSA roles for service accounts
- Supporting infrastructure (S3, ECR, ElastiCache, SQS)
- Helm charts for cluster management tools

## Usage

### Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform >= 1.0 installed
3. Appropriate IAM permissions for resource creation

### Configuration

1. Create a `terraform.tfvars` file with your configuration:

```hcl
aws_region = "us-east-1"
cluster_name = "ai-chatbot-eks"
cluster_version = "1.29"
vpc_cidr = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
```

2. Initialize Terraform:

```bash
terraform init
```

3. Review the deployment plan:

```bash
terraform plan
```

4. Deploy infrastructure (see root README for staged deployment approach):

```bash
terraform apply
```

### Key Modules Used

- `terraform-modules/aws-vpc` - VPC and networking
- `terraform-modules/eks` - EKS cluster
- `terraform-modules/eks-managed-nodegroup` - Node groups
- `terraform-modules/eks-managed-addons` - EKS add-ons
- `terraform-modules/iam-role` - IAM roles for IRSA
- `terraform-modules/s3` - S3 bucket
- `terraform-modules/ecr` - ECR repositories
- `terraform-modules/elasticache` - ElastiCache Redis
- `terraform-modules/sqs` - SQS queue

## Important Notes

- Resources must be deployed in stages due to dependencies (see root README)
- All resources are tagged with mandatory tags
- IRSA roles are configured for secure AWS API access
- Node groups are deployed in private subnets for security

## Outputs

After deployment, use `terraform output` to view:
- Cluster endpoint and certificate
- VPC and subnet IDs
- Node group information
- IRSA role ARNs
- S3 bucket name
- ECR repository URLs
- ElastiCache endpoint
- SQS queue URL

## Related Documentation

- [Root README](../README.md) - Overall project documentation
- [Terraform Modules README](../terraform-modules/README.md) - Module documentation

