resource "aws_elasticache_cluster" "redis" {
  count                      = var.create_cluster_without_replication ? 1 : 0
  availability_zone          = var.availability_zones
  cluster_id                 = var.cluster_id
  subnet_group_name          = var.subnet_group_name
  port                       = var.port
  num_cache_nodes            = var.cluster_size
  node_type                  = var.node_type
  engine_version             = var.engine_version
  engine                     = var.engine
  parameter_group_name       = var.parameter_group_name
  security_group_ids         = var.security_group_ids
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  maintenance_window         = var.maintenance_window
  tags = merge(
    var.mandatory_tags,
    var.custom_tags,
  )
}