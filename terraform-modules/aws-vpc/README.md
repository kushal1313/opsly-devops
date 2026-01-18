# AWS VPC Module

Terraform module for creating a comprehensive VPC with public and private subnets, NAT gateways, internet gateway, and route tables.

## Features

- Creates VPC with configurable CIDR block
- Public and private subnets across multiple Availability Zones
- Internet Gateway for public subnet internet access
- NAT Gateways for private subnet egress (configurable: single or per-AZ)
- Route tables for public and private subnets
- VPC endpoints (optional, e.g., S3)
- DNS support configuration
- IPv6 support (optional)

## Usage

```hcl
module "vpc" {
  source = "./terraform-modules/aws-vpc"
  
  create_vpc          = true
  cidr                = "10.0.0.0/16"
  azs                 = ["us-east-1a", "us-east-1b", "us-east-1c"]
  region              = "us-east-1"
  public_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  Private_App_Subnets = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  
  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true
  
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  mandatory_tags = {
    TEAM        = "DevOps"
    DEPARTMENT  = "Engineering"
    OWNER       = "DevOps Team"
    FUNCTION    = "Infrastructure"
    PRODUCT     = "AI Chatbot"
    ENVIRONMENT = "production"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| create_vpc | Controls if VPC should be created | bool | true | no |
| cidr | The CIDR block for the VPC | string | "0.0.0.0/0" | no |
| azs | List of Availability Zones | list(string) | [] | yes |
| region | AWS region | string | - | yes |
| public_subnets | List of public subnet CIDR blocks | list(string) | [] | no |
| Private_App_Subnets | List of private application subnet CIDR blocks | list(string) | [] | no |
| enable_nat_gateway | Should be true to provision NAT Gateways | bool | false | no |
| single_nat_gateway | Should be true to provision a single shared NAT Gateway | bool | false | no |
| one_nat_gateway_per_az | Should be true to provision one NAT Gateway per AZ | bool | false | no |
| enable_dns_hostnames | Should be true to enable DNS hostnames in the VPC | bool | false | no |
| enable_dns_support | Should be true to enable DNS support in the VPC | bool | true | no |
| mandatory_tags | Mandatory tags for all resources | object | - | yes |
| custom_tags | Custom tags for all resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the VPC |
| vpc_cidr_block | CIDR block of the VPC |
| public_subnets | List of IDs of public subnets |
| private_subnets | List of IDs of private subnets |
| internet_gateway_id | ID of the Internet Gateway |
| nat_gateway_ids | List of IDs of the NAT Gateways |
| public_route_table_ids | List of IDs of the public route tables |
| private_route_table_ids | List of IDs of the private route tables |

## Notes

- NAT Gateway configuration affects cost: `one_nat_gateway_per_az = true` creates one NAT Gateway per AZ (more expensive but better availability)
- `single_nat_gateway = true` creates a single shared NAT Gateway (cost-effective but single point of failure)
- Private subnets require NAT Gateways for outbound internet access
- Public subnets have direct internet access via Internet Gateway

