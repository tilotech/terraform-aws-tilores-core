output "api_url" {
  value       = module.api_gateway.apigatewayv2_api_api_endpoint
  description = "The endpoint URL of the GraphQL API."
}

output "api_default_stage_id" {
  value       = module.api_gateway.default_apigatewayv2_stage_id
  description = "The default stage ID of the GraphQL API."
}

output "api_id" {
  value       = module.api_gateway.apigatewayv2_api_id
  description = "The ID of the GraphQL API."
}

output "core_policy_arn" {
  value       = aws_iam_policy.lambda_core.arn
  description = "The policy ARN granting access to core resources"
}

output "core_environment_variables" {
  value       = local.core_envs
  description = "The core lambda environment variables"
}

output "config_layer_arn" {
  value       = module.lambda_layer_rule_config.lambda_layer_arn
  description = "The lambda layer ARN holding the config"
}

output "etm_ref_lists_layer_arn" {
  value       = module.lambda_layer_etm_ref_lists.lambda_layer_arn
  description = "The lambda layer ARN holding etm pre-defined reference lists"
}

output "entity_bucket_name" {
  value       = aws_s3_bucket.entity.id
  description = "The name of the bucket holding the entities"
}

output "entity_bucket_arn" {
  value       = aws_s3_bucket.entity.arn
  description = "The ARN of the bucket holding the entities"
}

output "entity_stream_kinesis_arn" {
  value       = local.create_entity_stream_kinesis ? aws_kinesis_stream.kinesis_entity_stream[0].arn : ""
  description = "The ARN of the kinesis entity stream"
}

output "entity_stream_sqs_arn" {
  value       = local.create_entity_stream_sqs ? aws_sqs_queue.entity_stream[0].arn : ""
  description = "The ARN of the SQS entity stream"
}

output "execution_plan_bucket_arn" {
  value       = aws_s3_bucket.execution_plan.arn
  description = "The ARN of the bucket holding the execution plans"
}

output "scavenger_dead_letter_queue_arn" {
  value       = aws_sqs_queue.scavenger_dead_letter_queue.arn
  description = "The ARN of the scavenger dead letter queue"
}

output "scavenger_dead_letter_queue_id" {
  value       = aws_sqs_queue.scavenger_dead_letter_queue.id
  description = "The ID of the scavenger dead letter queue"
}

output "table_entities_name" {
  value       = aws_dynamodb_table.entities.name
  description = "The DynamoDB name for entities table"
}

output "table_entities_arn" {
  value       = aws_dynamodb_table.entities.arn
  description = "The DynamoDB arn for entities table"
}

output "table_records_name" {
  value       = aws_dynamodb_table.records.name
  description = "The DynamoDB name for records table"
}

output "table_records_arn" {
  value       = aws_dynamodb_table.records.arn
  description = "The DynamoDB arn for records table"
}

output "analytics_bucket_name" {
  value       = var.enable_analytics ? module.analytics[0].bucket_name : ""
  description = "The name of the bucket holding the analytics data (if enabled)"
}

output "analytics_bucket_arn" {
  value       = var.enable_analytics ? module.analytics[0].bucket_arn : ""
  description = "The ARN of the analytics S3 bucket (if enabled)."
}

output "analytics_s3_entities_snapshot_arn" {
  value       = var.enable_analytics ? module.analytics[0].s3_entities_snapshot_arn : ""
  description = "The full ARN to the location of the entities snapshot (if enabled)."
}

output "analytics_glue_entities_snapshot_table_arn" {
  value       = var.enable_analytics ? module.analytics[0].glue_entities_snapshot_table_arn : ""
  description = "The ARN of the entities snapshot table (if enabled)."
}

output "analytics_s3_records_snapshot_arn" {
  value       = var.enable_analytics ? module.analytics[0].s3_records_snapshot_arn : ""
  description = "The full ARN to the location of the records snapshot (if enabled)."
}

output "analytics_glue_records_snapshot_table_arn" {
  value       = var.enable_analytics ? module.analytics[0].glue_records_snapshot_table_arn : ""
  description = "The ARN of the records snapshot table (if enabled)."
}

output "analytics_s3_query_output_arn" {
  value       = var.enable_analytics ? module.analytics[0].s3_query_output_arn : ""
  description = "The full ARN to the location of the Athena query outputs (if enabled)."
}

output "analytics_s3_query_output_path" {
  value       = var.enable_analytics ? module.analytics[0].s3_query_output_path : ""
  description = "The path within the analytics bucket where the query results are stored (if enabled)."
}

output "analytics_glue_catalog_arn" {
  value       = var.enable_analytics ? module.analytics[0].glue_catalog_arn : ""
  description = "The ARN of the analytics glue catalog (if enabled)."
}

output "analytics_glue_database_name" {
  value       = var.enable_analytics ? module.analytics[0].glue_database_name : ""
  description = "The name of the glue database (if enabled)."
}

output "analytics_glue_database_arn" {
  value       = var.enable_analytics ? module.analytics[0].glue_database_arn : ""
  description = "The ARN of the analytics glue database (if enabled)."
}

output "analytics_athena_workgroup_name" {
  value       = var.enable_analytics ? module.analytics[0].athena_workgroup_name : ""
  description = "The name of the athena workgroup (if enabled)."
}

output "analytics_athena_workgroup_arn" {
  value       = var.enable_analytics ? module.analytics[0].athena_workgroup_arn : ""
  description = "The ARN of the athena workgroup (if enabled)."
}
