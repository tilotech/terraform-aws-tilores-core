# Plans the whole module with the AWS and time providers mocked, so the test
# needs no AWS access. Run with `terraform init && terraform test` (Terraform
# 1.11 or newer, for override_during).

mock_provider "aws" {
  # The provider checks policy JSON even when it is mocked.
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  # The ARNs of the data stores and functions are known during the plan, so
  # that the policies of the functions can be checked for wildcard resources.
  mock_resource "aws_s3_bucket" {
    override_during = plan
    defaults = {
      arn = "arn:aws:s3:::test-tilores-bucket"
    }
  }
  mock_resource "aws_dynamodb_table" {
    override_during = plan
    defaults = {
      arn = "arn:aws:dynamodb:eu-central-1:123456789012:table/test-tilores-table"
    }
  }
  mock_resource "aws_sqs_queue" {
    override_during = plan
    defaults = {
      arn = "arn:aws:sqs:eu-central-1:123456789012:test-tilores-queue"
    }
  }
  mock_resource "aws_kinesis_stream" {
    override_during = plan
    defaults = {
      arn = "arn:aws:kinesis:eu-central-1:123456789012:stream/test-tilores-stream"
    }
  }
  mock_resource "aws_lambda_function" {
    override_during = plan
    defaults = {
      arn = "arn:aws:lambda:eu-central-1:123456789012:function:test-tilores-function"
    }
  }
}
mock_provider "time" {}

variables {
  resource_prefix  = "test"
  api_file         = "not-used-api.zip"
  rule_config_file = "not-used-rule-config.zip"
}

run "instance_with_every_option_plans" {
  command = plan

  variables {
    enable_analytics         = true
    enable_review            = true
    enable_serial_assembly   = true
    create_entity_stream     = true
    enable_entity_stream_api = true
  }

  assert {
    condition = alltrue(flatten([
      [
        for b in [aws_s3_bucket_public_access_block.entity, aws_s3_bucket_public_access_block.execution_plan] :
        b.block_public_acls && b.block_public_policy && b.ignore_public_acls && b.restrict_public_buckets
      ],
      [
        for c in [aws_s3_bucket_server_side_encryption_configuration.entity, aws_s3_bucket_server_side_encryption_configuration.execution_plan] :
        length(c.rule) > 0 && alltrue([for r in c.rule : one(r.apply_server_side_encryption_by_default).sse_algorithm == "aws:kms"])
      ],
    ]))
    error_message = "The entity and execution plan buckets must block every kind of public access and encrypt with KMS."
  }

  assert {
    condition = alltrue(flatten([
      [
        for q in concat([aws_sqs_queue.dead_letter_queue, aws_sqs_queue.scavenger_dead_letter_queue], aws_sqs_queue.rawdata, aws_sqs_queue.rawdata_serial, aws_sqs_queue.entity_stream) :
        q.kms_master_key_id == "alias/aws/sqs"
      ],
      [
        for t in concat([aws_dynamodb_table.entities, aws_dynamodb_table.records, aws_dynamodb_table.rule_index, aws_dynamodb_table.rule_reverse_index], aws_dynamodb_table.review_cases, aws_dynamodb_table.review_decisions) :
        one(t.server_side_encryption).enabled
      ],
    ]))
    error_message = "Every queue and every table must be encrypted at rest with KMS."
  }

  assert {
    condition = alltrue([
      for name in concat(
        [aws_s3_bucket.entity.bucket, aws_s3_bucket.execution_plan.bucket, aws_iam_policy.lambda_core.name, aws_iam_policy.lambda_send_usage_data.name],
        [for t in concat([aws_dynamodb_table.entities, aws_dynamodb_table.records, aws_dynamodb_table.rule_index, aws_dynamodb_table.rule_reverse_index], aws_dynamodb_table.review_cases, aws_dynamodb_table.review_decisions) : t.name],
        [for q in concat([aws_sqs_queue.dead_letter_queue, aws_sqs_queue.scavenger_dead_letter_queue], aws_sqs_queue.rawdata, aws_sqs_queue.rawdata_serial, aws_sqs_queue.entity_stream) : q.name],
        [for g in concat([aws_cloudwatch_log_group.lambda_api, aws_cloudwatch_log_group.lambda_assemble, aws_cloudwatch_log_group.lambda_remove_connection_ban, aws_cloudwatch_log_group.lambda_scavenger, aws_cloudwatch_log_group.lambda_send_usage_data], aws_cloudwatch_log_group.lambda_assemble_serial) : trimprefix(g.name, "/aws/lambda/")],
      ) : startswith(name, "test-tilores-")
    ])
    error_message = "Every bucket, table, queue, log group and policy must be named after the resource prefix, so that several instances fit into one AWS account."
  }

  assert {
    condition = alltrue(flatten([
      for doc in concat([data.aws_iam_policy_document.lambda_core, data.aws_iam_policy_document.lambda_send_usage_data], data.aws_iam_policy_document.scavenger_schedule) : [
        for s in doc.statement : concat(
          [for a in s.actions : can(regex("^(s3|dynamodb|kinesis|sqs|cloudwatch|logs|lambda):[A-Za-z]+$", a))],
          # A wildcard resource only for the actions that cannot be limited to a resource.
          [contains(s.resources, "*") ? length(setsubtract(s.actions, ["kinesis:ListStreams", "cloudwatch:GetMetricData", "cloudwatch:PutMetricData"])) == 0 : true],
        )
      ]
    ]))
    error_message = "The function policies may only name single S3, DynamoDB, Kinesis, SQS, CloudWatch, Logs and Lambda actions, and use a wildcard resource only for listing streams and for metrics."
  }
}

run "defaults_create_no_optional_parts" {
  command = plan

  assert {
    condition = (
      output.analytics_bucket_name == "" && length(aws_scheduler_schedule.scavenger) == 0
      && output.table_review_cases_name == "" && output.table_review_decisions_name == ""
      && length(aws_sqs_queue.rawdata_serial) == 0
      && length(aws_sqs_queue.entity_stream) == 0 && length(aws_kinesis_stream.kinesis_entity_stream) == 0
      && run.instance_with_every_option_plans.analytics_bucket_name == "test-tilores-analytics"
      && run.instance_with_every_option_plans.table_review_cases_name == "test-tilores-review-cases"
      && run.instance_with_every_option_plans.core_environment_variables["SQS_ENTITY_STREAM"] == "test-tilores-entity-stream"
    )
    error_message = "Analytics, review tables, serial assembly and the entity stream must exist only when their option is turned on."
  }
}
