module "ecr" {
  source                            = "github.com/terraform-aws-modules/terraform-aws-ecr?ref=v1.4.0"
  repository_name                   = var.repository_name
  create_repository                 = var.create_repository
  create                            = var.create
  repository_type                   = var.repository_type
  repository_image_tag_mutability   = var.repository_image_tag_mutability
  repository_encryption_type        = var.repository_encryption_type
  repository_kms_key                = var.repository_kms_key
  repository_image_scan_on_push     = var.repository_image_scan_on_push
  repository_policy                 = var.repository_policy
  repository_force_delete           = var.repository_force_delete
  attach_repository_policy          = var.attach_repository_policy
  create_repository_policy          = var.create_repository_policy
  repository_read_access_arns       = var.repository_read_access_arns
  repository_read_write_access_arns = var.repository_read_write_access_arns
  create_lifecycle_policy           = var.create_lifecycle_policy
  repository_lifecycle_policy       = var.repository_lifecycle_policy
  tags = merge(
    var.mandatory_tags,
    var.custom_tags,
  )
}