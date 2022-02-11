locals {
  metric_filters = [
    {
      name           = "GraphQLErrors"
      pattern        = "[date, time, level=METRIC, metric_name=GraphQLErrors, metric_value]"
      value          = "$metric_value"
      namespace      = local.prefix
      log_group_name = module.lambda_api.lambda_cloudwatch_log_group_name
    }
  ]
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
  name = format("%s-send-usage-data", local.prefix)
  schedule_expression = "cron(5 * * * ? *)" // every hour at minute 5
}

resource "aws_cloudwatch_event_target" "send_usage_data" {
  rule = aws_cloudwatch_event_rule.send_usage_data.name
  arn = module.lambda_send_usage_data.lambda_function_arn
}