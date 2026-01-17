################################################################################
# Common Variables
################################################################################

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "ai-chatbot-eks"
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.29"
}

################################################################################
# VPC Variables
################################################################################

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to use for the infrastructure"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

################################################################################
# Node Group Variables - General Workloads
################################################################################

variable "general_node_instance_types" {
  description = "Instance types for general workload node group"
  type        = list(string)
  default     = ["t3.medium", "t3.large"]
}

variable "general_node_min_size" {
  description = "Minimum number of nodes in general workload node group"
  type        = number
  default     = 2
}

variable "general_node_max_size" {
  description = "Maximum number of nodes in general workload node group"
  type        = number
  default     = 5
}

variable "general_node_desired_size" {
  description = "Desired number of nodes in general workload node group"
  type        = number
  default     = 2
}

################################################################################
# Node Group Variables - ML Workloads
################################################################################

variable "ml_node_instance_types" {
  description = "Instance types for ML workload node group"
  type        = list(string)
  default     = ["c5.xlarge", "m5.large"]
}

variable "ml_node_min_size" {
  description = "Minimum number of nodes in ML workload node group"
  type        = number
  default     = 1
}

variable "ml_node_max_size" {
  description = "Maximum number of nodes in ML workload node group"
  type        = number
  default     = 3
}

variable "ml_node_desired_size" {
  description = "Desired number of nodes in ML workload node group"
  type        = number
  default     = 1
}

################################################################################
# Tagging Variables
################################################################################

variable "mandatory_tags" {
  description = "Mandatory tags for all resources"
  type = object({
    TEAM        = string
    DEPARTMENT  = string
    OWNER       = string
    FUNCTION    = string
    PRODUCT     = string
    ENVIRONMENT = string
    Name        = string
  })
  default = {
    TEAM        = "DevOps"
    DEPARTMENT  = "Engineering"
    OWNER       = "DevOps Team"
    FUNCTION    = "AI Chatbot Infrastructure"
    PRODUCT     = "AI Chatbot Framework"
    ENVIRONMENT = "production"
    Name        = "ai-chatbot-eks"
  }
}

variable "custom_tags" {
  description = "Custom tags for all resources"
  type        = map(string)
  default     = {}
}

