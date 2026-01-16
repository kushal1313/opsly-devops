###############################################################################
# EKS Cluster
################################################################################

resource "aws_eks_cluster" "this" {
  count = var.create ? 1 : 0

  name                      = var.cluster_name
  role_arn                  = var.cluster_role
  version                   = var.cluster_version
  enabled_cluster_log_types = var.cluster_enabled_log_types

  vpc_config {
    security_group_ids      = [local.cluster_security_group_id]
    subnet_ids              = coalescelist(var.control_plane_subnet_ids, var.subnet_ids)
    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access  = var.cluster_endpoint_public_access
  }
  tags = merge(
    var.mandatory_tags,
    var.custom_tags,
  )
}
################################################################################
# Cluster Security Group
# Defaults follow https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html
################################################################################

locals {
  cluster_sg_name   = coalesce(var.cluster_security_group_name, "${var.cluster_name}-cluster")
  create_cluster_sg = var.create && var.create_cluster_security_group

  cluster_security_group_id = local.create_cluster_sg ? aws_security_group.cluster[0].id : var.cluster_security_group_id

  cluster_security_group_rules = { for k, v in {
    ingress_nodes_443 = {
      description                = "Node groups to cluster API"
      protocol                   = "tcp"
      from_port                  = 443
      to_port                    = 443
      type                       = "ingress"
      source_node_security_group = true
    }
  } : k => v if var.create_node_sg }
}

resource "aws_security_group" "cluster" {
  count       = local.create_cluster_sg ? 1 : 0
  name        = var.cluster_security_group_use_name_prefix ? null : local.cluster_sg_name
  description = var.cluster_security_group_description
  vpc_id      = var.vpc_id

  tags = merge(
    var.mandatory_tags,
    var.custom_tags,
  )

  lifecycle {
    create_before_destroy = true
  }
}



resource "aws_security_group_rule" "ingress_rules" {
  count = local.create_cluster_sg ? length(var.ingress_rules) : 0

  type              = "ingress"
  from_port         = var.ingress_rules[count.index].from_port
  to_port           = var.ingress_rules[count.index].to_port
  protocol          = var.ingress_rules[count.index].protocol
  cidr_blocks       = [var.ingress_rules[count.index].cidr_block]
  description       = var.ingress_rules[count.index].description
  security_group_id = aws_security_group.cluster[0].id
}

resource "aws_security_group_rule" "ingress_rules_sg" {
  count = local.create_cluster_sg ? length(var.ingress_rules_sg) : 0

  type      = "ingress"
  from_port = var.ingress_rules_sg[count.index].from_port
  to_port   = var.ingress_rules_sg[count.index].to_port
  protocol  = var.ingress_rules_sg[count.index].protocol
  #cidr_blocks       = try(var.ingress_rules[count.index].cidr_block, false) ? var.ingress_rules[count.index].cidr_block : null
  description              = var.ingress_rules_sg[count.index].description
  security_group_id        = aws_security_group.cluster[0].id
  source_security_group_id = try(var.ingress_rules_sg[count.index].source_node_security_group, false) ? var.node_security_group_id : lookup(var.ingress_rules_sg[count.index], "source_security_group_id", null)
}

resource "aws_security_group_rule" "egress_rules" {
  count = local.create_cluster_sg ? length(var.egress_rules) : 0

  type                     = "egress"
  from_port                = var.egress_rules[count.index].from_port
  to_port                  = var.egress_rules[count.index].to_port
  protocol                 = var.egress_rules[count.index].protocol
  cidr_blocks              = [var.egress_rules[count.index].cidr_block]
  description              = var.egress_rules[count.index].description
  security_group_id        = aws_security_group.cluster[0].id
  source_security_group_id = try(var.egress_rules[count.index].source_node_security_group, false) ? var.node_security_group_id : lookup(var.egress_rules[count.index], "source_security_group_id", null)

}

