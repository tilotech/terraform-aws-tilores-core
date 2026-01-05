variable "resource_prefix" {
  type        = string
  description = "The text every created resource will be prefixed with."
}

variable "authorizer_issuer_url" {
  type        = string
  description = "(Only used and required for `JWT` type, or ip_range_allow_list) The issuer URL to be used by the authorizer (for cognito it is the user pool endpoint)"
  default     = null
}

variable "authorizer_audience" {
  type        = list(string)
  description = "(Only used and required for `JWT` type, or ip_range_allow_list) A list of allowed token recipient identifiers  (for cognito it is the client ID)"
  default     = null
}

variable "ip_range_allow_list" {
  description = "(Requires authorizer_issuer_url and authorizer_audience) List of IP addresses and/or CIDR blocks allowed to invoke tilores API, e.g. ['192.168.0.2', '192.168.0.0', '192.168.0.0/24']"
  type        = list(string)
  default     = null
}

variable "authorizer_version" {
  description = "(Only used with ip_range_allow_list) The version of tilores authorizer, e.g. v0-1-0 , v0 or latest"
  type        = string
  default     = "v0"
}

variable "create_default_stage" {
  description = "Whether to create the default stage. This is useful when a custom default stage is needed, such as providing stage variables. Then you can provide a `false` here and create an `aws_apigatewayv2_stage` resource outside of the module with and attach your custom stage to the API using the output `api_id`."
  type        = bool
  default     = true
}

variable "authorizer_type" {
  type        = string
  description = "(Conflicts with ip_range_allow_list) The type of the authorizer attached to the API. Valid values: `JWT`, `REQUEST`."
  default     = "JWT"
}

variable "authorizer_credentials_arn" {
  type        = string
  description = "(Only for `REQUEST` type, and conflicts with ip_range_allow_list) The IAM role for API Gateway to invoke the authorizer. Supported only for `REQUEST` authorizers."
  default     = null
}

variable "authorizer_payload_format_version" {
  type        = string
  description = "(Only for `REQUEST` type, and conflicts with ip_range_allow_list) The format of the payload sent to an HTTP API Lambda authorizer. Required for HTTP API Lambda authorizers. Valid values: `1.0`, `2.0`."
  default     = null
}

variable "authorizer_result_ttl_in_seconds" {
  type        = number
  description = "(Works with `REQUEST` type, or with ip_range_allow_list) The time to live (TTL) for cached authorizer results, in seconds. If it equals 0, authorization caching is disabled. If it is greater than 0, API Gateway caches authorizer responses. The maximum value is 3600, or 1 hour. Supported only for HTTP API Lambda authorizers."
  default     = 0
}

variable "authorizer_uri" {
  type        = string
  description = "(Only for `REQUEST` type, and conflicts with ip_range_allow_list) The authorizer's Uniform Resource Identifier (URI). For REQUEST authorizers this must be a well-formed Lambda function URI, such as the invoke_arn attribute of the aws_lambda_function resource. Supported only for REQUEST authorizers. Must be between 1 and 2048 characters in length."
  default     = null
}

variable "enable_simple_responses" {
  type        = bool
  description = "(Only for `REQUEST` type, and conflicts with ip_range_allow_list) Whether a Lambda authorizer returns a response in a simple format. If enabled, the Lambda authorizer can return a boolean value instead of an IAM policy. Supported only for HTTP APIs."
  default     = null
}

variable "cors_configuration" {
  type        = any
  description = "The CORS configuration for the API."
  default     = {}
}

variable "create_entity_stream" {
  description = "Whether to create the entity event stream or not, if set to true and entity_event_stream_shard_count is 0 then an SQS queue is created"
  type        = bool
  default     = false
}

variable "entity_stream_offload_expiry_days" {
  description = "The number of days before offloaded entity stream messages will expire. Currently only applies to SQS-based entity streams."
  type        = number
  default     = 4
}

variable "entity_event_stream_shard_count" {
  description = "The amount of Kinesis shards used for entity event stream; can at maximum be set to twice or half the current value; if needed increasing or decreasing can be applied multiple times in seperate steps"
  type        = number
  default     = 0
}

variable "rawdata_stream_shard_count" {
  description = "The amount of Kinesis shards used for the rawdata assembly stream, in case you expect a high amount of data ingestion (mutation submit) then increase this number; can at maximum be set to twice or half the current value; if needed increasing or decreasing can be applied multiple times in separate steps"
  type        = number
  default     = 0
}

variable "assemble_parallelization_factor" {
  type        = number
  description = "This value configures how many lambda consumers are listening on each raw stream shard. (Max and default is 10)"
  default     = 10
}

variable "assemble_parallelization_sqs" {
  type        = number
  description = "This value configures how many lambda consumers are listening on sqs raw data queue. (Between 2 and 1000, default is 10)"
  default     = 10
}

variable "api_file" {
  type        = string
  description = "The path to the built and zipped API artifact. (automatically created using tilores-cli)"
}

variable "api_access_log_destination_arn" {
  description = "ARN of the CloudWatch Logs log group to receive API gateweay access logs. Any trailing :* is trimmed from the ARN. (If used then api_access_log_format must also be provided, Default is null)"
  type        = string
  default     = null
}

variable "api_access_log_format" {
  description = "Single line format of the access logs of data, as specified by selected $context variables. (If used then api_access_log_destination_arn must also be provided, Default is null)"
  type        = string
  default     = null
}

variable "rule_config_file" {
  description = "The path to the zipped rule config json file. (automatically created using tilores-cli)"
  type        = string
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

variable "customer_metrics_version" {
  description = "The version of customer metrics, e.g. v0-1-0 , v0 or latest"
  type        = string
  default     = "v0"
}

variable "update_records" {
  description = "Allows updating existing records if set to true"
  type        = bool
  default     = false
}

variable "create_dashboard" {
  description = "Defines whether to create a cloudwatch dashboard"
  type        = bool
  default     = true
}

variable "enable_analytics" {
  description = "Defines whether to create the resources required for improved analytic queries"
  type        = bool
  default     = false
}

variable "snapshot_query_mode" {
  description = "Query mode for snapshot creation: WAIT (ensures successful query execution) or FIRE_AND_FORGET (ensures that the query was started but will not wait for it to finish). Ignored if enable_analytics is false."
  type        = string
  default     = "FIRE_AND_FORGET"
}

variable "prepare_for_aws_backup" {
  description = "Prepares resources to be backed up by AWS Backup if it is setup. Enables S3 versioning and DynamoDB point in time recovery"
  type        = bool
  default     = null
}

variable "enable_serial_assembly" {
  description = "Defines whether to enable automatic serial processing for highly locked entities; highly recommended for most large volume deployments; serial processing requires a valid sqs (default) or kinesis stream"
  type        = bool
  default     = false
}

variable "rawdata_serial_stream_shard_count" {
  description = "The amount of Kinesis shards used for the rawdata assembly stream during serial processing, in case you expect a high amount of data ingestion (mutation submit) then increase this number; can at maximum be set to twice or half the current value; if needed increasing or decreasing can be applied multiple times in separate steps"
  type        = number
  default     = 0
}

variable "locked_entities_cache_size" {
  description = "The cache size for detecting entities that require serial processing; higher values increase the likeliness of identifying frequently locked entities"
  type        = number
  default     = 200
}

variable "locked_entities_cache_max_age" {
  description = "The maximum age of cache entries for detecting entities that require serial processing; e.g. 10m or 2h; longer periods increase the likeliness of identifying frequently locked entities and decrease chance of early cache eviction"
  type        = string
  default     = "30m"
}

variable "locked_entities_cache_threshold" {
  description = "The count threshold for detecting entities that require serial processing; defines the minimal required count an entity must have been locked (in the same lambda function) before being migrated into serial processing"
  type        = number
  default     = 10
}

variable "enable_file_compression" {
  description = "Enables gzip compression for entity files"
  type        = bool
  default     = false
}

variable "tags_dynamodb" {
  description = "A map of tags to assign to DynamoDB tables."
  type        = map(string)
  default     = {}
}

variable "tags_s3_entity" {
  description = "A map of tags to assign to the entity S3 bucket."
  type        = map(string)
  default     = {}
}

variable "cloudwatch_logs_retention_in_days" {
  description = "Number of days to keep the cloudwatch logs for lambda functions."
  type        = number
  default     = null
}

variable "external_reflists" {
  type        = list(string)
  description = "List of external reference list identifiers (format: filename@version)"
  default     = []

  validation {
    condition     = alltrue([for ref in var.external_reflists : length(split("@", ref)) == 2])
    error_message = "Each external_reflists entry must be in format 'filename@version'."
  }
}

locals {
  prefix           = format("%s-tilores", var.resource_prefix)
  artifacts_bucket = format("tilotech-artifacts-%s", data.aws_region.current.id)
  tilotech_api_url = "https://api.tilotech.io"

  rule_config_json_path = format("/opt/%s", replace(basename(var.rule_config_file), ".zip", ".json"))

  create_entity_stream_sqs     = var.create_entity_stream && var.entity_event_stream_shard_count == 0
  create_entity_stream_kinesis = var.create_entity_stream && var.entity_event_stream_shard_count != 0

  core_envs = {
    RULE_CONFIG                       = local.rule_config_json_path
    DYNAMODB_RULE_INDEX               = aws_dynamodb_table.rule_index.name
    DYNAMODB_RULE_REVERSE_INDEX       = aws_dynamodb_table.rule_reverse_index.name
    DYNAMODB_ENTITIES                 = aws_dynamodb_table.entities.name
    DYNAMODB_RECORDS                  = aws_dynamodb_table.records.name
    DYNAMODB_CONSISTENT_READ          = "TRUE"
    S3_ENTITY_BUCKET                  = aws_s3_bucket.entity.bucket
    S3_EXECUTION_PLAN_BUCKET          = aws_s3_bucket.execution_plan.bucket
    KINESIS_ENTITY_STREAM             = local.create_entity_stream_kinesis ? aws_kinesis_stream.kinesis_entity_stream[0].name : ""
    SQS_ENTITY_STREAM                 = local.create_entity_stream_sqs ? aws_sqs_queue.entity_stream[0].name : ""
    ENTITY_STREAM_PROVIDER            = local.create_entity_stream_sqs ? "SQS" : ""
    KINESIS_RAW_DATA_STREAM           = var.rawdata_stream_shard_count == 0 ? "" : aws_kinesis_stream.kinesis_rawdata_stream[0].name
    RAW_DATA_SQS                      = var.assemble_parallelization_sqs == 0 ? "" : aws_sqs_queue.rawdata[0].name
    SNAPSHOT_REPO_PROVIDER            = var.enable_analytics ? "ATHENA" : "NONE"
    DEAD_LETTER_QUEUE                 = aws_sqs_queue.dead_letter_queue.name
    UPDATE_RECORDS                    = var.update_records ? "TRUE" : "FALSE"
    ENTITY_FILE_COMPRESSION           = var.enable_file_compression ? "gzip" : ""
    PARTIAL_BATCH_RESPONSE            = var.assemble_parallelization_sqs == 0 ? "FALSE" : "TRUE"
    ENTITY_STREAM_OFFLOAD_EXPIRY_DAYS = var.entity_stream_offload_expiry_days
    REFLIST_LOCAL_PATH                = local.has_external_refs ? "/opt" : ""
    REFLIST_S3_PATH                   = local.has_external_refs ? format("%s/tilotech/tilores-reflists", local.artifacts_bucket) : ""
  }
}
