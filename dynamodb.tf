resource "aws_dynamodb_table" "entities" {
  name         = format("%s-%s", local.prefix, "entities")
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = coalesce(var.prepare_for_aws_backup, true)
  }

  tags = var.tags_dynamodb
}

resource "aws_dynamodb_table" "records" {
  name         = format("%s-%s", local.prefix, "records")
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = coalesce(var.prepare_for_aws_backup, true)
  }

  tags = var.tags_dynamodb
}

resource "aws_dynamodb_table" "rule_index" {
  name         = format("%s-%s", local.prefix, "rule-index")
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "matching_key"

  attribute {
    name = "matching_key"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = coalesce(var.prepare_for_aws_backup, false)
  }

  tags = var.tags_dynamodb
}

resource "aws_dynamodb_table" "rule_reverse_index" {
  name         = format("%s-%s", local.prefix, "rule-reverse-index")
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = coalesce(var.prepare_for_aws_backup, false)
  }

  tags = var.tags_dynamodb
}



# The review tables only exist where reviewing weak links is turned on, so that
# an instance that does not review pays neither the storage nor the writes.
resource "aws_dynamodb_table" "review_cases" {
  count = var.enable_review ? 1 : 0

  name         = format("%s-%s", local.prefix, "review-cases")
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  attribute {
    name = "sortKey"
    type = "S"
  }

  # the queue itself: the waiting cases of one status, oldest first. It projects
  # the keys only, because counting the open cases happens on every page of the
  # queue and the cases are read from the table anyway.
  global_secondary_index {
    name            = "status-sortKey-index"
    projection_type = "KEYS_ONLY"

    key_schema {
      attribute_name = "status"
      key_type       = "HASH"
    }

    key_schema {
      attribute_name = "sortKey"
      key_type       = "RANGE"
    }
  }

  server_side_encryption {
    enabled = true
  }

  # a case is transient, it is deleted as soon as it was decided
  point_in_time_recovery {
    enabled = coalesce(var.prepare_for_aws_backup, false)
  }

  tags = var.tags_dynamodb
}

resource "aws_dynamodb_table" "review_decisions" {
  count = var.enable_review ? 1 : 0

  name         = format("%s-%s", local.prefix, "review-decisions")
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"
  range_key    = "sk"

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  # a decision is the permanent record of what a reviewer concluded and cannot
  # be recomputed from the data it changed
  point_in_time_recovery {
    enabled = coalesce(var.prepare_for_aws_backup, true)
  }

  tags = var.tags_dynamodb
}
