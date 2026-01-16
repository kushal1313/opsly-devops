data "aws_eks_cluster" "eks" {
  name = var.cluster_name
}
################################################################################
# EKS managed Addons
################################################################################
resource "aws_eks_addon" "this" {
  for_each = { for k, v in var.cluster_addons : k => v if !try(v.before_compute, false) && var.create }

  cluster_name = data.aws_eks_cluster.eks.name
  addon_name   = try(each.value.name, each.key)

  addon_version               = coalesce(try(each.value.addon_version, null), data.aws_eks_addon_version.this[each.key].version)
  configuration_values        = try(each.value.configuration_values, null) ## if we want to provide custom configuration like replica count, resource allocation, we can do using this.
  preserve                    = try(each.value.preserve, null)
  resolve_conflicts_on_create = try(each.value.resolve_conflicts, "OVERWRITE")
  resolve_conflicts_on_update = try(each.value.resolve_conflicts, "OVERWRITE")
  service_account_role_arn    = try(each.value.service_account_role_arn, null) ## if we want any specific tole to be used while creating the addons, by default if we ddnt specify it will use the IAM role attached to the node.

  timeouts {
    create = try(each.value.timeouts.create, var.cluster_addons_timeouts.create, null)
    update = try(each.value.timeouts.update, var.cluster_addons_timeouts.update, null)
    delete = try(each.value.timeouts.delete, var.cluster_addons_timeouts.delete, null)
  }

  tags = merge(
    var.mandatory_tags,
    var.custom_tags,
  )
}


data "aws_eks_addon_version" "this" {
  for_each = { for k, v in var.cluster_addons : k => v if var.create }

  addon_name         = try(each.value.name, each.key)
  kubernetes_version = coalesce(var.cluster_version, data.aws_eks_cluster.eks.version)
  most_recent        = try(each.value.most_recent, null)
}
