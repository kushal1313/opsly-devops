# ElastiCache Module

Terraform module for creating Amazon ElastiCache clusters (Redis/Valkey).

## Features

- Creates ElastiCache clusters (Redis or Valkey)
- Single-node or replication group support
- Subnet group configuration
- Security group configuration
- Parameter group support
- Automatic failover (for replication groups)
- Backup and maintenance window configuration

## Usage

### Single Node Cluster

```hcl
module "elasticache_redis" {
  source = "./terraform-modules/elasticache"
  
  create_cluster_without_replication = true
  cluster_id                         = "my-redis-cluster"
  engine                             = "redis"
  engine_version                     = "7.0"
  node_type                          = "cache.t3.medium"
  cluster_size                       = 1
  parameter_group_name               = "default.redis7"
  port                               = 6379
  subnet_group_name                  = aws_elasticache_subnet_group.redis.name
  security_group_ids                 = [aws_security_group.redis.id]
  availability_zones                 = "us-east-1a"
  vpc_id                             = module.vpc.vpc_id
  
  mandatory_tags = {
    TEAM        = "DevOps"
    DEPARTMENT  = "Engineering"
    OWNER       = "DevOps Team"
    FUNCTION    = "Caching"
    PRODUCT     = "AI Chatbot"
    ENVIRONMENT = "production"
  }
  
  region = "us-east-1"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| create_cluster_without_replication | Controls if single-node cluster should be created | bool | false | no |
| cluster_id | Group identifier for the ElastiCache cluster | string | - | yes |
| engine | Name of the cache engine (redis or valkey) | string | "redis" | no |
| engine_version | Version number of the cache engine | string | - | yes |
| node_type | Instance type for the cache nodes | string | - | yes |
| cluster_size | Number of cache nodes in the cluster | number | 1 | no |
| parameter_group_name | Name of the parameter group to associate with this cluster | string | "default.redis7" | no |
| port | Port number on which the cache accepts connections | number | 6379 | no |
| subnet_group_name | Name of the subnet group to use for the cluster | string | - | yes |
| security_group_ids | List of security group IDs to associate with the cluster | list(string) | - | yes |
| availability_zones | Availability zone for the cluster | string | - | yes |
| vpc_id | ID of the VPC where the cluster will be created | string | - | yes |
| mandatory_tags | Mandatory tags for all resources | object | - | yes |
| custom_tags | Custom tags for all resources | map(string) | {} | no |
| region | AWS region | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| cluster_endpoint | Address of the ElastiCache cluster endpoint |
| cluster_id | ElastiCache cluster ID |
| cluster_port | Port number on which the cache accepts connections |

## Prerequisites

- VPC and subnets must exist
- ElastiCache subnet group must be created
- Security group must be created with appropriate rules
- Subnets must be in the same VPC

## Notes

- ElastiCache clusters are deployed in private subnets for security
- Single-node clusters are cost-effective but lack high availability
- For production, consider using replication groups with automatic failover
- Security groups must allow inbound traffic on the Redis port (6379) from application subnets
- ElastiCache Valkey is AWS's managed Redis-compatible service
- Use parameter groups to configure Redis settings (e.g., maxmemory-policy)
- Backup and maintenance windows can be configured for production clusters

## Security Considerations

- ElastiCache clusters should be in private subnets
- Security groups should restrict access to application subnets only
- Consider enabling encryption in transit and at rest for sensitive data
- Use IAM authentication (available for Redis 6.0+) for additional security

