output "bucket_name" {
  value       = aws_s3_bucket.analytics.bucket
  description = "The name of the analytics S3 bucket."
}

output "s3_entities_snapshot_arn" {
  value       = local.s3_entities_snapshot_arn
  description = "The full ARN to the location of the entities snapshot."
}

output "s3_records_snapshot_arn" {
  value       = local.s3_records_snapshot_arn
  description = "The full ARN to the location of the records snapshot."
}
