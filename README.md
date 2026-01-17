# AI Chatbot Framework - EKS Infrastructure

This repository contains Terraform modules and configurations to deploy a complete EKS infrastructure for the AI Chatbot Framework application.

## Architecture Overview

The infrastructure includes:

- **EKS Cluster** (Kubernetes 1.29+)
- **VPC** with public and private subnets across 3 Availability Zones
- **NAT Gateways** for private subnet egress
- **Two Managed Node Groups**:
  - General workloads: t3.medium/large (2-5 nodes, auto-scaling)
  - ML workloads: c5.xlarge or m5.large (1-3 nodes, auto-scaling)
- **EKS Add-ons**: CoreDNS, kube-proxy, VPC CNI, EBS CSI driver
- **IRSA (IAM Roles for Service Accounts)** for:
  - EBS CSI Driver
  - Cluster Autoscaler
  - AWS Load Balancer Controller
- **Helm Charts**:
  - Cluster Autoscaler
  - AWS Load Balancer Controller
- **Supporting Infrastructure**:
  - S3 bucket for chatbot data
  - ECR repositories for backend and frontend
  - ElastiCache Redis
  - SQS queue

## Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.0
3. **kubectl** installed
4. **helm** installed (for managing Kubernetes applications)
5. AWS account with appropriate permissions

## Directory Structure

```
.
├── main.tf                 # Main infrastructure configuration
├── variables.tf            # Variable definitions
├── outputs.tf             # Output definitions
├── terraform-modules/     # Reusable Terraform modules
│   ├── aws-vpc/           # VPC module
│   ├── eks/               # EKS cluster module
│   ├── eks-managed-nodegroup/  # Node group module
│   ├── eks-managed-addons/     # EKS add-ons module
│   ├── iam-role/          # IAM role module
│   ├── iam-policy/        # IAM policy module
│   ├── s3/                # S3 bucket module
│   ├── ecr/               # ECR repository module
│   ├── elasticache/      # ElastiCache module
│   └── sqs/               # SQS queue module
└── README.md              # This file
```

## Configuration

### Variables

Edit `variables.tf` or create a `terraform.tfvars` file to customize:

```hcl
aws_region = "us-east-1"
cluster_name = "ai-chatbot-eks"
cluster_version = "1.29"
vpc_cidr = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

# General workload node group
general_node_instance_types = ["t3.medium", "t3.large"]
general_node_min_size = 2
general_node_max_size = 5
general_node_desired_size = 2

# ML workload node group
ml_node_instance_types = ["c5.xlarge", "m5.large"]
ml_node_min_size = 1
ml_node_max_size = 3
ml_node_desired_size = 1

# Mandatory tags
mandatory_tags = {
  TEAM        = "DevOps"
  DEPARTMENT  = "Engineering"
  OWNER       = "DevOps Team"
  FUNCTION    = "AI Chatbot Infrastructure"
  PRODUCT     = "AI Chatbot Framework"
  ENVIRONMENT = "production"
  Name        = "ai-chatbot-eks"
}
```

## Deployment

Due to resource dependencies in Terraform, resources must be created in a specific order. The following steps ensure proper dependency resolution.

### Step 1: Initialize Terraform

```bash
terraform init
```

This downloads all required providers and modules.

### Step 2: Validate Configuration

Before planning or applying, validate your Terraform configuration:

```bash
terraform validate
```

This checks for syntax errors and validates the configuration structure. Fix any errors before proceeding.

### Step 3: Deploy Infrastructure in Stages

Due to dependencies between resources, we need to apply in stages. This approach ensures that resources that depend on others are created only after their dependencies exist.

#### Stage 1: Core Infrastructure (VPC, IAM Roles, and Supporting Resources)

First, create the foundational infrastructure that other resources depend on:

```bash
terraform apply -target=module.vpc \
  -target=module.eks_cluster_role \
  -target=module.s3_chatbot_data \
  -target=module.ecr_backend \
  -target=module.ecr_frontend \
  -target=module.elasticache_redis \
  -target=module.sqs_chatbot_queue \
  -target=aws_security_group.redis \
  -target=aws_elasticache_subnet_group.redis
```

**Why this order?**
- VPC must exist before EKS cluster and node groups can be created
- Supporting resources (S3, ECR, ElastiCache, SQS) are independent and can be created early
- EKS cluster role is needed before the cluster can be created

#### Stage 2: EKS Cluster

Once the VPC and cluster role exist, create the EKS cluster:

```bash
terraform apply -target=module.eks
```

**Why this order?**
- EKS cluster requires the VPC and cluster IAM role to exist
- Node groups, add-ons, and IRSA roles all depend on the cluster existing

#### Stage 3: OIDC Provider

After the cluster is created, set up the OIDC provider for IRSA:

```bash
terraform apply -target=data.tls_certificate.eks \
  -target=aws_iam_openid_connect_provider.eks
```

**Why this order?**
- OIDC provider requires the cluster's OIDC issuer URL, which is only available after cluster creation
- IRSA roles depend on the OIDC provider existing

#### Stage 4: IAM Policy for Load Balancer Controller

Create the IAM policy that will be attached to the Load Balancer Controller role:

```bash
terraform apply -target=module.aws_lb_controller_policy
```

**Why this order?**
- The AWS Load Balancer Controller IAM role references this policy ARN
- Policy must exist before the role can reference it

#### Stage 5: IRSA Roles

Create the IAM roles for service accounts:

```bash
terraform apply -target=module.ebs_csi_irsa_role \
  -target=module.cluster_autoscaler_irsa_role \
  -target=module.aws_lb_controller_irsa_role
```

**Why this order?**
- IRSA roles depend on the OIDC provider being created
- These roles are needed by EKS add-ons and Helm charts

#### Stage 6: Node Groups

Create the managed node groups:

```bash
terraform apply -target=module.eks_node_group_general \
  -target=module.eks_node_group_ml
```

**Why this order?**
- Node groups require the EKS cluster to exist
- They also need the cluster's security group and subnet configuration

#### Stage 7: EKS Add-ons

Install the EKS managed add-ons:

```bash
terraform apply -target=module.eks_addons
```

**Why this order?**
- Add-ons require the cluster and node groups to be ready
- EBS CSI driver add-on needs the IRSA role to exist

#### Stage 8: Kubernetes Resources and Helm Charts

Finally, create Kubernetes namespaces and install Helm charts:

```bash
terraform apply -target=kubernetes_namespace.kube_system \
  -target=helm_release.cluster_autoscaler \
  -target=helm_release.aws_load_balancer_controller
```

**Why this order?**
- Helm charts require the cluster to be accessible via kubectl
- They depend on IRSA roles being created
- Kubernetes namespace must exist before resources can be created in it

#### Stage 9: Complete Deployment

After all stages are complete, run a final apply to ensure everything is in sync:

```bash
terraform apply
```

This will catch any remaining resources and ensure the entire infrastructure is properly configured.

### Alternative: Single Apply (Not Recommended)

If you prefer to apply everything at once, you can use:

```bash
terraform apply
```

However, you may encounter dependency errors. If this happens, Terraform will indicate which resources need to be created first. Use the staged approach above to avoid these issues.

### Step 4: Configure kubectl

After the infrastructure is created, configure kubectl:

```bash
aws eks update-kubeconfig --region <your-region> --name <cluster-name>
```

Or use the output command:

```bash
terraform output -raw configure_kubectl
```

### Step 5: Verify Installation

Verify the cluster is accessible:

```bash
kubectl get nodes
kubectl get pods -n kube-system
```

Verify Helm releases:

```bash
helm list -n kube-system
```

Verify Cluster Autoscaler:

```bash
kubectl get pods -n kube-system | grep cluster-autoscaler
```

Verify AWS Load Balancer Controller:

```bash
kubectl get pods -n kube-system | grep aws-load-balancer-controller
```

## Key Components

### EKS Cluster

- **Version**: 1.29+
- **Endpoint Access**: Both private and public
- **Logging**: API, audit, authenticator, controller manager, scheduler

### Node Groups

#### General Workloads
- **Instance Types**: t3.medium, t3.large
- **Scaling**: 2-5 nodes
- **Labels**: `workload-type=general`

#### ML Workloads
- **Instance Types**: c5.xlarge, m5.large
- **Scaling**: 1-3 nodes
- **Labels**: `workload-type=ml`
- **Taints**: `workload-type=ml:NoSchedule`

### EKS Add-ons

- **CoreDNS**: DNS service for the cluster
- **kube-proxy**: Network proxy for the cluster
- **VPC CNI**: Networking plugin for pod networking
- **EBS CSI Driver**: Storage driver for EBS volumes (with IRSA)

### IRSA Roles

All service accounts use IAM Roles for Service Accounts (IRSA) for secure AWS API access:

- **EBS CSI Driver**: Manages EBS volumes
- **Cluster Autoscaler**: Automatically adjusts cluster size
- **AWS Load Balancer Controller**: Manages AWS load balancers

### Supporting Infrastructure

- **S3 Bucket**: `{cluster-name}-chatbot-data-{account-id}`
- **ECR Repositories**: 
  - `{cluster-name}-backend`
  - `{cluster-name}-frontend`
- **ElastiCache Redis**: Single node, cache.t3.medium
- **SQS Queue**: `{cluster-name}-chatbot-queue`

## Outputs

After deployment, you can view outputs:

```bash
terraform output
```

Key outputs include:
- Cluster endpoint and certificate
- VPC and subnet IDs
- Node group ARNs
- IRSA role ARNs
- S3 bucket name
- ECR repository URLs
- Redis endpoint
- SQS queue URL

## Application Deployment

After the infrastructure is ready, you can deploy the AI Chatbot Framework application:

1. **Build and push Docker images** to ECR repositories
2. **Create Kubernetes manifests** for:
   - Backend (FastAPI)
   - Frontend (React/Next.js)
   - MongoDB (or use DocumentDB)
3. **Configure ingress** using AWS Load Balancer Controller
4. **Set up secrets** for database connections, API keys, etc.

## Scaling

The cluster autoscaler will automatically scale node groups based on:
- Pod resource requests
- Node capacity
- Scaling policies defined in the node groups

You can also manually scale:

```bash
# Scale general node group
aws eks update-nodegroup-config \
  --cluster-name <cluster-name> \
  --nodegroup-name <nodegroup-name> \
  --scaling-config minSize=3,maxSize=10,desiredSize=5

# Or use kubectl to scale deployments
kubectl scale deployment <deployment-name> --replicas=5
```

## Monitoring

Consider setting up:
- CloudWatch Container Insights for EKS
- Prometheus and Grafana for metrics
- ELK stack for logging

## Cleanup

To destroy all resources, reverse the deployment order:

```bash
# Destroy in reverse order of creation
terraform destroy -target=helm_release.aws_load_balancer_controller \
  -target=helm_release.cluster_autoscaler \
  -target=kubernetes_namespace.kube_system \
  -target=module.eks_addons \
  -target=module.eks_node_group_ml \
  -target=module.eks_node_group_general \
  -target=module.aws_lb_controller_irsa_role \
  -target=module.cluster_autoscaler_irsa_role \
  -target=module.ebs_csi_irsa_role \
  -target=module.aws_lb_controller_policy \
  -target=aws_iam_openid_connect_provider.eks \
  -target=module.eks \
  -target=module.vpc
```

Or destroy everything at once:

```bash
terraform destroy
```

**Note**: This will delete all resources including the EKS cluster, VPC, and all supporting infrastructure. Make sure you have backups if needed.

## Troubleshooting

### Terraform Validation Errors

If `terraform validate` fails:

1. Check for syntax errors in `.tf` files
2. Verify all required variables are defined
3. Ensure module sources are correct
4. Check that provider versions are compatible

### EKS Cluster Not Found Errors

If you see "couldn't find resource" errors for the EKS cluster:

1. Ensure you've completed Stage 2 (EKS Cluster creation) before proceeding
2. Verify the cluster was created successfully:
   ```bash
   aws eks describe-cluster --name <cluster-name> --region <region>
   ```
3. Wait a few minutes after cluster creation before creating dependent resources

### Invalid Count Argument Errors

If you encounter count argument errors with IAM roles:

1. These errors occur because the upstream module checks policy strings at plan time
2. Complete Stage 3 (OIDC Provider) and Stage 5 (IRSA Roles) in order
3. The errors should resolve once the OIDC provider is created
4. If issues persist, apply the OIDC provider first, then the roles separately

### Cluster Autoscaler not working

1. Check IRSA role is properly configured:
   ```bash
   kubectl describe sa cluster-autoscaler -n kube-system
   ```

2. Check Cluster Autoscaler logs:
   ```bash
   kubectl logs -n kube-system deployment/cluster-autoscaler
   ```

### AWS Load Balancer Controller not working

1. Check IRSA role:
   ```bash
   kubectl describe sa aws-load-balancer-controller -n kube-system
   ```

2. Check controller logs:
   ```bash
   kubectl logs -n kube-system deployment/aws-load-balancer-controller
   ```

### Node groups not joining

1. Check node group status in AWS Console
2. Check security group rules
3. Verify IAM roles have correct permissions
4. Ensure the cluster was created before node groups

## Security Considerations

- All node groups are in private subnets
- EKS endpoint has both private and public access (adjust as needed)
- IRSA is used for all service accounts
- Security groups follow AWS best practices
- All resources are tagged appropriately

## Additional Resources

- [EKS User Guide](https://docs.aws.amazon.com/eks/latest/userguide/)
- [Cluster Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [IRSA Documentation](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)

## Support

For issues or questions, please contact the DevOps team.
