variable "resource_prefix" {
  type        = string
  description = "The text every created resource will be prefixed with."
}

variable "authorizer_issuer_url" {
  type        = string
  description = "(Only used and required for `JWT` type) The issuer URL to be used by the authorizer (for cognito it is the user pool endpoint)"
  default     = null
}

variable "authorizer_audience" {
  type        = list(string)
  description = "(Only used and required for `JWT` type) A list of allowed token recipient identifiers  (for cognito it is the client ID)"
  default     = null
}

variable "authorizer_type" {
  type        = string
  description = "The type of the authorizer attached to the API. Valid values: `JWT`, `REQUEST`."
  default     = "JWT"
}

variable "authorizer_credentials_arn" {
  type        = string
  description = "(Only for `REQUEST` type) The IAM role for API Gateway to invoke the authorizer. Supported only for `REQUEST` authorizers."
  default     = null
}

variable "authorizer_payload_format_version" {
  type        = string
  description = "(Only for `REQUEST` type) The format of the payload sent to an HTTP API Lambda authorizer. Required for HTTP API Lambda authorizers. Valid values: `1.0`, `2.0`."
  default     = null
}

variable "authorizer_result_ttl_in_seconds" {
  type        = number
  description = "(Only for `REQUEST` type) The time to live (TTL) for cached authorizer results, in seconds. If it equals 0, authorization caching is disabled. If it is greater than 0, API Gateway caches authorizer responses. The maximum value is 3600, or 1 hour. Supported only for HTTP API Lambda authorizers."
  default     = 0
}

variable "authorizer_uri" {
  type        = string
  description = "(Only for `REQUEST` type) The authorizer's Uniform Resource Identifier (URI). For REQUEST authorizers this must be a well-formed Lambda function URI, such as the invoke_arn attribute of the aws_lambda_function resource. Supported only for REQUEST authorizers. Must be between 1 and 2048 characters in length."
  default     = null
}

variable "enable_simple_responses" {
  type        = bool
  description = "(Only for `REQUEST` type) Whether a Lambda authorizer returns a response in a simple format. If enabled, the Lambda authorizer can return a boolean value instead of an IAM policy. Supported only for HTTP APIs."
  default     = null
}

variable "entity_event_stream_shard_count" {
  description = "The amount of Kinesis shards used for entity event stream; can at maximum be set to twice or half the current value; if needed increasing or decreasing can be applied multiple times in seperate steps"
  type        = string
  default     = "1"
}

variable "rawdata_stream_shard_count" {
  description = "The amount of Kinesis shards used for the rawdata assembly stream, in case you expect a high amount of data ingestion (mutation submit) then increase this number; can at maximum be set to twice or half the current value; if needed increasing or decreasing can be applied multiple times in seperate steps"
  type        = string
  default     = "1"
}

variable "assemble_parallelization_factor" {
  type        = string
  description = "This value configures how many lambda consumers are listening on each raw stream shard. (Max and default is 10)"
  default     = "10"
}

variable "api_file" {
  type        = string
  description = "The path to the built and zipped API artifact. (automatically created using tilores-cli)"
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

locals {
  prefix           = format("%s-tilores", var.resource_prefix)
  artifacts_bucket = format("tilotech-artifacts-%s", data.aws_region.current.id)
  tilotech_api_url = "https://api.tilotech.io"

  rule_config_json_path = format("/opt/%s", replace(basename(var.rule_config_file), ".zip", ".json"))

  core_envs = {
    RULE_CONFIG                 = local.rule_config_json_path
    DYNAMODB_RULE_INDEX         = aws_dynamodb_table.rule_index.name
    DYNAMODB_RULE_REVERSE_INDEX = aws_dynamodb_table.rule_reverse_index.name
    DYNAMODB_ENTITIES           = aws_dynamodb_table.entities.name
    DYNAMODB_RECORDS            = aws_dynamodb_table.records.name
    DYNAMODB_CONSISTENT_READ    = "TRUE"
    S3_ENTITY_BUCKET            = aws_s3_bucket.entity.bucket
    S3_EXECUTION_PLAN_BUCKET    = aws_s3_bucket.execution_plan.bucket
    KINESIS_ENTITY_STREAM       = aws_kinesis_stream.kinesis_entity_stream.name
    KINESIS_RAW_DATA_STREAM     = aws_kinesis_stream.kinesis_rawdata_stream.name
    DEAD_LETTER_QUEUE           = aws_sqs_queue.dead_letter_queue.name
  }
}
