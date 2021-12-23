locals {
  metric_filters = [
    {
      name           = "EntityReport"
      pattern        = "[date, time, level=METRIC, metric_name=EntityReport, metric_value]"
      value          = "$metric_value"
      namespace      = local.prefix
      log_group_name = module.lambda_assemble.lambda_cloudwatch_log_group_name
    },
    {
      name           = "EntityReport"
      pattern        = "[date, time, level=METRIC, metric_name=EntityReport, metric_value]"
      value          = "$metric_value"
      namespace      = local.prefix
      log_group_name = module.lambda_disassemble.lambda_cloudwatch_log_group_name
    },
    {
      name           = "GraphQLErrors"
      pattern        = "[date, time, level=METRIC, metric_name=GraphQLErrors, metric_value]"
      value          = "$metric_value"
      namespace      = local.prefix
      log_group_name = module.lambda_api.lambda_cloudwatch_log_group_name
    }
  ]
}

resource "aws_cloudwatch_dashboard" "entity_report" {
  dashboard_body = templatefile(format("%s/dashboards/entity-report.json", path.module), { NAMESPACE = local.prefix })
  dashboard_name = "entity-report"
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