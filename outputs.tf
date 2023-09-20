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
  value = module.lambda_layer_rule_config.lambda_layer_arn
  description = "The lambda layer ARN holding the config"
}

output "entity_bucket_name" {
  value       = aws_s3_bucket.entity.id
  description = "The name of the bucket holding the entities"
}

output "entity_bucket_arn" {
  value       = aws_s3_bucket.entity.arn
  description = "The ARN of the bucket holding the entities"
}

output "entity_stream_arn" {
  value       = var.entity_event_stream_shard_count == 0 ? "" : aws_kinesis_stream.kinesis_entity_stream[0].arn
  description = "The ARN of the entity stream"
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