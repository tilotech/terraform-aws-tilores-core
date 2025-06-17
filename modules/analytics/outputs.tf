output "bucket_name" {
  value       = aws_s3_bucket.analytics.bucket
  description = "The name of the analytics S3 bucket."
}

output "bucket_arn" {
  value       = aws_s3_bucket.analytics.arn
  description = "The ARN of the analytics S3 bucket."
}

output "s3_entities_snapshot_arn" {
  value       = local.s3_entities_snapshot_arn
  description = "The full ARN to the location of the entities snapshot."
}

output "glue_entities_snapshot_table_arn" {
  value       = aws_glue_catalog_table.entities_snapshots.arn
  description = "The ARN of the entities snapshot table."
}

output "s3_records_snapshot_arn" {
  value       = local.s3_records_snapshot_arn
  description = "The full ARN to the location of the records snapshot."
}

output "glue_records_snapshot_table_arn" {
  value       = aws_glue_catalog_table.records_snapshots.arn
  description = "The ARN of the records snapshot table."
}

output "s3_query_output_arn" {
  value       = local.s3_query_output_arn
  description = "The full ARN to the location of the Athena query outputs."
}

output "s3_query_output_path" {
  value       = local.query_output_path
  description = "The path within the analytics bucket where the query results are stored."
}

output "glue_catalog_arn" {
  value       = local.glue_catalog_arn
  description = "The ARN of the glue catalog."
}

output "glue_database_name" {
  value       = aws_glue_catalog_database.analytics.name
  description = "The name of the glue database."
}

output "glue_database_arn" {
  value       = aws_glue_catalog_database.analytics.arn
  description = "The ARN of the glue database."
}

output "athena_workgroup_name" {
  value       = aws_athena_workgroup.analytics.name
  description = "The name of the athena workgroup."
}

output "athena_workgroup_arn" {
  value       = aws_athena_workgroup.analytics.arn
  description = "The ARN of the athena workgroup."
}
