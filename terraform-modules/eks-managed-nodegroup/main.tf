data "aws_eks_cluster" "eks" {
  name = var.cluster_name
}
resource "aws_launch_template" "lt" {
  count                  = var.create_separate_launch_template ? 1 : 0
  name                   = var.launch_template_name
  update_default_version = var.update_launch_template_default_version
  dynamic "block_device_mappings" {
    for_each = var.block_device_mappings
    content {
      device_name = try(block_device_mappings.value.device_name, null)

      dynamic "ebs" {
        for_each = try([block_device_mappings.value.ebs], [])

        content {
          delete_on_termination = try(ebs.value.delete_on_termination, null)
          encrypted             = try(ebs.value.encrypted, null)
          iops                  = try(ebs.value.iops, null)
          kms_key_id            = try(ebs.value.kms_key_id, null)
          snapshot_id           = try(ebs.value.snapshot_id, null)
          throughput            = try(ebs.value.throughput, null)
          volume_size           = try(ebs.value.volume_size, null)
          volume_type           = try(ebs.value.volume_type, null)
        }
      }

      no_device    = try(block_device_mappings.value.no_device, null)
      virtual_name = try(block_device_mappings.value.virtual_name, null)
    }
  }

  dynamic "metadata_options" {
    for_each = length(var.metadata_options) > 0 ? [var.metadata_options] : []

    content {
      http_endpoint               = try(metadata_options.value.http_endpoint, null)
      http_protocol_ipv6          = try(metadata_options.value.http_protocol_ipv6, null)
      http_put_response_hop_limit = try(metadata_options.value.http_put_response_hop_limit, null)
      http_tokens                 = try(metadata_options.value.http_tokens, null)
      instance_metadata_tags      = try(metadata_options.value.instance_metadata_tags, null)
    }
  }

  vpc_security_group_ids = var.vpc_security_group_ids
  key_name               = var.key_name
  tags = merge(
    var.mandatory_tags,
    var.custom_tags,
  )
}
data "aws_ssm_parameter" "eks_ami_release_version" {
  name = "/aws/service/eks/optimized-ami/${data.aws_eks_cluster.eks.version}/amazon-linux-2/recommended/release_version"
}
module "eks_managed_node_group" {
  source                                 = "github.com/terraform-aws-modules/terraform-aws-eks.git//modules/eks-managed-node-group?ref=v19.12.0"
  name                                   = var.name
  use_name_prefix                        = var.use_name_prefix
  cluster_name                           = data.aws_eks_cluster.eks.name
  cluster_version                        = data.aws_eks_cluster.eks.version
  subnet_ids                             = var.subnet_ids
  create_launch_template                 = var.create_launch_template
  use_custom_launch_template             = var.use_custom_launch_template
  launch_template_id                     = var.create_separate_launch_template ? aws_launch_template.lt[0].id : var.launch_template_id
  create_iam_role                        = var.create_iam_role
  iam_role_arn                           = var.iam_role_arn
  cluster_primary_security_group_id      = data.aws_eks_cluster.eks.vpc_config[0].cluster_security_group_id
  ami_type                               = var.ami_type
  ami_release_version                    = var.use_data_release_version ? nonsensitive(data.aws_ssm_parameter.eks_ami_release_version.value) : var.ami_release_version
  min_size                               = var.min_size
  max_size                               = var.max_size
  desired_size                           = var.desired_size
  instance_types                         = var.instance_types
  capacity_type                          = var.capacity_type
  update_config                          = var.update_config
  labels                                 = var.labels
  taints                                 = var.taints
  depends_on                             = [aws_launch_template.lt[0]]
  tags = merge(
    var.mandatory_tags,
    var.custom_tags,
  )
}
