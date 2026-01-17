locals {
  bucket_arn = coalesce(var.bucket_arn, "arn:${data.aws_partition.this.partition}:s3:::${var.bucket_name}")
  queue_ids = { for k, v in var.sqs_notifications : k => format("https://%s.%s.amazonaws.com/%s/%s", data.aws_arn.queue[k].service, data.aws_arn.queue[k].region, data.aws_arn.queue[k].account, data.aws_arn.queue[k].resource) if try(v.queue_id, "") == "" }
}
module "s3_bucket" {
  source                               = "github.com/terraform-aws-modules/terraform-aws-s3-bucket?ref=v3.10.1"
  create_bucket                        = var.create_bucket
  bucket                               = var.bucket_name
  bucket_prefix                        = var.bucket_prefix
  acl                                  = var.acl
  versioning                           = var.versioning
  grant                                = var.grant
  block_public_acls                    = var.block_public_acls
  block_public_policy                  = var.block_public_policy
  ignore_public_acls                   = var.ignore_public_acls
  restrict_public_buckets              = var.restrict_public_buckets
  lifecycle_rule                       = var.lifecycle_rule
  attach_policy                        = var.attach_policy
  policy                               = var.policy
  replication_configuration            = var.replication_configuration
  server_side_encryption_configuration = var.server_side_encryption_configuration
  control_object_ownership             = var.control_object_ownership
  object_ownership                     = var.object_ownership
  inventory_configuration              = var.inventory_configuration
  logging                              = var.logging
  tags = merge(
    var.mandatory_tags,
    var.custom_tags,
  )
}
data "aws_partition" "this" {}
resource "aws_s3_bucket_notification" "this" {
  count = var.create_bucket_notification ? 1 : 0

  bucket = var.bucket_name

  eventbridge = var.eventbridge

  dynamic "lambda_function" {
    for_each = var.lambda_notifications

    content {
      id                  = lambda_function.key
      lambda_function_arn = lambda_function.value.function_arn
      events              = lambda_function.value.events
      filter_prefix       = try(lambda_function.value.filter_prefix, null)
      filter_suffix       = try(lambda_function.value.filter_suffix, null)
    }
  }

  dynamic "queue" {
    for_each = var.sqs_notifications

    content {
      id            = queue.key
      queue_arn     = queue.value.queue_arn
      events        = queue.value.events
      filter_prefix = try(queue.value.filter_prefix, null)
      filter_suffix = try(queue.value.filter_suffix, null)
    }
  }

  dynamic "topic" {
    for_each = var.sns_notifications

    content {
      id            = topic.key
      topic_arn     = topic.value.topic_arn
      events        = topic.value.events
      filter_prefix = try(topic.value.filter_prefix, null)
      filter_suffix = try(topic.value.filter_suffix, null)
    }
  }

  depends_on = [
    aws_lambda_permission.allow,
    aws_sqs_queue_policy.allow,
    aws_sns_topic_policy.allow,
  ]
}
resource "aws_lambda_permission" "allow" {
  for_each = var.lambda_notifications

  statement_id_prefix = try(each.value.statement_id_prefix, null)
  action              = try(each.value.action, null)
  function_name       = each.value.function_name
  qualifier           = try(each.value.qualifier, null)
  principal           = try(each.value.principal, null)
  source_arn          = local.bucket_arn
  source_account      = try(each.value.source_account, null)
}
# SQS Queue
data "aws_arn" "queue" {
  for_each = var.sqs_notifications

  arn = each.value.queue_arn
}

data "aws_iam_policy_document" "sqs" {
  for_each = { for k, v in var.sqs_notifications : k => v if var.create_sqs_policy }

  statement {
    sid = "AllowSQSS3BucketNotification"

    effect = "Allow"

    actions = [
      "sqs:SendMessage",
    ]

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    resources = [each.value.queue_arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [local.bucket_arn]
    }
  }
}
resource "aws_sqs_queue_policy" "allow" {
  for_each = { for k, v in var.sqs_notifications : k => v if var.create_sqs_policy }

  queue_url = try(each.value.queue_id, local.queue_ids[each.key], null)
  policy    = data.aws_iam_policy_document.sqs[each.key].json
}

# SNS Topic
data "aws_iam_policy_document" "sns" {
  for_each = { for k, v in var.sns_notifications : k => v if var.create_sns_policy }

  statement {
    sid = "AllowSNSS3BucketNotification"

    effect = "Allow"

    actions = [
      "sns:Publish",
    ]

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    resources = [each.value.topic_arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [local.bucket_arn]
    }
  }
}
resource "aws_sns_topic_policy" "allow" {
  for_each = { for k, v in var.sns_notifications : k => v if var.create_sns_policy }

  arn    = each.value.topic_arn
  policy = data.aws_iam_policy_document.sns[each.key].json
}
