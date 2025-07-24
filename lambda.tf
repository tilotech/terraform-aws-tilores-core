locals {
  all_assemble_event_source_mapping = {
    sqs = var.assemble_parallelization_sqs == 0 ? null : {
      event_source_arn        = aws_sqs_queue.rawdata[0].arn
      batch_size              = 1
      function_response_types = ["ReportBatchItemFailures"]
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

  all_assemble_serial_event_source_mapping = {
    sqs = !var.enable_serial_assembly || var.rawdata_serial_stream_shard_count != 0 ? null : {
      event_source_arn        = aws_sqs_queue.rawdata_serial[0].arn
      batch_size              = 1
      function_response_types = ["ReportBatchItemFailures"]
      scaling_config = {
        maximum_concurrency = 2
      }
    }
    kinesis = !var.enable_serial_assembly || var.rawdata_serial_stream_shard_count == 0 ? null : {
      event_source_arn       = aws_kinesis_stream.kinesis_rawdata_serial_stream[0].arn
      starting_position      = "TRIM_HORIZON"
      batch_size             = 1
      parallelization_factor = 1
    }
  }
  assemble_serial_event_source_mapping = {
    for source, config in local.all_assemble_serial_event_source_mapping :
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

  environment_variables = merge(
    local.core_envs,
    var.enable_serial_assembly ? {
      SERIAL_RAW_DATA_STREAM_PROVIDER = var.entity_event_stream_shard_count == 0 ? "SQS" : "KINESIS"
      KINESIS_SERIAL_RAW_DATA_STREAM  = var.entity_event_stream_shard_count == 0 ? "" : aws_kinesis_stream.kinesis_rawdata_serial_stream[0].name
      SERIAL_RAW_DATA_SQS             = var.entity_event_stream_shard_count == 0 ? aws_sqs_queue.rawdata_serial[0].name : ""
      LOCKED_ENTITIES_CACHE_SIZE      = var.locked_entities_cache_size
      LOCKED_ENTITIES_CACHE_MAX_AGE   = var.locked_entities_cache_max_age
      LOCKED_ENTITIES_CACHE_THRESHOLD = var.locked_entities_cache_threshold
    } : {}
  )

  attach_policies = true
  policies = [
    aws_iam_policy.lambda_core.arn
  ]
  number_of_policies = 1

  event_source_mapping = local.assemble_event_source_mapping

  cloudwatch_logs_retention_in_days = var.cloudwatch_logs_retention_in_days
}

module "lambda_assemble_serial" {
  count = var.enable_serial_assembly ? 1 : 0

  source  = "terraform-aws-modules/lambda/aws"
  version = "7.2.1"

  function_name = format("%s-assemble-serial", local.prefix)
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

  environment_variables          = local.core_envs
  reserved_concurrent_executions = var.rawdata_serial_stream_shard_count == 0 ? 2 : 1 // limit to 1 entry for kinesis and 2 for sqs -> sqs max concurrency setting in the trigger cannot go below 2 and must be equal or higher than lambda reserved concurrency

  attach_policies = true
  policies = [
    aws_iam_policy.lambda_core.arn
  ]
  number_of_policies = 1

  event_source_mapping = local.assemble_serial_event_source_mapping

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
    DEAD_LETTER_QUEUE_URL     = aws_sqs_queue.scavenger_dead_letter_queue.id
    S3_ENTITIES_BUCKET        = aws_s3_bucket.entity.bucket
    S3_ANALYTICS_BUCKET       = var.enable_analytics ? module.analytics[0].bucket_name : ""
    S3_DELETE_DELAY           = var.enable_analytics ? "60" : ""
    S3_DELETE_DELAY_BUCKET    = var.enable_analytics ? aws_s3_bucket.execution_plan.bucket : ""
    S3_DELETE_DELAY_PREFIX    = var.enable_analytics ? "scavenger" : ""
    S3_DELETE_DELAY_META_FILE = var.enable_analytics ? "scavenger/meta.json" : ""
  }

  allowed_triggers = merge(
    {
      assemble = {
        principal  = format("logs.%s.amazonaws.com", data.aws_region.current.id)
        source_arn = format("%s:*", module.lambda_assemble.lambda_cloudwatch_log_group_arn)
      }
      remove_connection_ban = {
        principal  = format("logs.%s.amazonaws.com", data.aws_region.current.id)
        source_arn = format("%s:*", module.lambda_remove_connection_ban.lambda_cloudwatch_log_group_arn)
      }
    },
    var.enable_serial_assembly ? {
      assemble_serial = {
        principal  = format("logs.%s.amazonaws.com", data.aws_region.current.id)
        source_arn = format("%s:*", module.lambda_assemble_serial[0].lambda_cloudwatch_log_group_arn)
      }
    } : {}
  )

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
      },
      s3Scavenger = {
        effect = "Allow"
        actions = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        resources = [
          aws_s3_bucket.execution_plan.arn,
          format("%s/*", aws_s3_bucket.execution_plan.arn)
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

resource "aws_cloudwatch_log_subscription_filter" "assemble_serial_scavenger" {
  count           = var.enable_serial_assembly ? 1 : 0
  destination_arn = module.lambda_scavenger.lambda_function_arn
  filter_pattern  = "\"REMOVE-GARBAGE\""
  log_group_name  = module.lambda_assemble_serial[0].lambda_cloudwatch_log_group_name
  name            = format("%s-%s", local.prefix, "assemble-serial-scavenger")
}

resource "aws_cloudwatch_log_subscription_filter" "remove_connection_ban_scavenger" {
  destination_arn = module.lambda_scavenger.lambda_function_arn
  filter_pattern  = "\"REMOVE-GARBAGE\""
  log_group_name  = module.lambda_remove_connection_ban.lambda_cloudwatch_log_group_name
  name            = format("%s-%s", local.prefix, "remove-connection-ban-scavenger")
}

resource "aws_scheduler_schedule" "scavenger" {
  count = var.enable_analytics ? 1 : 0

  name = format("%s-scavenger", local.prefix)

  flexible_time_window {
    mode = "OFF"
  }
  schedule_expression = "rate(5 minutes)"

  target {
    arn      = module.lambda_scavenger.lambda_function_arn
    role_arn = aws_iam_role.scavenger_schedule[0].arn
    input    = "{\"scheduled\":true}"

    retry_policy {
      maximum_retry_attempts = 0
    }
  }
}

resource "aws_iam_role" "scavenger_schedule" {
  count = var.enable_analytics ? 1 : 0
  name  = format("%s-scavenger-schedule", local.prefix)
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "scheduler.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition : {
          StringEquals : {
            "aws:SourceAccount" : data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "scavenger_schedule" {
  count  = var.enable_analytics ? 1 : 0
  name   = format("%s-scavenger-schedule", local.prefix)
  role   = aws_iam_role.scavenger_schedule[0].id
  policy = data.aws_iam_policy_document.scavenger_schedule[0].json
}

data "aws_iam_policy_document" "scavenger_schedule" {
  count = var.enable_analytics ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = [
      module.lambda_scavenger.lambda_function_arn
    ]
  }
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
