##############################################################################
# SQS module
################################################################################
module "sqs" {
  source                                = "github.com/terraform-aws-modules/terraform-aws-sqs?ref=v4.1.1"
  create                                = var.create
  name                                  = var.name
  fifo_queue                            = var.fifo_queue
  use_name_prefix                       = var.use_name_prefix
  content_based_deduplication           = var.content_based_deduplication
  deduplication_scope                   = var.deduplication_scope
  delay_seconds                         = var.delay_seconds
  fifo_throughput_limit                 = var.fifo_throughput_limit
  kms_data_key_reuse_period_seconds     = var.kms_data_key_reuse_period_seconds
  kms_master_key_id                     = var.kms_master_key_id
  sqs_managed_sse_enabled               = var.sqs_managed_sse_enabled
  max_message_size                      = var.max_message_size
  message_retention_seconds             = var.message_retention_seconds
  receive_wait_time_seconds             = var.receive_wait_time_seconds
  visibility_timeout_seconds            = var.visibility_timeout_seconds
  create_queue_policy                   = var.create_queue_policy
  source_queue_policy_documents         = var.source_queue_policy_documents
  override_queue_policy_documents       = var.override_queue_policy_documents
  redrive_allow_policy                  = var.redrive_allow_policy
  queue_policy_statements               = var.queue_policy_statements
  redrive_policy                        = var.redrive_policy
  dlq_name                              = var.dlq_name
  dlq_kms_master_key_id                 = var.dlq_kms_master_key_id
  dlq_sqs_managed_sse_enabled           = var.dlq_sqs_managed_sse_enabled
  create_dlq                            = var.create_dlq
  dlq_content_based_deduplication       = var.dlq_content_based_deduplication
  dlq_deduplication_scope               = var.dlq_deduplication_scope
  dlq_delay_seconds                     = var.dlq_delay_seconds
  dlq_kms_data_key_reuse_period_seconds = var.dlq_kms_data_key_reuse_period_seconds
  dlq_message_retention_seconds         = var.dlq_message_retention_seconds
  dlq_receive_wait_time_seconds         = var.dlq_receive_wait_time_seconds
  dlq_visibility_timeout_seconds        = var.dlq_visibility_timeout_seconds
  create_dlq_queue_policy               = var.create_dlq_queue_policy
  source_dlq_queue_policy_documents     = var.source_dlq_queue_policy_documents
  override_dlq_queue_policy_documents   = var.override_dlq_queue_policy_documents
  dlq_queue_policy_statements           = var.dlq_queue_policy_statements
  dlq_redrive_allow_policy              = var.dlq_redrive_allow_policy
  tags = merge(
    var.mandatory_tags,
    var.custom_tags,
  )
}
