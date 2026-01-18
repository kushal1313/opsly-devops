# IAM Policy Module

Terraform module for creating IAM policies with custom JSON policy documents.

## Features

- Creates IAM policies with custom JSON policy documents
- Configurable policy name and description
- Tagging support
- Useful for creating policies that will be attached to multiple roles

## Usage

```hcl
module "aws_lb_controller_policy" {
  source = "./terraform-modules/iam-policy"
  
  name = "AWSLoadBalancerControllerIAMPolicy"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeAvailabilityZones",
          # ... more actions
        ]
        Resource = "*"
      }
    ]
  })
  
  description = "IAM policy for AWS Load Balancer Controller"
  
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
| name | Name of the IAM policy | string | - | yes |
| policy | JSON policy document | string | - | yes |
| description | Description of the IAM policy | string | "" | no |
| mandatory_tags | Mandatory tags for all resources | object | - | yes |
| custom_tags | Custom tags for all resources | map(string) | {} | no |
| region | AWS region | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| policy_arn | ARN of the IAM policy |
| policy_id | ID of the IAM policy |
| policy_name | Name of the IAM policy |

## Prerequisites

- Policy JSON must be valid IAM policy format
- Policy name must be unique within the AWS account

## Notes

- Policies created by this module can be attached to multiple IAM roles
- Use this module when you need to create a policy that will be reused across multiple roles
- Policy JSON must follow AWS IAM policy syntax
- Policy size is limited to 6,144 characters
- Policies are versioned by AWS automatically

