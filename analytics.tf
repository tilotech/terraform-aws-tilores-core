module "analytics" {
  source = "./modules/analytics"
  count  = var.enable_analytics ? 1 : 0

  prefix                            = local.prefix
  core_version                      = var.core_version
  artifacts_bucket                  = local.artifacts_bucket
  cloudwatch_logs_retention_in_days = var.cloudwatch_logs_retention_in_days
  entity_s3_bucket_id               = aws_s3_bucket.entity.id
  entity_s3_bucket_arn              = aws_s3_bucket.entity.arn
  snapshot_query_mode               = var.snapshot_query_mode
}
