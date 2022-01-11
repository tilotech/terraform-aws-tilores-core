module "api_gateway" {
  source = "terraform-aws-modules/apigateway-v2/aws"

  name          = format("%s-api", local.prefix)
  description   = "TiloRes API Gateway"
  protocol_type = "HTTP"

  create_api_domain_name = false

  integrations = {
    "POST /" = {
      lambda_arn             = module.lambda_api.lambda_function_arn
      payload_format_version = "1.0"
      authorization_type     = "JWT"
      authorizer_id          = aws_apigatewayv2_authorizer.api_authorizer.id
    }
  }
}

resource "aws_apigatewayv2_authorizer" "api_authorizer" {
  api_id           = module.api_gateway.apigatewayv2_api_id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = format("%s-authorizer", local.prefix)

  jwt_configuration {
    audience = var.authorizer_audience
    issuer   = var.authorizer_issuer_url
  }
}

module "lambda_api" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = format("%s-api", local.prefix)
  description   = "TiloRes API"
  handler       = "api"
  runtime       = "go1.x"
  timeout       = 30

  create_package         = false
  local_existing_package = var.api_file

  layers = [
    module.lambda_layer_dispatcher_plugin.lambda_layer_arn,
    module.lambda_layer_rule_config.lambda_layer_arn,
  ]

  allowed_triggers = {
    APIGateway = {
      service    = "apigateway"
      source_arn = format("%s/*/*/*", module.api_gateway.apigatewayv2_api_execution_arn)
    }
  }
  create_current_version_allowed_triggers = false

  environment_variables = merge(local.core_envs, {
    DISPATCHER_PLUGIN_PATH                = "/opt/dispatcher"
    CORE_LAMBDA_DISASSEMBLE_ARN           = module.lambda_disassemble.lambda_function_arn
    CORE_LAMBDA_REMOVE_CONNECTION_BAN_ARN = module.lambda_remove_connection_ban.lambda_function_arn
  })

  attach_policy = true
  policy        = aws_iam_policy.lambda_core.arn

  attach_policy_statements = true
  policy_statements = {
    lambda = {
      effect  = "Allow",
      actions = ["lambda:InvokeFunction"]
      resources = [
        module.lambda_disassemble.lambda_function_arn,
        module.lambda_remove_connection_ban.lambda_function_arn
      ]
    }
  }
}

module "lambda_layer_dispatcher_plugin" {
  source = "terraform-aws-modules/lambda/aws"

  create_layer = true

  layer_name          = format("%s-dispatcher-plugin", local.prefix)
  description         = "TiloRes API Dispatcher Plugin"
  compatible_runtimes = ["go1.x"]

  create_package = false
  s3_existing_package = {
    bucket     = data.aws_s3_bucket_object.dispatcher_plugin_artifact.bucket
    key        = data.aws_s3_bucket_object.dispatcher_plugin_artifact.key
    version_id = data.aws_s3_bucket_object.dispatcher_plugin_artifact.version_id
  }
}

module "lambda_layer_rule_config" {
  source = "terraform-aws-modules/lambda/aws"

  create_layer = true

  layer_name          = format("%s-rule-config", local.prefix)
  description         = "Rule config json file"
  compatible_runtimes = ["go1.x"]

  create_package         = false
  local_existing_package = var.rule_config_file
}