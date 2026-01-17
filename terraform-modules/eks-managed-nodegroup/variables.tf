variable "region" {
  type        = string
  description = "AWS region"
}
variable "name" {
  description = "Name of the EKS managed node group"
  type        = string
  default     = ""
}
variable "use_name_prefix" {
  description = "Determines whether to use `name` as is or create a unique name beginning with the `name` as the prefix"
  type        = bool
  default     = false
}
variable "cluster_name" {
  description = "Name of associated EKS cluster"
  type        = string
  default     = ""
}
variable "cluster_version" {
  description = "Kubernetes version. Defaults to EKS Cluster Kubernetes version"
  type        = string
  default     = ""
}
variable "subnet_ids" {
  description = "Identifiers of EC2 Subnets to associate with the EKS Node Group. These subnets must have the following resource tag: `kubernetes.io/cluster/CLUSTER_NAME`"
  type        = list(string)
  default     = []
}
variable "create_iam_role" {
  description = "Determines whether an IAM role is created or to use an existing IAM role"
  type        = bool
  default     = false
}
variable "iam_role_arn" {
  description = "Existing IAM role ARN for the node group. Required if `create_iam_role` is set to `false`"
  type        = string
  default     = ""
}
variable "create_launch_template" {
  description = "Determines whether to create a launch template or not. If set to `false`, EKS will use its own default launch template"
  type        = bool
  default     = false
}
variable "create_separate_launch_template" {
  description = "Determines whether to create a launch template or not. If set to `false`, EKS will use its own default launch template"
  type        = bool
  default     = true
}
variable "key_name" {
  description = "The key name that should be used for the instance(s)"
  type        = string
  default     = null
}
variable "launch_template_name" {
  description = "Name of launch template to be created"
  type        = string
  default     = "default-launch-template"
}
variable "update_launch_template_default_version" {
  description = "Whether to update the launch templates default version on each update. Conflicts with `launch_template_default_version`"
  type        = bool
  default     = true
}
variable "use_custom_launch_template" {
  description = "Determines whether to use a custom launch template or not. If set to `false`, EKS will use its own default launch template"
  type        = bool
  default     = false
}
variable "launch_template_id" {
  description = "The ID of an existing launch template to use. Required when `create_launch_template` = `false` and `use_custom_launch_template` = `true`"
  type        = string
  default     = ""
}
variable "ami_type" {
  description = "Type of Amazon Machine Image (AMI) associated with the EKS Node Group. Valid values are `AL2_x86_64`, `AL2_x86_64_GPU`, `AL2_ARM_64`, `CUSTOM`, `BOTTLEROCKET_ARM_64`, `BOTTLEROCKET_x86_64`"
  type        = string
  default     = ""
}
variable "use_data_release_version" {
  description = "Determines whether to use release version from data source. set to false will use the ami_release_version from the variable"
  type        = bool
  default     = false
}
variable "ami_release_version" {
  description = "AMI version of the EKS Node Group. Defaults to latest version for Kubernetes version. Should be used if use_data_release_version is set to false"
  type        = string
  default     = null
}
variable "cluster_primary_security_group_id" {
  description = "The ID of the EKS cluster primary security group to associate with the instance(s). This is the security group that is automatically created by the EKS service"
  type        = string
  default     = ""
}
variable "vpc_security_group_ids" {
  description = "A list of security group IDs to associate"
  type        = list(string)
  default     = []
}
variable "remote_access" {
  description = "Configuration block with remote access settings. Only valid when `use_custom_launch_template` = `false`"
  type        = any
  default     = {}
}

variable "block_device_mappings" {
  description = "Specify volumes to attach to the instance besides the volumes specified by the AMI"
  type        = any
  default     = {}
}
variable "min_size" {
  description = "Minimum number of instances/nodes"
  type        = number
  default     = 0
}

variable "max_size" {
  description = "Maximum number of instances/nodes"
  type        = number
  default     = 3
}

variable "desired_size" {
  description = "Desired number of instances/nodes"
  type        = number
  default     = 1
}
variable "instance_types" {
  description = "Set of instance types associated with the EKS Node Group. Defaults to `[\"t3.medium\"]`"
  type        = list(string)
  default     = []
}
variable "capacity_type" {
  description = "Type of capacity associated with the EKS Node Group. Valid values: `ON_DEMAND`, `SPOT`"
  type        = string
  default     = "ON_DEMAND"
}
variable "update_config" {
  description = "Configuration block of settings for max unavailable resources during node group updates"
  type        = map(string)
  default = {
    max_unavailable_percentage = 33
  }
}
variable "labels" {
  description = "Key-value map of Kubernetes labels. Only labels that are applied with the EKS API are managed by this argument. Other Kubernetes labels applied to the EKS Node Group will not be managed"
  type        = map(string)
  default     = null
}
variable "taints" {
  description = "The Kubernetes taints to be applied to the nodes in the node group. Maximum of 50 taints per node group"
  type        = any
  default     = {}
}
variable "mandatory_tags" {
  type = object({
    TEAM        = string
    DEPARTMENT  = string
    OWNER       = string
    FUNCTION    = string
    PRODUCT     = string
    ENVIRONMENT = string
  })

}

variable "custom_tags" {
  default     = {}
  description = "Custom tag and value if any"
}


variable "metadata_options" {
  description = "Customize the metadata options for the instance"
  type        = map(string)
  default = {

  }
}
