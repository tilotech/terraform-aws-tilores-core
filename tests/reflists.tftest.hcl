# External reference lists must reach the Lambda layer byte for byte.
#
# Terraform keeps every string value in Unicode NFC form. A list that passes
# through a string (for example data.aws_s3_object.body) loses its non-NFC text:
# the precomposed Bengali letter U+09DC becomes U+09A1 U+09BC, which breaks the
# 4-character limit for normalizename script entries.
#
# Needs Terraform >= 1.7 (mock providers). AWS and time are mocked; local and
# archive run for real and write the list files and the zip.
#
# The samples are base64 because override values must be literals, and because a
# string literal in this file would itself be normalized. Decoded, the first
# sample is this list, with token A = U+0995 U+09CD U+09DC "$" and token B = U+09A1:
#   {"meta": {"header": [{"type": "token"}, {"type": "constraint"}, {"type": "mapping"}]},
#    "rows": [[A, "*", "kr"], [B, "*", "d"]]}
# The second sample is the same list with the mapping "dh" instead of "d".
# sha256 of the first sample's bytes: 3dedfc8f40299ec71e61252a2d5de60442a36f7843109755817c6236a820105c

mock_provider "aws" {
  # The provider validates policy and ARN arguments even when mocked.
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
  mock_resource "aws_iam_policy" {
    defaults = {
      arn = "arn:aws:iam::123456789012:policy/test"
    }
  }
  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/test"
    }
  }
  mock_resource "aws_lambda_layer_version" {
    defaults = {
      arn = "arn:aws:lambda:eu-central-1:123456789012:layer:test:1"
    }
  }
  mock_resource "aws_lambda_function" {
    defaults = {
      arn = "arn:aws:lambda:eu-central-1:123456789012:function:test"
    }
  }
  mock_resource "aws_apigatewayv2_api" {
    defaults = {
      execution_arn = "arn:aws:execute-api:eu-central-1:123456789012:test"
    }
  }
  mock_resource "aws_cloudwatch_log_group" {
    defaults = {
      arn = "arn:aws:logs:eu-central-1:123456789012:log-group:test"
    }
  }
  mock_resource "aws_cloudwatch_event_rule" {
    defaults = {
      arn = "arn:aws:events:eu-central-1:123456789012:rule/test"
    }
  }
}
mock_provider "time" {}

variables {
  resource_prefix   = "test"
  api_file          = "not-used-api.zip"
  rule_config_file  = "not-used-rule-config.zip"
  external_reflists = ["map-person-script@v0-5-0"]
}

run "list_bytes_reach_the_layer_unchanged" {
  command = apply

  override_data {
    target = data.aws_s3_object.ref_list_files
    values = {
      body_base64 = "eyJtZXRhIjogeyJoZWFkZXIiOiBbeyJ0eXBlIjogInRva2VuIn0sIHsidHlwZSI6ICJjb25zdHJhaW50In0sIHsidHlwZSI6ICJtYXBwaW5nIn1dfSwgInJvd3MiOiBbWyLgppXgp43gp5wkIiwgIioiLCAia3IiXSwgWyLgpqEiLCAiKiIsICJkIl1dfQo="
    }
  }

  assert {
    condition     = local_sensitive_file.ref_list_files["map-person-script@v0-5-0"].content_sha256 == "3dedfc8f40299ec71e61252a2d5de60442a36f7843109755817c6236a820105c"
    error_message = "The list file for the layer differs from the S3 object."
  }

  assert {
    # Decoding into a string normalizes the sample, so its hash must differ from the raw bytes.
    condition     = length(local_sensitive_file.ref_list_files) == 1 && sha256(base64decode("eyJtZXRhIjogeyJoZWFkZXIiOiBbeyJ0eXBlIjogInRva2VuIn0sIHsidHlwZSI6ICJjb25zdHJhaW50In0sIHsidHlwZSI6ICJtYXBwaW5nIn1dfSwgInJvd3MiOiBbWyLgppXgp43gp5wkIiwgIioiLCAia3IiXSwgWyLgpqEiLCAiKiIsICJkIl1dfQo=")) != "3dedfc8f40299ec71e61252a2d5de60442a36f7843109755817c6236a820105c"
    error_message = "The sample must contain text that is not in NFC form, or this test proves nothing."
  }

  assert {
    condition     = aws_lambda_layer_version.ref_lists[0].source_code_hash == sha256(jsonencode({ "map-person-script@v0-5-0" = sha256("eyJtZXRhIjogeyJoZWFkZXIiOiBbeyJ0eXBlIjogInRva2VuIn0sIHsidHlwZSI6ICJjb25zdHJhaW50In0sIHsidHlwZSI6ICJtYXBwaW5nIn1dfSwgInJvd3MiOiBbWyLgppXgp43gp5wkIiwgIioiLCAia3IiXSwgWyLgpqEiLCAiKiIsICJkIl1dfQo=") }))
    error_message = "The layer hash must be computed from the list content."
  }

  assert {
    condition     = try(startswith(local_sensitive_file.ref_list_files["map-person-script@v0-5-0"].filename, data.archive_file.ref_lists_layer[0].source_dir), false)
    error_message = "The zip must be built from the list files on disk. Zip content passed as a string is converted to NFC."
  }
}

run "layer_is_published_again_when_a_list_changes" {
  command = plan

  override_data {
    target = data.aws_s3_object.ref_list_files
    values = {
      body_base64 = "eyJtZXRhIjogeyJoZWFkZXIiOiBbeyJ0eXBlIjogInRva2VuIn0sIHsidHlwZSI6ICJjb25zdHJhaW50In0sIHsidHlwZSI6ICJtYXBwaW5nIn1dfSwgInJvd3MiOiBbWyLgppXgp43gp5wkIiwgIioiLCAia3IiXSwgWyLgpqEiLCAiKiIsICJkaCJdXX0K"
    }
  }

  assert {
    condition     = aws_lambda_layer_version.ref_lists[0].source_code_hash != sha256(jsonencode({ "map-person-script@v0-5-0" = sha256("eyJtZXRhIjogeyJoZWFkZXIiOiBbeyJ0eXBlIjogInRva2VuIn0sIHsidHlwZSI6ICJjb25zdHJhaW50In0sIHsidHlwZSI6ICJtYXBwaW5nIn1dfSwgInJvd3MiOiBbWyLgppXgp43gp5wkIiwgIioiLCAia3IiXSwgWyLgpqEiLCAiKiIsICJkIl1dfQo=") }))
    error_message = "A changed list must change the layer hash, so that the layer is published again."
  }
}

run "no_layer_without_external_reference_lists" {
  command = plan

  variables {
    external_reflists = []
  }

  assert {
    condition     = length(aws_lambda_layer_version.ref_lists) == 0 && output.etm_ref_lists_layer_arn == null
    error_message = "Without external reference lists there must be no layer."
  }
}
