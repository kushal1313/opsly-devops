# S3 Bucket Module

Terraform module for creating and configuring Amazon S3 buckets.

## Features

- Creates S3 buckets with configurable settings
- Versioning support
- Server-side encryption configuration
- Lifecycle policies
- Bucket policies
- Public access block configuration
- ELB/ALB log delivery policy support

## Usage

```hcl
module "s3_chatbot_data" {
  source = "./terraform-modules/s3"
  
  create_bucket = true
  bucket_name   = "my-chatbot-data-bucket"
  
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
    TEAM        = "DevOps"
    DEPARTMENT  = "Engineering"
    OWNER       = "DevOps Team"
    FUNCTION    = "Storage"
    PRODUCT     = "AI Chatbot"
    ENVIRONMENT = "production"
  }
  
  region = "us-east-1"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| create_bucket | Controls if S3 bucket should be created | bool | true | no |
| bucket_name | Name of the S3 bucket | string | - | yes |
| versioning | Map containing versioning configuration | object | {} | no |
| server_side_encryption_configuration | Map containing server-side encryption configuration | object | {} | no |
| attach_elb_log_delivery_policy | Controls if ELB log delivery policy should be attached | bool | false | no |
| attach_lb_log_delivery_policy | Controls if ALB/NLB log delivery policy should be attached | bool | false | no |
| mandatory_tags | Mandatory tags for all resources | object | - | yes |
| custom_tags | Custom tags for all resources | map(string) | {} | no |
| region | AWS region | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| bucket_id | Name of the S3 bucket |
| bucket_arn | ARN of the S3 bucket |
| bucket_domain_name | Bucket domain name |

## Prerequisites

- Bucket name must be globally unique across all AWS accounts
- Bucket name must follow S3 naming conventions

## Notes

- S3 bucket names are globally unique
- Versioning helps protect against accidental deletion
- Server-side encryption is recommended for sensitive data
- Use lifecycle policies to manage object storage classes and deletion
- Public access should be blocked by default for security
- ELB/ALB log delivery policies enable automatic log delivery from load balancers

