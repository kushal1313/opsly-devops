################################################################################
# VPC Outputs
################################################################################

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

################################################################################
# EKS Cluster Outputs
################################################################################

output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}

output "cluster_version" {
  description = "Kubernetes version"
  value       = module.eks.cluster_version
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = module.eks.cluster_oidc_issuer_url
}

################################################################################
# Node Group Outputs
################################################################################

output "node_group_general_arn" {
  description = "Amazon Resource Name (ARN) of the general workload node group"
  value       = module.eks_node_group_general.node_group_arn
}

output "node_group_ml_arn" {
  description = "Amazon Resource Name (ARN) of the ML workload node group"
  value       = module.eks_node_group_ml.node_group_arn
}

################################################################################
# IRSA Role Outputs
################################################################################

output "ebs_csi_irsa_role_arn" {
  description = "IAM role ARN for EBS CSI driver"
  value       = module.ebs_csi_irsa_role.iam_role_arn
}

output "cluster_autoscaler_irsa_role_arn" {
  description = "IAM role ARN for Cluster Autoscaler"
  value       = module.cluster_autoscaler_irsa_role.iam_role_arn
}

output "aws_lb_controller_irsa_role_arn" {
  description = "IAM role ARN for AWS Load Balancer Controller"
  value       = module.aws_lb_controller_irsa_role.iam_role_arn
}

################################################################################
# Supporting Infrastructure Outputs
################################################################################

output "s3_chatbot_data_bucket_name" {
  description = "Name of the S3 bucket for chatbot data"
  value       = module.s3_chatbot_data.s3_bucket_id
}

output "ecr_backend_repository_url" {
  description = "URL of the ECR repository for backend"
  value       = module.ecr_backend.repository_url
}

output "ecr_frontend_repository_url" {
  description = "URL of the ECR repository for frontend"
  value       = module.ecr_frontend.repository_url
}

output "elasticache_redis_cluster_id" {
  description = "Redis ElastiCache cluster ID"
  value       = "${var.cluster_name}-redis"
}

output "redis_security_group_id" {
  description = "Security group ID for Redis"
  value       = aws_security_group.redis.id
}

output "redis_endpoint" {
  description = "Redis ElastiCache endpoint (use AWS CLI or Console to get the actual endpoint)"
  value       = "${var.cluster_name}-redis.xxxxx.cache.amazonaws.com:6379"
}

output "sqs_chatbot_queue_name" {
  description = "Name of the SQS queue for chatbot"
  value       = "${var.cluster_name}-chatbot-queue"
}

################################################################################
# Connection Instructions
################################################################################

output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

