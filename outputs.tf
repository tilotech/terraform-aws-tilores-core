output "api_url" {
  value       = module.api_gateway.apigatewayv2_api_api_endpoint
  description = "The endpoint URL of the GraphQL API."
}
