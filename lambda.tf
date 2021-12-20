locals {
  assemble_artifact_key              = format("tilotech/tilores-core/%s/assemble.zip", var.core_version)
  disassemble_artifact_key           = format("tilotech/tilores-core/%s/disassemble.zip", var.core_version)
  remove_connection_ban_artifact_key = format("tilotech/tilores-core/%s/remove-connection-ban.zip", var.core_version)
  scavenger_artifact_key             = format("tilotech/func-scavenger/%s/scavenger.zip", var.scavenger_version)
}

module "lambda_assemble" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = format("%s-assemble", local.prefix)
  handler       = "assemble"
  runtime       = "go1.x"
  timeout       = 900

  create_package = false

  s3_existing_package = {
    bucket = local.artifacts_bucket
    key    = local.assemble_artifact_key
  }

  environment_variables = local.core_envs

  attach_policies = true
  policies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess",
    aws_iam_policy.lambda_core.arn
  ]
  number_of_policies = 3

  event_source_mapping = {
    kinesis = {
      event_source_arn       = aws_kinesis_stream.kinesis_rawdata_stream.arn
      starting_position      = "TRIM_HORIZON"
      batch_size             = 1
      parallelization_factor = var.assemble_parallelization_factor
    }
  }
}

module "lambda_disassemble" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = format("%s-disassemble", local.prefix)
  handler       = "disassemble"
  runtime       = "go1.x"
  timeout       = 900

  dead_letter_target_arn = aws_sqs_queue.dead_letter_queue.arn

  create_package = false

  s3_existing_package = {
    bucket = local.artifacts_bucket
    key    = local.disassemble_artifact_key
  }

  environment_variables = local.core_envs

  attach_policies = true
  policies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess",
    aws_iam_policy.lambda_core.arn
  ]
  number_of_policies = 3
}

module "lambda_remove_connection_ban" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = format("%s-remove-connection-ban", local.prefix)
  handler       = "removeconnectionban"
  runtime       = "go1.x"
  timeout       = 900

  create_package = false

  s3_existing_package = {
    bucket = local.artifacts_bucket
    key    = local.remove_connection_ban_artifact_key
  }

  environment_variables = local.core_envs

  attach_policies = true
  policies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess",
    aws_iam_policy.lambda_core.arn
  ]
  number_of_policies = 3
}

module "lambda_scavenger" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = format("%s-scavenger", local.prefix)
  handler       = "scavenger"
  runtime       = "go1.x"
  timeout       = 900

  create_package = false

  s3_existing_package = {
    bucket = local.artifacts_bucket
    key    = local.scavenger_artifact_key
  }

  environment_variables = {
    DEAD_LETTER_QUEUE_URL = aws_sqs_queue.scavenger_dead_letter_queue.id
  }

  allowed_triggers = {
    assemble = {
      principal  = format("logs.%s.amazonaws.com", data.aws_region.current)
      source_arn = format("%s:*", module.lambda_assemble.lambda_cloudwatch_log_group_arn)
    }
    disassemble = {
      principal  = format("logs.%s.amazonaws.com", data.aws_region.current)
      source_arn = format("%s:*", module.lambda_disassemble.lambda_cloudwatch_log_group_arn)
    }
    remove_connection_ban = {
      principal  = format("logs.%s.amazonaws.com", data.aws_region.current)
      source_arn = format("%s:*", module.lambda_remove_connection_ban.lambda_cloudwatch_log_group_arn)
    }
  }

  create_current_version_allowed_triggers = false

  attach_policies = true
  policies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
  ]
  number_of_policies = 2

  attach_policy_statements = true
  policy_statements = {
    s3 = {
      effect = "Allow"
      actions = [
        "s3:DeleteObject"
      ]
      resources = [
        format("%s/*", aws_s3_bucket.entity.arn),
        format("%s/*", aws_s3_bucket.execution_plan.arn)
      ]
    },
    sqs = {
      effect    = "Allow"
      actions   = ["sqs:SendMessage"]
      resources = [aws_sqs_queue.scavenger_dead_letter_queue.arn]
    }
  }
}

resource "aws_cloudwatch_log_subscription_filter" "assemble_scavenger" {
  destination_arn = module.lambda_scavenger.lambda_function_arn
  filter_pattern  = "\"REMOVE-GARBAGE\""
  log_group_name  = module.lambda_assemble.lambda_cloudwatch_log_group_name
  name            = format("%s-%s", local.prefix, "assemble-scavenger")
}

resource "aws_cloudwatch_log_subscription_filter" "disassemble_scavenger" {
  destination_arn = module.lambda_scavenger.lambda_function_arn
  filter_pattern  = "\"REMOVE-GARBAGE\""
  log_group_name  = module.lambda_disassemble.lambda_cloudwatch_log_group_name
  name            = format("%s-%s", local.prefix, "disassemble-scavenger")
}

resource "aws_cloudwatch_log_subscription_filter" "remove_connection_ban_scavenger" {
  destination_arn = module.lambda_scavenger.lambda_function_arn
  filter_pattern  = "\"REMOVE-GARBAGE\""
  log_group_name  = module.lambda_remove_connection_ban.lambda_cloudwatch_log_group_name
  name            = format("%s-%s", local.prefix, "remove-connection-ban-scavenger")
}