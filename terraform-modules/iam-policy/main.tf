################################################################################
# IAM Policy
################################################################################
module "iam_role_policy" {
  source      = "github.com/terraform-aws-modules/terraform-aws-iam//modules/iam-policy?ref=v5.3.0"
  name        = var.name
  path        = var.path
  description = var.description
  policy      = var.policy
  tags = merge(
    var.mandatory_tags,
    var.custom_tags,
  )
}