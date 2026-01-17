##############################################################################
# Variables required for IAM Policy
##############################################################################

variable "name" {
  description = "The name of the policy"
  type        = string
}

variable "path" {
  description = "The path of the policy in IAM"
  type        = string
  default     = "/"
}

variable "description" {
  description = "The description of the policy"
  type        = string
}

variable "policy" {
  description = "The path of the policy in IAM (tpl file)"
  type        = string
  default     = ""
}



##############################################################################
# Variables required for tagging
##############################################################################

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
