locals {
  resources_granted_to_lambda = compact(
    [
      aws_dynamodb_table.entities.arn,
      aws_dynamodb_table.records.arn,
      aws_dynamodb_table.rule_index.arn,
      aws_dynamodb_table.rule_reverse_index.arn,
      var.rawdata_stream_shard_count == 0 ? "" : aws_kinesis_stream.kinesis_rawdata_stream[0].arn,
      var.assemble_parallelization_sqs == 0 ? "" : aws_sqs_queue.rawdata[0].arn,
      local.create_entity_stream_kinesis ? aws_kinesis_stream.kinesis_entity_stream[0].arn : "",
      local.create_entity_stream_sqs ? aws_sqs_queue.entity_stream[0].arn : "",
      aws_sqs_queue.dead_letter_queue.arn,
    ]
  )
}

resource "aws_iam_policy" "lambda_core" {
  name   = format("%s-%s-%s", local.prefix, "lambda", "core")
  policy = data.aws_iam_policy_document.lambda_core.json
}

data "aws_iam_policy_document" "lambda_core" {
  statement {
    effect  = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:AbortMultipartUpload",
      "s3:ListBucketMultipartUploads",
      "s3:DeleteObject"
    ]
    resources = [
      aws_s3_bucket.entity.arn,
      aws_s3_bucket.execution_plan.arn,
      format("%s/*", aws_s3_bucket.entity.arn),
      format("%s/*", aws_s3_bucket.execution_plan.arn),
    ]
  }
  statement {
    effect  = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:BatchGetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "kinesis:GetShardIterator",
      "kinesis:DescribeStream",
      "kinesis:GetRecords",
      "kinesis:PutRecords",
      "sqs:SendMessage",
      "sqs:GetQueueUrl",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]
    resources = local.resources_granted_to_lambda
  }
  statement {
    effect  = "Allow"
    actions = [
      "kinesis:ListStreams",
      "cloudwatch:PutMetricData"
    ]
    resources = ["*"]
  }
  statement {
    effect  = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:${data.aws_region.current.id}:*:log-group:/aws/lambda/${local.prefix}-*"]
  }
}

resource "aws_iam_policy" "lambda_send_usage_data" {
  name   = format("%s-lambda-send-usage-data", local.prefix)
  policy = data.aws_iam_policy_document.lambda_send_usage_data.json
}

data "aws_iam_policy_document" "lambda_send_usage_data" {
  statement {
    effect  = "Allow"
    actions = [
      "cloudwatch:GetMetricData",
      "cloudwatch:PutMetricData"
    ]
    resources = ["*"]
  }
  statement {
    effect  = "Allow"
    actions = [
      "dynamodb:DescribeTable"
    ]
    resources = [
      aws_dynamodb_table.entities.arn,
      aws_dynamodb_table.records.arn
    ]
  }
}
