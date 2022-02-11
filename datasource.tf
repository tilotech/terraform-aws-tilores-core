locals {
  dispatcher_plugin_artifact_key     = format("tilotech/tilores-core/%s/plugin-dispatcher.zip", var.core_version)
  assemble_artifact_key              = format("tilotech/tilores-core/%s/assemble.zip", var.core_version)
  disassemble_artifact_key           = format("tilotech/tilores-core/%s/disassemble.zip", var.core_version)
  remove_connection_ban_artifact_key = format("tilotech/tilores-core/%s/removeconnectionban.zip", var.core_version)
  scavenger_artifact_key             = format("tilotech/func-scavenger/%s/scavenger.zip", var.scavenger_version)
  customer_metrics_artifact_key      = format("tilotech/func-customer-metrics/%s/send.zip", var.customer_metrics_version)
}

data "aws_region" "current" {}

data "aws_s3_bucket_object" "dispatcher_plugin_artifact" {
  bucket = local.artifacts_bucket
  key    = local.dispatcher_plugin_artifact_key
}

data "aws_s3_bucket_object" "assemble_artifact" {
  bucket = local.artifacts_bucket
  key    = local.assemble_artifact_key
}

data "aws_s3_bucket_object" "disassemble_artifact" {
  bucket = local.artifacts_bucket
  key    = local.disassemble_artifact_key
}

data "aws_s3_bucket_object" "remove_connection_ban_artifact" {
  bucket = local.artifacts_bucket
  key    = local.remove_connection_ban_artifact_key
}

data "aws_s3_bucket_object" "scavenger_artifact" {
  bucket = local.artifacts_bucket
  key    = local.scavenger_artifact_key
}

data "aws_s3_bucket_object" "customer_metrics_artifact" {
  bucket = local.artifacts_bucket
  key    = local.customer_metrics_artifact_key
}