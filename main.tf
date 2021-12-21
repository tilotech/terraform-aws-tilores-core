locals {
  dispatcher_plugin_artifact_key = format("tilotech/tilores-plugin-dispatcher/%s/tilores-plugin-dispatcher.zip", var.dispatcher_plugin_version)
}

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
    }
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
  ]

  allowed_triggers = {
    APIGateway = {
      service    = "apigateway"
      source_arn = format("%s/*/*/*", module.api_gateway.apigatewayv2_api_execution_arn)
    }
  }
  create_current_version_allowed_triggers = false

  environment_variables = merge(local.core_envs, { // TODO: Adjust according to new dispatcher
    IR_LAMBDA_DISASSEMBLE_ARN           = module.lambda_disassemble.lambda_function_arn
    IR_LAMBDA_REMOVE_CONNECTION_BAN_ARN = module.lambda_remove_connection_ban.lambda_function_arn
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
    bucket = local.artifacts_bucket
    key    = local.dispatcher_plugin_artifact_key
  }
}