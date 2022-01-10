resource "aws_iam_policy" "lambda_core" {
  name   = format("%s-%s-%s", local.prefix, "lambda", "core")
  policy = data.aws_iam_policy_document.lambda_core.json
}

data "aws_iam_policy_document" "lambda_core" {
  statement {
    effect = "Allow"
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
    effect = "Allow"
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
      "sqs:GetQueueUrl"
    ]
    resources = [
      aws_dynamodb_table.entites.arn,
      aws_dynamodb_table.records.arn,
      aws_dynamodb_table.rule_index.arn,
      aws_dynamodb_table.rule_reverse_index.arn,
      aws_kinesis_stream.kinesis_rawdata_stream.arn,
      aws_kinesis_stream.kinesis_entity_stream.arn,
      aws_sqs_queue.dead_letter_queue.arn,
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "kinesis:ListStreams",
      "cloudwatch:PutMetricData"
    ]
    resources = ["*"]
  }
}