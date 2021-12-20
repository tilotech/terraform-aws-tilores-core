resource "aws_dynamodb_table" "lookup" {
  name         = format("%s-%s", local.prefix, "lookup")
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

resource "aws_dynamodb_table" "rule_index_all" {
  name         = format("%s-%s", local.prefix, "rule-index-all")
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

resource "aws_dynamodb_table" "rule_index_entity" {
  name         = format("%s-%s", local.prefix, "rule-index-entity")
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "matching_key"
  range_key    = "entity_id"

  attribute {
    name = "matching_key"
    type = "S"
  }

  attribute {
    name = "entity_id"
    type = "S"
  }

  global_secondary_index {
    hash_key        = "entity_id"
    name            = "entity_id-index"
    projection_type = "ALL"
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

// This table can be used by external tools for storing not importable records.
// tilores itself will not add items here.
resource "aws_dynamodb_table" "import_failures" {
  name         = format("%s-%s", local.prefix, "import-failures")
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

// This table can be used by external tools for storing not importable records.
// tilores itself will not add items here.
resource "aws_dynamodb_table" "disassemble_failures" {
  name         = format("%s-%s", local.prefix, "disassemble-failures")
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


