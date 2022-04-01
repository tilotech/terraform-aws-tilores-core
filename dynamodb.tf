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
    enabled = true
  }
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
    enabled = true
  }
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
}


