resource "aws_s3_bucket" "analytics" {
  bucket        = format("%s-analytics", var.prefix)
  force_destroy = true

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "analytics" {
  bucket = aws_s3_bucket.analytics.id

  rule {
    id     = "cleanup"
    status = "Enabled"
    filter {}
    expiration {
      expired_object_delete_marker = true
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "analytics" {
  bucket = aws_s3_bucket.analytics.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "analytics" {
  bucket = aws_s3_bucket.analytics.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_athena_workgroup" "analytics" {
  name          = var.prefix
  force_destroy = true
  configuration {
    engine_version {
      selected_engine_version = "Athena engine version 3"
    }
    result_configuration {
      output_location = format("s3://%s/%s", aws_s3_bucket.analytics.id, local.query_output_path)
    }
  }
}

resource "aws_glue_catalog_database" "analytics" {
  name        = var.prefix
  description = "contains all relevant tables for analyzing the Tilores data"
}

resource "aws_glue_catalog_table" "entities_operational" {
  database_name = aws_glue_catalog_database.analytics.name
  name          = "entities_operational"
  description   = "contains the operational data from tilores, partitioned in 5 minute timeframes"
  parameters = {
    classification = "json"
  }
  table_type = "EXTERNAL_TABLE"

  storage_descriptor {
    location      = format("s3://%s/", var.entity_s3_bucket_id)
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"
    ser_de_info {
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
      parameters = {
        "case.insensitive"           = "FALSE",
        "mapping.record_ids"         = "recordIDs",
        "mapping.submit_timestamp"   = "submitTimestamp"
        "mapping.assemble_timestamp" = "assembleTimestamp"
        "mapping.create_timestamp"   = "createTimestamp"
        "mapping.update_timestamp"   = "updateTimestamp"
        "dots.in.keys"               = "FALSE",
        "ignore.malformed.json"      = "TRUE"
      }
    }

    columns {
      name    = "type"
      type    = "string"
      comment = "the storage type of the entity header; valid for: header row"
    }
    columns {
      name    = "record_ids"
      type    = "array<string>"
      comment = "list of entity record ids; valid for: header row, requires type elist"
    }
    columns {
      name    = "nodes"
      type    = "array<string>"
      comment = "list of entity record ids; valid for: header row, requires type cbgc"
    }
    columns {
      name    = "edges"
      type    = "string"
      comment = "type dependent edge representation; valid for: header row"
    }
    columns {
      name    = "cliques"
      type    = "map<string,array<struct<n:array<int>,p:string>>>"
      comment = "cliques of the edge graph; valid for: header row, requires type cbgc"
    }
    columns {
      name    = "duplicates"
      type    = "string"
      comment = "type dependent duplicate representation; valid for: header row"
    }
    columns {
      name    = "create_timestamp"
      type    = "string"
      comment = "timestamp of when an entity was created; valid for: header row"
    }
    columns {
      name    = "update_timestamp"
      type    = "string"
      comment = "timestamp of when an entity was updated; valid for: header row"
    }
    columns {
      name    = "id"
      type    = "string"
      comment = "record id, NOT the entity id; valid for: record rows"
    }
    columns {
      name    = "meta"
      type    = "struct<submit_timestamp:string,assemble_timestamp:string,version:int>"
      comment = "record meta data; valid for: record rows"
    }
    columns {
      name    = "data"
      type    = "string"
      comment = "json encoded record data; valid for: record rows"
    }
  }

  partition_keys {
    name    = "date"
    type    = "date"
    comment = "date (YYYY-MM-DD) for partitioning the operational entities into 5 minute timeframes of their latest update"
  }
  partition_keys {
    name    = "time"
    type    = "string"
    comment = "time (HH-MM) for partitioning the operational entities into 5 minute timeframes of their latest update"
  }
  partition_index {
    index_name = "timeframe_idx"
    keys       = ["date", "time"]
  }
}

resource "aws_glue_catalog_table" "entities_snapshots" {
  database_name = aws_glue_catalog_database.analytics.name
  name          = "entities_snapshots"
  description   = "append-only snapshots of the normalized and enriched header data of entities_operational"
  parameters = {
    classification = "json"
  }
  table_type = "EXTERNAL_TABLE"

  storage_descriptor {
    location      = format("s3://%s/entities_snapshots/", aws_s3_bucket.analytics.bucket)
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"
    ser_de_info {
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
      parameters = {
        "case.insensitive"      = "FALSE",
        "dots.in.keys"          = "FALSE",
        "ignore.malformed.json" = "TRUE"
      }
    }

    columns {
      name    = "entity_id"
      type    = "string"
      comment = "id of the entity"
    }
    columns {
      name    = "version"
      type    = "int"
      comment = "version of the entity"
    }
    columns {
      name    = "type"
      type    = "string"
      comment = "storage type hint for some of the fields (e.g. edges), either cbgc or elist"
    }
    columns {
      name    = "record_count"
      type    = "int"
      comment = "enriched number of records per entity"
    }
    columns {
      name    = "edge_count"
      type    = "int"
      comment = "enriched number of edges per entity"
    }
    columns {
      name    = "rule_edge_count"
      type    = "map<string,int>"
      comment = "enriched number of edges per rule"
    }
    columns {
      name    = "duplicate_count"
      type    = "int"
      comment = "number of duplicates per entity"
    }
    columns {
      name    = "clique_count"
      type    = "int"
      comment = "number of cliques per entity; always 0 if type equals elist"
    }
    columns {
      name    = "records"
      type    = "array<string>"
      comment = "list of all record IDs in this entity"
    }
    columns {
      name    = "edges"
      type    = "string"
      comment = "type dependent edge representation"
    }
    columns {
      name    = "duplicates"
      type    = "string"
      comment = "type dependent duplicate representation"
    }
    columns {
      name    = "cliques"
      type    = "map<string,array<struct<n:array<int>,p:string>>>"
      comment = "type dependent cliques representation; always null if type equals elist"
    }
    columns {
      name    = "data_location"
      type    = "string"
      comment = "data location of the entity header and record data in S3"
    }
    columns {
      name    = "create_timestamp"
      type    = "timestamp"
      comment = "timestamp of when an entity was created"
    }
    columns {
      name    = "update_timestamp"
      type    = "timestamp"
      comment = "timestamp of when an entity was last modified"
    }
    columns {
      name    = "deleted"
      type    = "boolean"
      comment = "if the entity was deleted or not; if true, then most of the other fields are null"
    }
  }

  partition_keys {
    name    = "date"
    type    = "date"
    comment = "date of last modification"
  }
  partition_index {
    index_name = "date_idx"
    keys       = ["date"]
  }
}

resource "aws_glue_catalog_table" "records_snapshots" {
  database_name = aws_glue_catalog_database.analytics.name
  name          = "records_snapshots"
  description   = "append-only snapshots of the normalized and enriched record data of entities_operational"
  parameters = {
    classification = "json"
  }
  table_type = "EXTERNAL_TABLE"
  storage_descriptor {
    location      = format("s3://%s/records_snapshots/", aws_s3_bucket.analytics.bucket)
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"
    ser_de_info {
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
      parameters = {
        "case.insensitive"      = "FALSE",
        "dots.in.keys"          = "FALSE",
        "ignore.malformed.json" = "TRUE"
      }
    }

    columns {
      name    = "record_id"
      type    = "string"
      comment = "id of the record"
    }
    columns {
      name    = "version"
      type    = "int"
      comment = "version of the record"
    }
    columns {
      name    = "entity_id"
      type    = "string"
      comment = "id of the records entity"
    }
    columns {
      name    = "submit_timestamp"
      type    = "timestamp"
      comment = "timestamp when the record was received by the system"
    }
    columns {
      name    = "assemble_timestamp"
      type    = "timestamp"
      comment = "timestamp when the record was assembled into the entity"
    }
    columns {
      name    = "data"
      type    = "string"
      comment = "client specific record data"
    }
    columns {
      name    = "deleted"
      type    = "boolean"
      comment = "if the record was deleted or not; if true, then most of the other fields are null"
    }
  }

  partition_keys {
    name    = "date"
    type    = "date"
    comment = "date of last modification"
  }
  partition_index {
    index_name = "date_idx"
    keys       = ["date"]
  }
}

module "lambda_aggregate_analytics" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.2.1"

  function_name = format("%s-aggregate-analytics", var.prefix)
  handler       = "aggregate-analytics"
  runtime       = "provided.al2"
  timeout       = 900
  memory_size   = 128
  architectures = ["arm64"]

  create_package = false

  s3_existing_package = {
    bucket     = data.aws_s3_object.aggregate_analytics_artifact.bucket
    key        = data.aws_s3_object.aggregate_analytics_artifact.key
    version_id = data.aws_s3_object.aggregate_analytics_artifact.version_id
  }

  environment_variables = {
    ATHENA_SOURCE_TABLE              = aws_glue_catalog_table.entities_operational.name
    ATHENA_TARGET_TABLE_ENTITIES     = aws_glue_catalog_table.entities_snapshots.name
    ATHENA_TARGET_TABLE_RECORDS      = aws_glue_catalog_table.records_snapshots.name
    ATHENA_DATABASE                  = aws_glue_catalog_database.analytics.name
    ATHENA_CATALOG                   = "AwsDataCatalog"
    ATHENA_WORKGROUP                 = aws_athena_workgroup.analytics.name
    S3_ANALYTICS_BUCKET              = aws_s3_bucket.analytics.bucket
    S3_ANALYTICS_SNAPSHOTS_META_FILE = local.snapshots_meta_file
    SNAPSHOT_QUERY_MODE              = var.snapshot_query_mode
  }

  attach_policies = true
  policies = [
    aws_iam_policy.aggregate_analytics.arn
  ]
  number_of_policies = 1

  use_existing_cloudwatch_log_group  = true
  attach_create_log_group_permission = false

  depends_on = [aws_cloudwatch_log_group.lambda_aggregate_analytics]
}

# Moved block to migrate log group from Lambda module to explicit resource
moved {
  from = module.lambda_aggregate_analytics.aws_cloudwatch_log_group.lambda[0]
  to   = aws_cloudwatch_log_group.lambda_aggregate_analytics
}

resource "aws_cloudwatch_log_group" "lambda_aggregate_analytics" {
  name              = "/aws/lambda/${var.prefix}-aggregate-analytics"
  retention_in_days = var.cloudwatch_logs_retention_in_days
}

resource "aws_iam_policy" "aggregate_analytics" {
  name   = format("%s-aggregate-analytics", var.prefix)
  policy = data.aws_iam_policy_document.aggregate_analytics.json
}

locals {
  glue_catalog_arn         = "arn:aws:glue:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:catalog"
  s3_entities_snapshot_arn = "${aws_s3_bucket.analytics.arn}/${aws_glue_catalog_table.entities_snapshots.name}"
  s3_records_snapshot_arn  = "${aws_s3_bucket.analytics.arn}/${aws_glue_catalog_table.records_snapshots.name}"
  s3_query_output_arn      = "${aws_s3_bucket.analytics.arn}/${local.query_output_path}"
}

data "aws_iam_policy_document" "aggregate_analytics" {
  statement {
    effect = "Allow"
    actions = [
      "athena:StartQueryExecution",
      "athena:GetQueryExecution"
    ]
    resources = [aws_athena_workgroup.analytics.arn]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [
      aws_s3_bucket.analytics.arn,
      var.entity_s3_bucket_arn
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject*"
    ]
    resources = [
      "${var.entity_s3_bucket_arn}/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject*",
      "s3:PutObject"
    ]
    resources = [
      "${local.s3_query_output_arn}/*",
      "${local.s3_entities_snapshot_arn}/*",
      "${local.s3_records_snapshot_arn}/*",
      "${aws_s3_bucket.analytics.arn}/${local.snapshots_meta_file}"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "glue:GetTable",
      "glue:GetDatabase",
      "glue:GetPartitions",
      "glue:GetPartition",
      "glue:BatchGetPartition",
      "glue:GetColumnStatisticsForPartition",
      "glue:GetPartitionIndexes",
      "glue:BatchCreatePartition",
      "glue:BatchDeletePartition",
      "glue:BatchUpdatePartition",
      "glue:CreatePartition",
      "glue:DeletePartition",
      "glue:UpdatePartition"
    ]
    resources = [
      local.glue_catalog_arn,
      "${local.glue_catalog_arn}/*",
      aws_glue_catalog_database.analytics.arn,
      aws_glue_catalog_table.entities_operational.arn,
      aws_glue_catalog_table.entities_snapshots.arn,
      aws_glue_catalog_table.records_snapshots.arn
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "glue:GetTable",
      "glue:GetDatabase",
      "glue:CreateTable",
      "glue:UpdateTable"
    ]
    resources = [
      local.glue_catalog_arn,
      "${local.glue_catalog_arn}/*",
      aws_glue_catalog_database.analytics.arn,
      replace(aws_glue_catalog_table.entities_snapshots.arn, aws_glue_catalog_table.entities_snapshots.name, local.entities_view),
      replace(aws_glue_catalog_table.records_snapshots.arn, aws_glue_catalog_table.records_snapshots.name, local.records_view)
    ]
  }
}

resource "aws_scheduler_schedule" "aggregate_analytics" {
  name = format("%s-aggregate-analytics", var.prefix)

  flexible_time_window {
    mode = "OFF"
  }
  schedule_expression = "rate(5 minutes)"

  target {
    arn      = module.lambda_aggregate_analytics.lambda_function_arn
    role_arn = aws_iam_role.aggregate_analytics_schedule.arn
    input    = "{}"

    retry_policy {
      maximum_retry_attempts = 0
    }
  }
}

resource "aws_iam_role" "aggregate_analytics_schedule" {
  name = format("%s-aggregate-analytics-schedule", var.prefix)
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

resource "aws_iam_role_policy" "aggregate_analytics_schedule" {
  name   = format("%s-aggregate-analytics-schedule", var.prefix)
  role   = aws_iam_role.aggregate_analytics_schedule.id
  policy = data.aws_iam_policy_document.aggregate_analytics_schedule.json
}

data "aws_iam_policy_document" "aggregate_analytics_schedule" {
  statement {
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = [
      module.lambda_aggregate_analytics.lambda_function_arn
    ]
  }
}

resource "aws_lambda_invocation" "aggregate_analytics_create_entity_view" {
  function_name = module.lambda_aggregate_analytics.lambda_function_name

  input = jsonencode({
    query = <<EOT
      CREATE OR REPLACE VIEW ${local.entities_view} AS
		  SELECT entity_id, version, type, record_count, edge_count, rule_edge_count, duplicate_count, clique_count, records, edges, duplicates, cliques, data_location, create_timestamp, update_timestamp, date FROM (
	      SELECT *, row_number() over (partition by entity_id order by update_timestamp desc) as rn FROM {{entities}}
		  )
		  WHERE rn = 1 AND deleted = false
    EOT
  })
}

resource "aws_lambda_invocation" "aggregate_analytics_create_record_view" {
  function_name = module.lambda_aggregate_analytics.lambda_function_name

  input = jsonencode({
    query = <<EOT
      CREATE OR REPLACE VIEW ${local.records_view} AS
		  SELECT record_id, version, entity_id, submit_timestamp, assemble_timestamp, data, date FROM (
	      SELECT *, row_number() over (partition by record_id order by assemble_timestamp desc) as rn FROM {{records}}
		  )
		  WHERE rn = 1 AND deleted = false
    EOT
  })
}
