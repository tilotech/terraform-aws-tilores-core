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
