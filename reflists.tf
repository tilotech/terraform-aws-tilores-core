// External Reference Lists
//
// Fetches reference lists from S3 based on external_reflists variable
// and creates a Lambda layer with them.

locals {
  // Parse each external reference: "filename@version"
  parsed_refs = {
    for ext in coalesce(var.external_reflists, []) : ext => {
      filename = split("@", ext)[0]
      version  = split("@", ext)[1]
    }
  }

  has_external_refs = length(coalesce(var.external_reflists, [])) > 0
}

// Fetch each external reference list file from S3
data "aws_s3_object" "ref_list_files" {
  for_each = local.parsed_refs

  bucket = local.artifacts_bucket
  key    = format("tilotech/tilores-reflists/%s/%s.json", each.value.version, each.value.filename)

  // Terraform strings are Unicode NFC, so the list bytes must never pass
  // through one: body_base64 carries the object bytes unchanged.
  download_body = true
}

// Write each ref list to local temp directory with correct structure.
// content_base64 writes the S3 bytes as they are. local_sensitive_file keeps
// the list data out of the plan output.
resource "local_sensitive_file" "ref_list_files" {
  for_each = local.has_external_refs ? data.aws_s3_object.ref_list_files : {}

  filename       = "${local.ref_lists_dir}/${local.parsed_refs[each.key].version}/${local.parsed_refs[each.key].filename}.json"
  content_base64 = each.value.body_base64
}

// Create ZIP archive from the files on disk, not from string content.
data "archive_file" "ref_lists_layer" {
  count = local.has_external_refs ? 1 : 0

  type        = "zip"
  output_path = "${path.module}/.terraform/tmp/ref-lists-layer.zip"
  source_dir  = local.ref_lists_dir

  depends_on = [local_sensitive_file.ref_list_files]
}

locals {
  // One directory per set of references, so files from another workspace or
  // an earlier set of references cannot end up in the zip.
  ref_lists_dir = "${path.module}/.terraform/tmp/reflists-${md5(join(",", sort(keys(local.parsed_refs))))}"
}

// Lambda layer containing external reference lists.
// The zip is built during apply, so its hash is unknown at plan time. The
// layer is published again when a reference or the content of a list changes:
// source_code_hash is computed from the S3 objects, which are read at plan time.
resource "aws_lambda_layer_version" "ref_lists" {
  count = local.has_external_refs ? 1 : 0

  layer_name               = format("%s-ref-lists", local.prefix)
  description              = "ETM external reference lists"
  compatible_runtimes      = ["provided.al2023"]
  compatible_architectures = ["arm64"]

  filename         = data.archive_file.ref_lists_layer[0].output_path
  source_code_hash = sha256(jsonencode({ for k, o in data.aws_s3_object.ref_list_files : k => sha256(o.body_base64) }))

  lifecycle {
    create_before_destroy = true
  }
}
