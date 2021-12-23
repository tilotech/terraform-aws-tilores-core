resource "aws_s3_bucket" "entity" {
  bucket        = format("%s-%s", local.prefix, "entity")
  acl           = "private"
  force_destroy = true

  versioning {
    enabled = false
  }

  lifecycle_rule {
    id      = "cleanup"
    enabled = true
    expiration {
      expired_object_delete_marker = true
    }
  }

  lifecycle {
    prevent_destroy = false
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
      bucket_key_enabled = true
    }
  }
}

resource "aws_s3_bucket" "execution_plan" {
  bucket        = format("%s-%s", local.prefix, "execution-plan")
  acl           = "private"
  force_destroy = true

  versioning {
    enabled = false
  }

  lifecycle_rule {
    id      = "cleanup"
    enabled = true
    expiration {
      expired_object_delete_marker = true
    }
  }

  lifecycle {
    prevent_destroy = false
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
      bucket_key_enabled = true
    }
  }
}
