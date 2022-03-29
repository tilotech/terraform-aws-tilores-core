output "api_url" {
  value       = module.api_gateway.apigatewayv2_api_api_endpoint
  description = "The endpoint URL of the GraphQL API."
}

output "api_default_stage_id" {
  value = module.api_gateway.default_apigatewayv2_stage_id
  description = "The default stage ID of the GraphQL API."
}

output "api_id" {
  value = module.api_gateway.apigatewayv2_api_id
  description = "The ID of the GraphQL API."
}