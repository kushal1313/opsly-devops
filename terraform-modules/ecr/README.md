# ECR Repository Module

Terraform module for creating Amazon ECR (Elastic Container Registry) repositories.

## Features

- Creates ECR repositories for container images
- Configurable image tag mutability
- Lifecycle policies for image retention
- Image scanning configuration
- Encryption support
- Tagging support

## Usage

```hcl
module "ecr_backend" {
  source = "./terraform-modules/ecr"
  
  repository_name                 = "my-app-backend"
  repository_image_tag_mutability = "MUTABLE"
  
  mandatory_tags = {
    TEAM        = "DevOps"
    DEPARTMENT  = "Engineering"
    OWNER       = "DevOps Team"
    FUNCTION    = "Container Registry"
    PRODUCT     = "AI Chatbot"
    ENVIRONMENT = "production"
  }
  
  region = "us-east-1"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| repository_name | Name of the ECR repository | string | - | yes |
| repository_image_tag_mutability | Tag mutability setting for the repository (MUTABLE or IMMUTABLE) | string | "MUTABLE" | no |
| mandatory_tags | Mandatory tags for all resources | object | - | yes |
| custom_tags | Custom tags for all resources | map(string) | {} | no |
| region | AWS region | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| repository_url | URL of the ECR repository |
| repository_arn | ARN of the ECR repository |
| repository_name | Name of the ECR repository |

## Prerequisites

- Repository name must be unique within the AWS account and region
- Repository name must follow ECR naming conventions

## Notes

- **MUTABLE** tags can be overwritten (useful for `latest` tag)
- **IMMUTABLE** tags cannot be overwritten (better for production)
- ECR repositories are region-specific
- Use lifecycle policies to automatically clean up old images
- Image scanning can be enabled for security vulnerability detection
- ECR integrates with EKS for seamless container image deployment

## Example: Pushing Images

After creating the repository, push images using:

```bash
# Authenticate Docker to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

# Tag your image
docker tag my-app:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/my-app-backend:latest

# Push the image
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/my-app-backend:latest
```

