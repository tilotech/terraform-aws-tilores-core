resource "aws_sqs_queue" "dead_letter_queue" {
  name                      = format("%s-%s", local.prefix, "dead-letter-queue")
  receive_wait_time_seconds = 20
  kms_master_key_id         = "alias/aws/sqs"
}

resource "aws_sqs_queue" "scavenger_dead_letter_queue" {
  name                      = format("%s-%s", local.prefix, "scavenger-dead-letter-queue")
  receive_wait_time_seconds = 20
  kms_master_key_id         = "alias/aws/sqs"
}

resource "aws_sqs_queue" "rawdata" {
  count                             = var.assemble_parallelization_sqs == 0 ? 0 : 1
  name                              = format("%s-%s", local.prefix, "rawdata")
  visibility_timeout_seconds        = 900
  receive_wait_time_seconds         = 20
  kms_master_key_id                 = "alias/aws/sqs"
  kms_data_key_reuse_period_seconds = 3600
}

resource "aws_sqs_queue" "rawdata_serial" {
  count                             = !var.enable_serial_assembly || var.assemble_parallelization_sqs == 0 ? 0 : 1
  name                              = format("%s-%s", local.prefix, "rawdata-serial")
  visibility_timeout_seconds        = 900
  receive_wait_time_seconds         = 20
  kms_master_key_id                 = "alias/aws/sqs"
  kms_data_key_reuse_period_seconds = 3600
}

resource "aws_sqs_queue" "entity_stream" {
  count                             = local.create_entity_stream_sqs ? 1 : 0
  name                              = format("%s-%s", local.prefix, "entity-stream")
  visibility_timeout_seconds        = 180
  receive_wait_time_seconds         = 20
  kms_master_key_id                 = "alias/aws/sqs"
  kms_data_key_reuse_period_seconds = 3600
}
