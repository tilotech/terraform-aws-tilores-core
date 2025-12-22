// External Reference Lists
//
// Dynamically fetches reference lists configured with "external" in rule config
// and creates a Lambda layer with them.
// Extract and parse rule config from ZIP file
data "external" "rule_config" {
  program = ["bash", "-c", <<-EOT
    unzip -p "${var.rule_config_file}" "*.json" | jq -c '{config: (. | @json)}'
  EOT
  ]
}

locals {
  rule_config = jsondecode(data.external.rule_config.result.config)

  // Extract external references from referenceLists
  external_refs = [
    for ref in try(local.rule_config.referenceLists, []) :
    ref.external if try(ref.external, null) != null
  ]

  // Parse each external reference: "filename@version"
  parsed_refs = {
    for ext in local.external_refs : ext => {
      filename = split("@", ext)[0]
      version  = split("@", ext)[1]
    }
  }

  has_external_refs = length(local.parsed_refs) > 0
}

// Fetch each external reference list file from S3
data "aws_s3_object" "ref_list_files" {
  for_each = local.parsed_refs

  bucket = local.artifacts_bucket
  key    = format("tilotech/tilores-reflists/%s/%s.json", each.value.version, each.value.filename)
}

// Write each ref list to local temp directory with correct structure
resource "local_file" "ref_list_files" {
  for_each = local.has_external_refs ? data.aws_s3_object.ref_list_files : {}

  filename = "${path.module}/.terraform/tmp/reflists/${local.parsed_refs[each.key].version}/${local.parsed_refs[each.key].filename}.json"
  content  = each.value.body
}

// Create ZIP archive with all ref list files
data "archive_file" "ref_lists_layer" {
  count = local.has_external_refs ? 1 : 0

  type        = "zip"
  output_path = "${path.module}/.terraform/tmp/ref-lists-layer.zip"

  dynamic "source" {
    for_each = local_file.ref_list_files
    content {
      filename = replace(source.value.filename, "${path.module}/.terraform/tmp/reflists/", "")
      content  = source.value.content
    }
  }
}

// Lambda layer containing external reference lists
module "lambda_layer_etm_ref_lists" {
  count = local.has_external_refs ? 1 : 0

  source  = "terraform-aws-modules/lambda/aws"
  version = "7.2.1"

  create_layer = true

  layer_name               = format("%s-ref-lists", local.prefix)
  description              = "ETM external reference lists"
  compatible_runtimes      = ["provided.al2023"]
  compatible_architectures = ["arm64"]

  create_package         = false
  local_existing_package = data.archive_file.ref_lists_layer[0].output_path

  cloudwatch_logs_retention_in_days = var.cloudwatch_logs_retention_in_days
}
