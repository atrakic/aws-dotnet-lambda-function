variable "enabled" {
  default     = true
  type        = bool
  description = "Set to false to prevent the module from creating any resources"
}

variable "function_name" {
  type        = string
  default     = "dotnet_lambda"
  description = "The name of the Lambda function"

}

locals {
  enabled = var.enabled ? true : false
}


resource "aws_iam_role" "lambda" {
  count = local.enabled ? 1 : 0

  name = "demo-lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "archive_file" "lambda_archive" {
  count = local.enabled ? 1 : 0

  type        = "zip"
  source_dir  = "src"
  output_path = "/tmp/lambda.zip"
}

resource "aws_lambda_function" "lambda" {
  count = local.enabled ? 1 : 0

  function_name = var.function_name
  role          = aws_iam_role.lambda[0].arn

  handler          = "dotnet_lambda::dotnet_lambda.Function::FunctionHandler"
  runtime          = "dotnet8"
  filename         = data.archive_file.lambda_archive[0].output_path
  source_code_hash = data.archive_file.lambda_archive[0].output_base64sha256
}

output "arn" {
  value = local.enabled ? join("", aws_lambda_function.lambda.*.arn) : ""
}

output "qualified_arn" {
  value = local.enabled ? join("", aws_lambda_function.lambda.*.qualified_arn) : ""
}

output "version" {
  value = local.enabled ? join("", aws_lambda_function.lambda.*.version) : ""
}

#output "print_aws_cli_usage" {
#  value = local.enabled ? format("aws lambda invoke --invocation-type RequestResponse --function-name %s --log-type Tail - | jq '.LogResult' -r | base64 --decode", local.function_name) : ""
#}

#output "print_aws_cli_get_function" {
#  value = local.enabled ? format("aws lambda get-function --function-name %s", local.function_name) : ""
#}
