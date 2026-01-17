################################################################################
# IAM Role
################################################################################


module "iam_role_aws" {
  source                   = "github.com/terraform-aws-modules/terraform-aws-iam//modules/iam-assumable-role?ref=v5.3.0"
  create_role              = var.create_role
  role_name                = var.role_name
  role_path                = var.path
  custom_role_trust_policy = var.assume_role_policy
  role_description         = var.role_description
  max_session_duration     = var.max_session_duration
  create_instance_profile  = var.create_instance_profile
  tags = merge(
    var.mandatory_tags,
    var.custom_tags,
  )
}



resource "aws_iam_role_policy" "inline_policy" {
  count       = length(var.inline_policies)
  name_prefix = "${var.inline_policies[count.index].name}-${var.role_name}"
  role        = module.iam_role_aws.iam_role_name
  policy      = var.inline_policies[count.index].json
}

resource "aws_iam_role_policy_attachment" "policy_attachment" {
  count      = length(var.aws_policy_arns)
  role       = var.iam_role_name == null ? module.iam_role_aws.iam_role_name : var.iam_role_name
  policy_arn = var.aws_policy_arns[count.index].arn
}
