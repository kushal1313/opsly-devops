##############################################################################
# Variables required for IAM
##############################################################################

variable "role_name" {
  description = "name of the resource"
  default     = ""
  validation {
    condition = (
      length(var.role_name) < 64
    )
    error_message = "The length of variable role_name is max 64 charcters."
  }
}

variable "role_description" {
  description = "IAM Role description"
  type        = string
  default     = ""
}

variable "assume_role_policy" {
  description = "Policy that grants an entity permission to assume the role."
  default     = <<-EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole",
      "Condition": {}
    }
  ]
}
EOT
}


variable "force_detach_policy" {
  type        = bool
  description = "Whether to force detaching any policies the role has before destroying it"
  default     = false
}

variable "max_session_duration" {
  type        = number
  description = "Maximum session duration (in seconds) that you want to set for the specified role."
  default     = 43200
}

variable "path" {
  description = "Path in which to create the role."
  default     = "/"
}

variable "aws_policy_arns" {
  type = list(object({
    arn = string
  }))
  default = []
}

variable "inline_policies" {
  type = list(object({
    name = string
    json = string
  }))
  default = []
}

variable "iam_role_name" {
  description = "role name to which you need to attach aws managed policy"
  type        = string
  default     = null
}

variable "create_role" {
  description = "Controls if the iam role should be created"
  type        = bool
  default     = true
}
variable "create_instance_profile" {
  description = "Controls if the iam instance profile should be created"
  type        = bool
  default     = true
  
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
