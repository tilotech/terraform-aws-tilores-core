variable "prefix" {
  description = "The text every created resources will be prefixed with."
  type        = string
}

variable "core_version" {
  description = "The version of tilores core, e.g. v0-1-0 , v0 or latest."
  type        = string
}

variable "artifacts_bucket" {
  description = "The artifacts bucket used for retrieving lambda binaries."
  type        = string
}

variable "cloudwatch_logs_retention_in_days" {
  description = "Number of days to keep the cloudwatch logs for lambda functions."
  type        = number
}

variable "entity_s3_bucket_id" {
  description = "ID of the S3 bucket where the operational data is stored."
  type        = string
}

variable "entity_s3_bucket_arn" {
  description = "ID of the S3 bucket where the operational data is stored."
  type        = string
}

variable "snapshot_query_mode" {
  description = "Query mode for snapshot creation: WAIT (ensures successful query execution) or FIRE_AND_FORGET (ensures that the query was started but will not wait for it to finish)."
  type        = string
}

locals {
  query_output_path   = "query_results"
  snapshots_meta_file = "snapshots.meta"
  entities_view       = "entities"
  records_view        = "records"
}
