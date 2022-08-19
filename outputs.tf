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
