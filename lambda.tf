locals {
  all_assemble_event_source_mapping = {
    sqs = var.assemble_parallelization_sqs == 0 ? null : {
      event_source_arn = aws_sqs_queue.rawdata[0].arn
      batch_size       = 1
      scaling_config = {
        maximum_concurrency = var.assemble_parallelization_sqs
      }
    }
    kinesis = var.rawdata_stream_shard_count == 0 ? null : {
      event_source_arn       = aws_kinesis_stream.kinesis_rawdata_stream[0].arn
      starting_position      = "TRIM_HORIZON"
      batch_size             = 1
      parallelization_factor = var.assemble_parallelization_factor
    }
  }
  assemble_event_source_mapping = {
    for source, config in local.all_assemble_event_source_mapping :
    source => config if config != null
  }
}

module "lambda_assemble" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.2.1"

  function_name = format("%s-assemble", local.prefix)
  handler       = "assemble"
  runtime       = "provided.al2"
  timeout       = 900
  memory_size   = 1024
  architectures = ["arm64"]

  create_package = false

  s3_existing_package = {
    bucket     = data.aws_s3_object.assemble_artifact.bucket
    key        = data.aws_s3_object.assemble_artifact.key
    version_id = data.aws_s3_object.assemble_artifact.version_id
  }

  layers = [
    module.lambda_layer_rule_config.lambda_layer_arn,
  ]

  environment_variables = local.core_envs

  attach_policies = true
  policies = [
    aws_iam_policy.lambda_core.arn
  ]
  number_of_policies = 1

  event_source_mapping = local.assemble_event_source_mapping

  cloudwatch_logs_retention_in_days = var.cloudwatch_logs_retention_in_days
}

module "lambda_remove_connection_ban" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.2.1"

  function_name = format("%s-remove-connection-ban", local.prefix)
  handler       = "removeconnectionban"
  runtime       = "provided.al2"
  timeout       = 900
  memory_size   = 1024
  architectures = ["arm64"]

  create_package = false

  s3_existing_package = {
    bucket     = data.aws_s3_object.remove_connection_ban_artifact.bucket
    key        = data.aws_s3_object.remove_connection_ban_artifact.key
    version_id = data.aws_s3_object.remove_connection_ban_artifact.version_id
  }

  layers = [
    module.lambda_layer_rule_config.lambda_layer_arn,
  ]

  environment_variables = local.core_envs

  attach_policies = true
  policies = [
    aws_iam_policy.lambda_core.arn
  ]
  number_of_policies = 1

  cloudwatch_logs_retention_in_days = var.cloudwatch_logs_retention_in_days
}

module "lambda_scavenger" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.2.1"

  function_name = format("%s-scavenger", local.prefix)
  handler       = "scavenger"
  runtime       = "provided.al2"
  timeout       = 900
  memory_size   = 1024
  architectures = ["arm64"]

  create_package = false

  s3_existing_package = {
    bucket     = data.aws_s3_object.scavenger_artifact.bucket
    key        = data.aws_s3_object.scavenger_artifact.key
    version_id = data.aws_s3_object.scavenger_artifact.version_id
  }

  environment_variables = {
    DEAD_LETTER_QUEUE_URL = aws_sqs_queue.scavenger_dead_letter_queue.id
    S3_ANALYTICS_BUCKET   = var.enable_analytics ? module.analytics[0].bucket_name : ""
  }

  allowed_triggers = {
    assemble = {
      principal  = format("logs.%s.amazonaws.com", data.aws_region.current.id)
      source_arn = format("%s:*", module.lambda_assemble.lambda_cloudwatch_log_group_arn)
    }
    remove_connection_ban = {
      principal  = format("logs.%s.amazonaws.com", data.aws_region.current.id)
      source_arn = format("%s:*", module.lambda_remove_connection_ban.lambda_cloudwatch_log_group_arn)
    }
  }

  create_current_version_allowed_triggers = false

  attach_policy_statements = true
  policy_statements = merge(
    {
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
      cloudwatch = {
        effect = "Allow"
        actions = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        resources = ["arn:aws:logs:${data.aws_region.current.id}:*:log-group:/aws/lambda/${local.prefix}-scavenger"]
      }
    },
    var.enable_analytics ? {
      s3Analytics = {
        effect = "Allow"
        actions = [
          "s3:PutObject"
        ]
        resources = [
          "${module.analytics[0].s3_entities_snapshot_arn}/*",
          "${module.analytics[0].s3_records_snapshot_arn}/*"
        ]
      }
    } : {}
  )

  cloudwatch_logs_retention_in_days = var.cloudwatch_logs_retention_in_days
}

resource "aws_cloudwatch_log_subscription_filter" "assemble_scavenger" {
  destination_arn = module.lambda_scavenger.lambda_function_arn
  filter_pattern  = "\"REMOVE-GARBAGE\""
  log_group_name  = module.lambda_assemble.lambda_cloudwatch_log_group_name
  name            = format("%s-%s", local.prefix, "assemble-scavenger")
}

resource "aws_cloudwatch_log_subscription_filter" "remove_connection_ban_scavenger" {
  destination_arn = module.lambda_scavenger.lambda_function_arn
  filter_pattern  = "\"REMOVE-GARBAGE\""
  log_group_name  = module.lambda_remove_connection_ban.lambda_cloudwatch_log_group_name
  name            = format("%s-%s", local.prefix, "remove-connection-ban-scavenger")
}

module "lambda_send_usage_data" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.2.1"

  function_name = format("%s-send-usage-data", local.prefix)
  handler       = "send"
  runtime       = "provided.al2"
  timeout       = 900
  memory_size   = 1024
  architectures = ["arm64"]

  create_package = false

  s3_existing_package = {
    bucket     = data.aws_s3_object.customer_metrics_artifact.bucket
    key        = data.aws_s3_object.customer_metrics_artifact.key
    version_id = data.aws_s3_object.customer_metrics_artifact.version_id
  }

  environment_variables = {
    TABLE_ENTITIES        = aws_dynamodb_table.entities.id
    TABLE_RECORDS         = aws_dynamodb_table.records.id
    STREAM_RAW_DATA       = var.rawdata_stream_shard_count == 0 ? "" : aws_kinesis_stream.kinesis_rawdata_stream[0].name
    QUEUE_RAW_DATA        = var.assemble_parallelization_sqs == 0 ? "" : aws_sqs_queue.rawdata[0].name
    FUNCTION_API          = module.lambda_api.lambda_function_name
    FUNCTION_ASSEMBLE     = module.lambda_assemble.lambda_function_name
    TILOTECH_API_URL      = local.tilotech_api_url
    TILORES_INSTANCE_NAME = local.prefix
    STORE_LOCAL_METRICS   = var.create_dashboard ? "TRUE" : "FALSE"
  }

  allowed_triggers = {
    CloudWatchRule = {
      principal  = "events.amazonaws.com"
      source_arn = aws_cloudwatch_event_rule.send_usage_data.arn
    }
  }
  create_current_version_allowed_triggers = false

  attach_policies = true
  policies = [
    aws_iam_policy.lambda_send_usage_data.arn
  ]
  number_of_policies = 1

  cloudwatch_logs_retention_in_days = var.cloudwatch_logs_retention_in_days
}

resource "aws_lambda_function_event_invoke_config" "send_usage_data" {
  function_name          = module.lambda_send_usage_data.lambda_function_name
  maximum_retry_attempts = 0
}
