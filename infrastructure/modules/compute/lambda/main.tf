resource "aws_lambda_function" "function" {
  filename      = var.function_file
  function_name = var.function_name
  role          = var.function_iam_role
  handler       = var.handler
  runtime       = var.runtime
  memory_size   = var.memory_size
  ephemeral_storage {
    size = var.storage_size
  }

  timeout = var.timeout

  environment {
    variables = var.function_environments
  }

  dynamic "vpc_config" {
    for_each = var.vpc_config_enabled ? [1] : []
    content {
      security_group_ids = var.security_group_ids
      subnet_ids         = var.subnet_ids
    }
  }

  layers = var.layers
}
