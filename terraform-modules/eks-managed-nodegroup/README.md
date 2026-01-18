# EKS Managed Node Group Module

Terraform module for creating Amazon EKS managed node groups.

## Features

- Creates EKS managed node groups with auto-scaling
- Configurable instance types and capacity types (ON_DEMAND or SPOT)
- Node labels and taints support
- Launch template configuration
- IAM role creation for node groups
- Support for multiple node groups per cluster

## Usage

```hcl
module "eks_node_group" {
  source = "./terraform-modules/eks-managed-nodegroup"
  
  name           = "general-workloads"
  cluster_name   = module.eks.cluster_name
  subnet_ids     = module.vpc.private_subnets
  instance_types = ["t3.medium", "t3.large"]
  capacity_type  = "ON_DEMAND"
  
  min_size     = 2
  max_size     = 5
  desired_size = 2
  
  create_iam_role = true
  
  labels = {
    workload-type = "general"
  }
  
  taints = []  # Optional: add taints if needed
  
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
| name | Name of the node group | string | - | yes |
| cluster_name | Name of the EKS cluster | string | - | yes |
| subnet_ids | List of subnet IDs where the nodes will be launched | list(string) | - | yes |
| instance_types | List of instance types for the node group | list(string) | - | yes |
| capacity_type | Type of capacity associated with the EKS Node Group (ON_DEMAND or SPOT) | string | "ON_DEMAND" | no |
| min_size | Minimum number of nodes in the node group | number | 1 | no |
| max_size | Maximum number of nodes in the node group | number | 3 | no |
| desired_size | Desired number of nodes in the node group | number | 2 | no |
| create_iam_role | Determines whether an IAM role is created | bool | true | no |
| labels | Key-value map of Kubernetes labels to apply to nodes | map(string) | {} | no |
| taints | List of Kubernetes taints to apply to nodes | list(object) | [] | no |
| mandatory_tags | Mandatory tags for all resources | object | - | yes |
| custom_tags | Custom tags for all resources | map(string) | {} | no |
| region | AWS region | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| node_group_id | EKS node group ID |
| node_group_arn | Amazon Resource Name (ARN) of the EKS Node Group |
| node_group_status | Status of the EKS Node Group |
| node_group_capacity_type | Type of capacity associated with the EKS Node Group |
| iam_role_arn | IAM role ARN associated with the node group |

## Prerequisites

- EKS cluster must exist before creating node groups
- Subnets must be in the same VPC as the EKS cluster
- IAM role will be created automatically if `create_iam_role = true`

## Notes

- Node groups are deployed in private subnets for security
- Use labels to schedule specific workloads to specific node groups
- Use taints to prevent certain workloads from being scheduled on specific node groups
- Auto-scaling is managed by the node group configuration (min/max/desired)
- For ML workloads, consider using compute-optimized instances (c5.xlarge, m5.large)
- For general workloads, general-purpose instances (t3.medium, t3.large) are typically sufficient

