##################################################
# Variables required for aws_elasticache_cluster #
##################################################
variable "create_cluster_without_replication" {
  type        = bool
  description = "Controls to create elastic cache cluster without replication group."
  default     = true
}
variable "region" {
  type        = string
  description = "AWS region"
}

variable "availability_zones" {
  type        = string
  description = "Availability zone IDs"
}
variable "cluster_id" {
  type        = string
  default     = ""
  description = "Name to give to cluster id"
}
variable "subnet_group_name" {
  type        = string
  default     = ""
  description = "Name of the subnet group to be used for the cache cluster. Changing this value will re-create the resource."
}
variable "port" {
  type        = number
  description = "The port number on which each of the cache nodes will accept connections. For Memcached the default is 11211, and for Redis the default port is 6379"
}
variable "cluster_size" {
  type        = number
  description = "Number of nodes in cluster"
}
variable "node_type" {
  type        = string
  description = "Elastic cache instance type"
}

variable "engine" {
  type        = string
  description = "Redis family"
}

variable "engine_version" {
  type        = string
  description = "Redis engine version"
}
variable "security_group_ids" {
  type        = list(string)
  default     = []
  description = "One or more VPC security groups associated with the cache cluster"
}
variable "vpc_id" {
  type        = string
  default     = ""
  description = "vpc id"
}
variable "name" {
  type        = string
  default     = ""
  description = "Name to give to cluster id"
}
variable "parameter_group_name" {
  type        = string
  default     = ""
  description = "The name of the parameter group to associate with this cache cluster."
}
variable "auto_minor_version_upgrade" {
  type        = bool
  default     = true
  description = "Specifies whether minor version engine upgrades will be applied automatically to the underlying Cache Cluster instances during the maintenance window. Only supported if the engine version is 6 or higher."
}
variable "maintenance_window" {
  type        = string
  default     = ""
  description = "Maintenance window"
}
##################################
# Variables required for tagging #
##################################

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


