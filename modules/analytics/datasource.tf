locals {
  aggregate_analytics_artifact_key = format("tilotech/tilores-core/%s/aggregate-analytics.zip", var.core_version)
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_s3_object" "aggregate_analytics_artifact" {
  bucket = var.artifacts_bucket
  key    = local.aggregate_analytics_artifact_key
}
