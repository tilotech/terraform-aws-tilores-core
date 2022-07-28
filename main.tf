module "api_gateway" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "~> 1.6"

  name          = format("%s-api", local.prefix)
  description   = "TiloRes API Gateway"
  protocol_type = "HTTP"

  create_api_domain_name = false

  integrations = {
    "POST /" = {
      lambda_arn             = module.lambda_api.lambda_function_arn
      payload_format_version = "1.0"
      authorization_type     = aws_apigatewayv2_authorizer.api_authorizer.authorizer_type == "REQUEST" ? "CUSTOM" : "JWT"
      authorizer_id          = aws_apigatewayv2_authorizer.api_authorizer.id
    }
  }
}

resource "aws_apigatewayv2_authorizer" "api_authorizer" {
  api_id           = module.api_gateway.apigatewayv2_api_id
  authorizer_type  = var.authorizer_type
  identity_sources = ["$request.header.Authorization"]
  name             = format("%s-%s-authorizer", local.prefix, var.authorizer_type)

  jwt_configuration {
    audience = var.authorizer_audience
    issuer   = var.authorizer_issuer_url
  }

  // Lambda Authorizer
  authorizer_credentials_arn        = var.authorizer_credentials_arn
  authorizer_payload_format_version = var.authorizer_payload_format_version
  authorizer_result_ttl_in_seconds  = var.authorizer_result_ttl_in_seconds
  authorizer_uri                    = var.authorizer_uri
  enable_simple_responses           = var.enable_simple_responses
  lifecycle {
    replace_triggered_by = [null_resource.force_replace_authorizer]
    create_before_destroy = true
  }
}

resource "null_resource" "force_replace_authorizer" {
  triggers = {
    authorizer_type = var.authorizer_type
  }
}

module "lambda_api" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 3.1"

  function_name = format("%s-api", local.prefix)
  description   = "TiloRes API"
  handler       = "api"
  runtime       = "provided.al2"
  timeout       = 30
  memory_size   = 1024
  architectures = ["arm64"]

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
    DISPATCHER_PLUGIN_PATH                = "/opt/plugin-dispatcher"
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
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 3.1"

  create_layer = true

  layer_name               = format("%s-dispatcher-plugin", local.prefix)
  description              = "TiloRes API Dispatcher Plugin"
  compatible_runtimes      = ["provided.al2"]
  compatible_architectures = ["arm64"]

  create_package = false
  s3_existing_package = {
    bucket     = data.aws_s3_object.dispatcher_plugin_artifact.bucket
    key        = data.aws_s3_object.dispatcher_plugin_artifact.key
    version_id = data.aws_s3_object.dispatcher_plugin_artifact.version_id
  }
}

module "lambda_layer_rule_config" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 3.1"

  create_layer = true

  layer_name               = format("%s-rule-config", local.prefix)
  description              = "Rule config json file"
  compatible_runtimes      = ["provided.al2"]
  compatible_architectures = ["arm64"]

  create_package         = false
  local_existing_package = var.rule_config_file
}
