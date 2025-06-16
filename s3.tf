resource "aws_s3_bucket" "entity" {
  bucket        = format("%s-%s", local.prefix, "entity")
  force_destroy = true

  lifecycle {
    prevent_destroy = false
  }

  tags = var.tags_s3_entity
}

resource "aws_s3_bucket_lifecycle_configuration" "entity" {
  bucket = aws_s3_bucket.entity.id

  rule {
    id     = "cleanup"
    status = "Enabled"
    filter {}
    expiration {
      expired_object_delete_marker = true
    }
    dynamic "noncurrent_version_expiration" {
      for_each = coalesce(var.prepare_for_aws_backup, false) ? [1] : []
      content {
        noncurrent_days = 1
      }
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

resource "aws_s3_bucket_public_access_block" "entity" {
  bucket = aws_s3_bucket.entity.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "entity" {
  count = coalesce(var.prepare_for_aws_backup, false) ? 1 : 0

  bucket = aws_s3_bucket.entity.id
  versioning_configuration {
    status = "Enabled"
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
    filter {}
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

resource "aws_s3_bucket_public_access_block" "execution_plan" {
  bucket = aws_s3_bucket.execution_plan.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
