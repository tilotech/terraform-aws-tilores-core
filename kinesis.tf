resource "aws_kinesis_stream" "kinesis_entity_stream" {
  count           = var.entity_event_stream_shard_count == 0 ? 0 : 1
  name            = format("%s-%s", local.prefix, "entity-stream")
  shard_count     = tostring(var.entity_event_stream_shard_count)
  kms_key_id      = "alias/aws/kinesis"
  encryption_type = "KMS"
}

resource "aws_kinesis_stream" "kinesis_rawdata_stream" {
  count           = var.rawdata_stream_shard_count == 0 ? 0 : 1
  name            = format("%s-%s", local.prefix, "rawdata-stream")
  shard_count     = tostring(var.rawdata_stream_shard_count)
  kms_key_id      = "alias/aws/kinesis"
  encryption_type = "KMS"
}
