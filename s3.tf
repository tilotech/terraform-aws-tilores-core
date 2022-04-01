resource "aws_s3_bucket" "entity" {
  bucket        = format("%s-%s", local.prefix, "entity")
  force_destroy = true

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "entity" {
  bucket = aws_s3_bucket.entity.id

  rule {
    id     = "cleanup"
    status = "Enabled"
    expiration {
      expired_object_delete_marker = true
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "entity" {
  bucket = aws_s3_bucket.entity.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket" "execution_plan" {
  bucket        = format("%s-%s", local.prefix, "execution-plan")
  force_destroy = true

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "execution_plan" {
  bucket = aws_s3_bucket.execution_plan.id

  rule {
    id     = "cleanup"
    status = "Enabled"
    expiration {
      expired_object_delete_marker = true
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "execution_plan" {
  bucket = aws_s3_bucket.execution_plan.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}
