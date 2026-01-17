variable "region" {
  type        = string
  description = "AWS region"
}
variable "cluster_version" {
  description = "Kubernetes `<major>.<minor>` version to use for the EKS cluster (i.e.: `1.24`)"
  type        = string
  default     = null
}
variable "cluster_enabled_log_types" {
  description = "A list of the desired control plane logs to enable. For more information, see Amazon EKS Control Plane Logging documentation (https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html)"
  type        = list(string)
  default     = []
}
################################################################################
# Cluster Security Group
################################################################################
variable "create" {
  description = "Controls if EKS resources should be created (affects nearly all resources)"
  type        = bool
  default     = true
}
variable "create_node_sg" {
  type        = bool
  description = "(nodesg"
  default     = false
}
variable "create_cluster_security_group" {
  description = "Determines if a security group is created for the cluster. Note: the EKS service creates a primary security group for the cluster by default"
  type        = bool
  default     = false
}
variable "cluster_security_group_name" {
  description = "Name to use on cluster security group created"
  type        = string
  default     = ""
}
variable "cluster_security_group_use_name_prefix" {
  description = "Determines whether cluster security group name (`cluster_security_group_name`) is used as a prefix"
  type        = bool
  default     = false
}
variable "cluster_security_group_description" {
  description = "Description of the cluster security group created"
  type        = string
  default     = "" #"EKS created security group applied to ENI that is attached to EKS Control Plane master nodes, as well as any managed workloads."
}
variable "cluster_security_group_additional_rules" {
  description = "List of additional security group rules to add to the cluster security group created. Set `source_node_security_group = true` inside rules to set the `node_security_group` as source"
  type        = map(map(any))
  default = {


  }
}
variable "cluster_security_group_rules" {
  type        = map(map(any))
  description = "cluster-security_group_rules"

  default = {
  }


}
variable "node_security_group_id" {
  type        = string
  description = "node_security_group_id"
  default     = null
}
variable "cluster_security_group_tags" {
  description = "A map of additional tags to add to the cluster security group created"
  type        = map(string)
  default     = {}
}
variable "cluster_endpoint_private_access" {
  type        = bool
  description = "(optional) describe your variable"
  default     = true
}
variable "cluster_endpoint_public_access" {
  type        = bool
  description = "(optional) describe your varible"
  default     = false
}
variable "subnet_ids" {
  type        = list(string)
  description = "(optional) describe your variable"
  default     = []
}
variable "control_plane_subnet_ids" {
  type        = list(string)
  description = "(optional) describe your variable"
  default     = []
}
variable "cluster_name" {
  type    = string
  default = ""
}
variable "cluster_role" {
  type        = string
  description = "(optional) describe your variable"
  default     = ""
}
variable "cluster_security_group_id" {
  description = "Existing security group ID to be attached to the cluster"
  type        = string
  default     = ""
}
variable "vpc_id" {
  type        = string
  description = "(optional) describe your variable"
  default     = null
}
variable "mandatory_tags" {
  type = object({
    TEAM        = string
    DEPARTMENT  = string
    OWNER       = string
    FUNCTION    = string
    PRODUCT     = string
    ENVIRONMENT = string
    Name        = string
  })
}
variable "custom_tags" {
  default     = {}
  description = "Custom tag and value if any"
}


variable "ingress_rules" {
  type = list(object({
    from_port                = number
    to_port                  = number
    protocol                 = string
    cidr_block               = string
    description              = string
    source_security_group_id = string

  }))
  default = []
}

variable "egress_rules" {
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_block  = string
    description = string
    #source_security_group_id = string

  }))
  default = []
}


variable "ingress_rules_sg" {
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_block  = string
    description = string
    #self = bool
    source_security_group_id = string
  }))
  default = []
}


variable "create_cluster_sg" {
  type    = bool
  default = true

}