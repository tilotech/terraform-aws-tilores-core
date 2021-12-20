variable "resource_prefix" {
  type        = string
  description = "The text every created resource will be prefixed with."
}

variable "enable_kms" {
  description = "Enabled KMS encryption (currently only SQS, for other resources its enabled by default)"
  type        = bool
  default     = "false"
}

variable "entity_event_stream_shard_count" {
  description = "The amount of Kinesis shards used for entity event stream, can only be incremented by doubling the current value as many times as needed"
  type        = string
  default     = "1"
}

variable "rawdata_stream_shard_count" {
  description = "The amount of Kinesis shards used for the rawdata assembly stream, in case you expect a high amount of data ingestion (mutation submit) then increase this number, can only be incremented by doubling the current value as many times as needed"
  type        = string
  default     = "1"
}

variable "assemble_parallelization_factor" {
  type        = string
  description = "This value configures how many lambda consumers are on each raw stream shard. (Max and default is 10)"
  default     = "10"
}

variable "rule_config" { // TODO: Verify if still needed
  type = string
}

variable "api_file" {
  type        = string
  description = "The path to the built and zipped API artifact. (automatically created using tilores-cli)"
}

variable "core_version" {
  description = "The version of tilores core, e.g. v0-1-0 , v0 or latest"
  type        = string
  default     = "v0"
}

variable "scavenger_version" {
  description = "The version of scavenger, e.g. v0-1-0 , v0 or latest"
  type        = string
  default     = "v0"
}

variable "dispatcher_plugin_version" {
  description = "The version of dispatcher plugin, e.g. v0-1-0 , v0 or latest"
  type        = string
  default     = "v0"
}

locals {
  prefix           = format("%s-tilores", var.resource_prefix)
  artifacts_bucket = "tilotech-artifacts"

  core_envs = { // TODO: Adjust according to refactored version
    RULE_CONFIG                           = var.rule_config
    RULE_SET_ID_INDEX                     = "index"
    RULE_SET_ID_INDEX_ALL                 = "indexAll"
    RULE_SET_ID_INDEX_ENTITY              = "indexEntity"
    RULE_SET_ID_SEARCH                    = "match"
    RULE_SET_ID_DEDUP                     = "dedup"
    RULE_SET_ID_ASSOC                     = "associated"
    DYNAMODB_RULE_INDEX                   = aws_dynamodb_table.rule_index.name
    DYNAMODB_RULE_INDEX_ALL               = aws_dynamodb_table.rule_index_all.name
    DYNAMODB_RULE_INDEX_ENTITY            = aws_dynamodb_table.rule_index_entity.name
    DYNAMODB_RULE_INDEX_ENTITY_INDEX_NAME = aws_dynamodb_table.rule_index_entity.global_secondary_index.*.name[0]
    DYNAMODB_RULE_REVERSE_INDEX           = aws_dynamodb_table.rule_reverse_index.name
    DYNAMODB_LOOKUP                       = aws_dynamodb_table.lookup.name
    DYNAMODB_CONSISTENT_READ              = "TRUE"
    S3_ENTITY_BUCKET                      = aws_s3_bucket.entity.bucket
    S3_EXECUTION_PLAN_BUCKET              = aws_s3_bucket.execution_plan.bucket
    KINESIS_ENTITY_STREAM                 = aws_kinesis_stream.kinesis_entity_stream.name
    KINESIS_RAW_DATA_STREAM               = aws_kinesis_stream.kinesis_rawdata_stream.name
    DEAD_LETTER_QUEUE                     = aws_sqs_queue.dead_letter_queue.name
  }
}
