locals {
  metric_filters = [
    {
      name           = "GraphQLErrors"
      pattern        = "[date, time, level=METRIC, metric_name=GraphQLErrors, metric_value]"
      value          = "$metric_value"
      namespace      = local.prefix
      log_group_name = aws_cloudwatch_log_group.lambda_api.name
    }
  ]
}

// Moved blocks to migrate log groups from Lambda modules to explicit resources
// These prevent destruction/recreation of existing log groups during migration

moved {
  from = module.lambda_api.aws_cloudwatch_log_group.lambda[0]
  to   = aws_cloudwatch_log_group.lambda_api
}

moved {
  from = module.lambda_assemble.aws_cloudwatch_log_group.lambda[0]
  to   = aws_cloudwatch_log_group.lambda_assemble
}

moved {
  from = module.lambda_assemble_serial[0].aws_cloudwatch_log_group.lambda[0]
  to   = aws_cloudwatch_log_group.lambda_assemble_serial[0]
}

moved {
  from = module.lambda_remove_connection_ban.aws_cloudwatch_log_group.lambda[0]
  to   = aws_cloudwatch_log_group.lambda_remove_connection_ban
}

moved {
  from = module.lambda_scavenger.aws_cloudwatch_log_group.lambda[0]
  to   = aws_cloudwatch_log_group.lambda_scavenger
}

moved {
  from = module.lambda_send_usage_data.aws_cloudwatch_log_group.lambda[0]
  to   = aws_cloudwatch_log_group.lambda_send_usage_data
}

resource "aws_cloudwatch_log_group" "lambda_api" {
  name              = "/aws/lambda/${local.prefix}-api"
  retention_in_days = var.cloudwatch_logs_retention_in_days
}

resource "aws_cloudwatch_log_group" "lambda_assemble" {
  name              = "/aws/lambda/${local.prefix}-assemble"
  retention_in_days = var.cloudwatch_logs_retention_in_days
}

resource "aws_cloudwatch_log_group" "lambda_assemble_serial" {
  count = var.enable_serial_assembly ? 1 : 0

  name              = "/aws/lambda/${local.prefix}-assemble-serial"
  retention_in_days = var.cloudwatch_logs_retention_in_days
}

resource "aws_cloudwatch_log_group" "lambda_remove_connection_ban" {
  name              = "/aws/lambda/${local.prefix}-remove-connection-ban"
  retention_in_days = var.cloudwatch_logs_retention_in_days
}

resource "aws_cloudwatch_log_group" "lambda_scavenger" {
  name              = "/aws/lambda/${local.prefix}-scavenger"
  retention_in_days = var.cloudwatch_logs_retention_in_days
}

resource "aws_cloudwatch_log_group" "lambda_send_usage_data" {
  name              = "/aws/lambda/${local.prefix}-send-usage-data"
  retention_in_days = var.cloudwatch_logs_retention_in_days
}

resource "aws_cloudwatch_log_metric_filter" "metric_filters" {
  count = length(local.metric_filters)

  name           = local.metric_filters[count.index].name
  pattern        = local.metric_filters[count.index].pattern
  log_group_name = local.metric_filters[count.index].log_group_name

  metric_transformation {
    name      = local.metric_filters[count.index].name
    namespace = local.metric_filters[count.index].namespace
    value     = local.metric_filters[count.index].value
  }
}

resource "aws_cloudwatch_event_rule" "send_usage_data" {
  name                = format("%s-send-usage-data", local.prefix)
  schedule_expression = "cron(5 * * * ? *)" // every hour at minute 5
}

resource "aws_cloudwatch_event_target" "send_usage_data" {
  rule = aws_cloudwatch_event_rule.send_usage_data.name
  arn  = module.lambda_send_usage_data.lambda_function_arn
}

resource "aws_cloudwatch_dashboard" "tilores_dashboard" {
  count = var.create_dashboard ? 1 : 0
  dashboard_body = templatefile(format("%s/tilores-dashboard.json", path.module), {
    PREFIX = local.prefix
    REGION = data.aws_region.current.id
  })
  dashboard_name = format("%s-dashboard", local.prefix)
}
