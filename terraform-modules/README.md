# Terraform Modules

This directory contains reusable Terraform modules for AWS infrastructure components.

## Overview

These modules are designed to be reusable, configurable, and follow AWS best practices. Each module is self-contained and can be used independently or as part of a larger infrastructure deployment.

## Available Modules

### Networking

- **`aws-vpc/`** - VPC with public and private subnets, NAT gateways, internet gateway, and route tables

### Kubernetes

- **`eks/`** - Amazon EKS cluster with configurable logging and endpoint access
- **`eks-managed-nodegroup/`** - EKS managed node groups with auto-scaling
- **`eks-managed-addons/`** - EKS managed add-ons (CoreDNS, kube-proxy, VPC CNI, EBS CSI)

### IAM

- **`iam-role/`** - IAM roles with assume role policies and attached policies
- **`iam-policy/`** - IAM policies with custom JSON policies

### Storage

- **`s3/`** - S3 buckets with versioning, encryption, and lifecycle policies
- **`ecr/`** - ECR repositories for container images

### Compute & Caching

- **`elasticache/`** - ElastiCache clusters (Redis/Valkey) with subnet groups and security groups
- **`sqs/`** - SQS queues with configurable settings

## Module Structure

Each module follows a consistent structure:

```
module-name/
├── main.tf          # Resource definitions
├── variables.tf     # Input variables
├── outputs.tf       # Output values
├── providers.tf     # Provider configuration (if needed)
└── README.md        # Module-specific documentation
```

## Usage

### Example: Using the VPC Module

```hcl
module "vpc" {
  source = "./terraform-modules/aws-vpc"
  
  create_vpc          = true
  cidr                = "10.0.0.0/16"
  azs                 = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  Private_App_Subnets = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  
  enable_nat_gateway     = true
  one_nat_gateway_per_az = true
  
  mandatory_tags = {
    TEAM        = "DevOps"
    ENVIRONMENT = "production"
  }
}
```

### Example: Using the EKS Module

```hcl
module "eks" {
  source = "./terraform-modules/eks"
  
  create                          = true
  cluster_name                    = "my-cluster"
  cluster_version                 = "1.29"
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  cluster_role = module.eks_cluster_role.iam_role_arn
  
  mandatory_tags = {
    TEAM = "DevOps"
  }
}
```

## Module Features

### Common Features

- **Tagging**: All modules support mandatory and custom tags
- **Region Support**: Configurable AWS region
- **Conditional Creation**: Most resources can be conditionally created
- **Outputs**: Comprehensive outputs for integration with other modules

### Best Practices

- **Idempotency**: All modules are idempotent
- **Resource Naming**: Consistent naming conventions
- **Security**: Security best practices built-in
- **Documentation**: Each module has its own README

## Module Dependencies

Some modules have dependencies on others:

- `eks/` depends on `aws-vpc/` and `iam-role/`
- `eks-managed-nodegroup/` depends on `eks/` and `aws-vpc/`
- `eks-managed-addons/` depends on `eks/` and `iam-role/`
- `elasticache/` depends on `aws-vpc/`

## Contributing

When adding or modifying modules:

1. Follow the existing module structure
2. Include comprehensive variable descriptions
3. Add appropriate outputs
4. Update module README with usage examples
5. Test modules in isolation before integration

## Related Documentation

- [Root README](../README.md) - Overall project documentation
- [AWS Infrastructure README](../aws/README.md) - Main infrastructure configuration

