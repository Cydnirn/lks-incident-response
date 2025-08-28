terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data source to get base infrastructure outputs
data "terraform_remote_state" "base" {
  backend = "local"
  config = {
    path = "../base/terraform.tfstate"
  }
}

# Data source to get Ollama endpoint
data "terraform_remote_state" "llm" {
  backend = "local"
  config = {
    path = "../llm/terraform.tfstate"
  }
}



# Package the function code
data "archive_file" "cloudwatch-alarm" {
  type        = "zip"
  source_file = "../../../function/lks-cloudwatch-alarm.py"
  output_path = "${path.module}/lambda/lks-cloudwatch-alarm.zip"
}

data "archive_file" "incident-creation" {
  type        = "zip"
  source_file = "../../../function/lks-incident-creation.py"
  output_path = "${path.module}/lambda/lks-incident-creation.zip"
}

data "archive_file" "incident-report" {
  type        = "zip"
  source_file = "../../../function/lks-incident-report.py"
  output_path = "${path.module}/lambda/lks-incident-report.zip"
}

data "archive_file" "incident-notification-confirm" {
  type        = "zip"
  source_file = "../../../function/lks-incident-notification-confirm.py"
  output_path = "${path.module}/lambda/lks-incident-notification-confirm.zip"
}

data "archive_file" "vector-embedding" {
  type        = "zip"
  source_file = "../../../function/lks-vector-embedding.py"
  output_path = "${path.module}/lambda/lks-vector-embedding.zip"
}

data "archive_file" "apigw-mail-action-code" {
  type        = "zip"
  source_file = "../../../function/lks-apigw-mail-action.py"
  output_path = "${path.module}/lambda/lks-apigw-mail-action.zip"
}

data "archive_file" "handle-cpu" {
  type        = "zip"
  source_file = "../../../function/incident-handling/lks-handle-cpu.py"
  output_path = "${path.module}/lambda/lks-handle-cpu.zip"
}

data "archive_file" "handle-mem" {
  type        = "zip"
  source_file = "../../../function/incident-handling/lks-handle-mem.py"
  output_path = "${path.module}/lambda/lks-handle-mem.zip"
}

data "archive_file" "handle-crash" {
  type        = "zip"
  source_file = "../../../function/incident-handling/lks-handle-crash.py"
  output_path = "${path.module}/lambda/lks-handle-crash.zip"
}

data "archive_file" "handle-shutdown" {
  type        = "zip"
  source_file = "../../../function/incident-handling/lks-handle-shutdown.py"
  output_path = "${path.module}/lambda/lks-handle-shutdown.zip"
}

data "archive_file" "handle-error" {
  type        = "zip"
  source_file = "../../../function/incident-handling/lks-handle-error.py"
  output_path = "${path.module}/lambda/lks-handle-error.zip"
}

data "archive_file" "handle-success" {
  type        = "zip"
  source_file = "../../../function/lks-handle-success.py"
  output_path = "${path.module}/lambda/lks-handle-success.zip"
}

data "archive_file" "handle-failed" {
  type        = "zip"
  source_file = "../../../function/lks-handle-failed.py"
  output_path = "${path.module}/lambda/lks-handle-failed.zip"
}

module "cloudwatch-alarm" {
  source        = "../../modules/compute/lambda"
  function_name = "lks-cloudwatch-alarm"
  function_file = data.archive_file.cloudwatch-alarm.output_path
  function_environments = {
    "STEP_FUNCTION_ARN" = "arn:aws:states:us-east-1:284845684968:stateMachine:POC-1-Step-Functions"
  }
  function_iam_role = "arn:aws:iam::284845684968:role/LambdaRoleExample"
  runtime           = "python3.9"
  handler           = "lks-cloudwatch-alarm.cloudwatch_alarm_handler"
  layers            = ["arn:aws:lambda:us-east-1:284845684968:layer:IRS-Layers:3"]
}

module "incident-creation" {
  source        = "../../modules/compute/lambda"
  function_name = "lks-incident-creation"
  function_file = data.archive_file.incident-creation.output_path
  function_environments = {
    "INCIDENTS_TABLE" = "incident",
  }
  timeout           = 30
  function_iam_role = "arn:aws:iam::284845684968:role/LambdaRoleExample"
  runtime           = "python3.9"
  handler           = "lks-incident-creation.lambda_handler"
  layers            = ["arn:aws:lambda:us-east-1:284845684968:layer:IRS-Layers:3"]
}

module "incident-notification-confirm" {
  source        = "../../modules/compute/lambda"
  function_name = "lks-incident-notification-confirm"
  function_file = data.archive_file.incident-notification-confirm.output_path
  function_environments = {
    "INCIDENTS_TABLE" = "incident",
    "SNS_TOPIC_ARN"   = "arn:aws:sns:us-east-1:284845684968:Incident-Subscription",
    "API_GATEWAY_URL" = "https://pxpm0t28id.execute-api.us-east-1.amazonaws.com/prod"
  }
  function_iam_role = "arn:aws:iam::284845684968:role/LambdaRoleExample"
  runtime           = "python3.9"
  handler           = "lks-incident-notification-confirm.lambda_handler"
  layers            = ["arn:aws:lambda:us-east-1:284845684968:layer:IRS-Layers:3"]
}

module "incident-report" {
  source        = "../../modules/compute/lambda"
  function_name = "lks-incident-report"
  function_file = data.archive_file.incident-report.output_path
  function_environments = {
    "INCIDENTS_TABLE" = "incident",
    "OLLAMA_ENDPOINT" = data.terraform_remote_state.llm.outputs.llm_api_url,
    "OLLAMA_MODEL"    = "phi4-mini"
  }
  function_iam_role  = "arn:aws:iam::284845684968:role/LambdaRoleExample"
  runtime            = "python3.9"
  handler            = "lks-incident-report.lambda_handler"
  layers             = ["arn:aws:lambda:us-east-1:284845684968:layer:IRS-Layers:3"]
  vpc_config_enabled = true
  security_group_ids = [data.terraform_remote_state.base.outputs.all_traffict_security_group_id]
  subnet_ids = [
    data.terraform_remote_state.base.outputs.private_subnet_1_id,
    data.terraform_remote_state.base.outputs.private_subnet_2_id
  ]
}


module "apigw-mail-action" {
  source        = "../../modules/compute/lambda"
  function_name = "lks-apigw-mail-action"
  function_file = data.archive_file.apigw-mail-action-code.output_path
  function_environments = {
    "INCIDENT_TABLE"    = "incident",
    "STEP_FUNCTION_ARN" = "arn:aws:states:us-east-1:284845684968:stateMachine:POC-2-Step-Functions"
  }
  function_iam_role = "arn:aws:iam::284845684968:role/LambdaRoleExample"
  runtime           = "python3.9"
  handler           = "lks-apigw-mail-action.api_gateway_handler"
  layers            = ["arn:aws:lambda:us-east-1:284845684968:layer:IRS-Layers:3"]
}

module "vector-embedding" {
  source        = "../../modules/compute/lambda"
  function_name = "lks-vector-embedding"
  function_file = data.archive_file.vector-embedding.output_path
  function_environments = {
    "OLLAMA_ENDPOINT" = data.terraform_remote_state.llm.outputs.llm_api_url,
    "OLLAMA_MODEL"    = "phi4-mini",
    "DB_HOST"         = "database-1.cctsbkfnu57a.us-east-1.rds.amazonaws.com",
    "DB_PORT"         = "5432",
    "DB_USER"         = "postgres",
    "DB_PASSWORD"     = "postgres",
    "DB_NAME"         = "incidents"
  }
  function_iam_role  = "arn:aws:iam::284845684968:role/LambdaRoleExample"
  runtime            = "python3.9"
  handler            = "lks-vector-embedding.lambda_handler"
  layers             = ["arn:aws:lambda:us-east-1:284845684968:layer:IRS-Layers:3"]
  vpc_config_enabled = true
  security_group_ids = [data.terraform_remote_state.base.outputs.all_traffict_security_group_id]
  subnet_ids = [
    data.terraform_remote_state.base.outputs.private_subnet_1_id,
    data.terraform_remote_state.base.outputs.private_subnet_2_id
  ]
}

module "handle-cpu" {
  source                = "../../modules/compute/lambda"
  function_name         = "lks-handle-cpu"
  function_file         = data.archive_file.handle-cpu.output_path
  function_environments = null
  function_iam_role     = "arn:aws:iam::284845684968:role/LambdaRoleExample"
  runtime               = "python3.9"
  handler               = "lks-handle-cpu.resize_instance_handler"
  layers                = ["arn:aws:lambda:us-east-1:284845684968:layer:IRS-Layers:3"]
  vpc_config_enabled    = true
  security_group_ids    = [data.terraform_remote_state.base.outputs.all_traffict_security_group_id]
  subnet_ids = [
    data.terraform_remote_state.base.outputs.private_subnet_1_id,
    data.terraform_remote_state.base.outputs.private_subnet_2_id
  ]
}

module "handle-memory" {
  source        = "../../modules/compute/lambda"
  function_name = "lks-handle-memory"
  function_file = data.archive_file.handle-mem.output_path
  function_environments = {
    "PRIVATE_KEY"  = "value",
    "SSH_USER"     = "ubuntu",
    "SERVICE_NAME" = "example_service"
  }
  function_iam_role  = "arn:aws:iam::284845684968:role/LambdaRoleExample"
  runtime            = "python3.9"
  handler            = "lks-handle-mem.resize_instance_handler"
  layers             = ["arn:aws:lambda:us-east-1:284845684968:layer:IRS-Layers:3"]
  vpc_config_enabled = true
  security_group_ids = [data.terraform_remote_state.base.outputs.all_traffict_security_group_id]
  subnet_ids = [
    data.terraform_remote_state.base.outputs.private_subnet_1_id,
    data.terraform_remote_state.base.outputs.private_subnet_2_id
  ]
}

module "handle-crash" {
  source        = "../../modules/compute/lambda"
  function_name = "lks-handle-crash"
  function_file = data.archive_file.handle-crash.output_path
  function_environments = {
    "PRIVATE_KEY"  = "value",
    "SSH_USER"     = "ubuntu",
    "SERVICE_NAME" = "example_service"
  }
  function_iam_role  = "arn:aws:iam::284845684968:role/LambdaRoleExample"
  runtime            = "python3.9"
  handler            = "lks-handle-crash.restart_service_handler"
  layers             = ["arn:aws:lambda:us-east-1:284845684968:layer:IRS-Layers:3"]
  vpc_config_enabled = true
  security_group_ids = [data.terraform_remote_state.base.outputs.all_traffict_security_group_id]
  subnet_ids = [
    data.terraform_remote_state.base.outputs.private_subnet_1_id,
    data.terraform_remote_state.base.outputs.private_subnet_2_id
  ]
}

module "handle-shutdown" {
  source        = "../../modules/compute/lambda"
  function_name = "lks-handle-shutdown"
  function_file = data.archive_file.handle-shutdown.output_path
  function_environments = {
    "PRIVATE_KEY"  = "value",
    "SSH_USER"     = "ubuntu",
    "SERVICE_NAME" = "example_service"
  }
  function_iam_role  = "arn:aws:iam::284845684968:role/LambdaRoleExample"
  runtime            = "python3.9"
  handler            = "lks-handle-shutdown.restart_service_handler"
  layers             = ["arn:aws:lambda:us-east-1:284845684968:layer:IRS-Layers:3"]
  vpc_config_enabled = true
  security_group_ids = [data.terraform_remote_state.base.outputs.all_traffict_security_group_id]
  subnet_ids = [
    data.terraform_remote_state.base.outputs.private_subnet_1_id,
    data.terraform_remote_state.base.outputs.private_subnet_2_id
  ]
}

module "handle-error" {
  source                = "../../modules/compute/lambda"
  function_name         = "lks-handle-error"
  function_file         = data.archive_file.handle-error.output_path
  function_environments = null
  function_iam_role     = "arn:aws:iam::284845684968:role/LambdaRoleExample"
  runtime               = "python3.9"
  handler               = "lks-handle-error.restart_service_handler"
  layers                = ["arn:aws:lambda:us-east-1:284845684968:layer:IRS-Layers:3"]
  vpc_config_enabled    = true
  security_group_ids    = [data.terraform_remote_state.base.outputs.all_traffict_security_group_id]
  subnet_ids = [
    data.terraform_remote_state.base.outputs.private_subnet_1_id,
    data.terraform_remote_state.base.outputs.private_subnet_2_id
  ]
}

module "handle-success" {
  source        = "../../modules/compute/lambda"
  function_name = "lks-handle-success"
  function_file = data.archive_file.handle-success.output_path
  function_environments = {
    "INCIDENT_TABLE" = "incident",
    "SNS_TOPIC_ARN"  = "arn:aws:sns:us-east-1:284845684968:incident-notification"
  }
  function_iam_role = "arn:aws:iam::284845684968:role/LambdaRoleExample"
  runtime           = "python3.9"
  handler           = "lks-handle-success.restart_service_handler"
  layers            = ["arn:aws:lambda:us-east-1:284845684968:layer:IRS-Layers:3"]
}

module "handle-failed" {
  source        = "../../modules/compute/lambda"
  function_name = "lks-handle-failed"
  function_file = data.archive_file.handle-failed.output_path
  function_environments = {
    "INCIDENT_TABLE" = "incident",
    "SNS_TOPIC_ARN"  = "arn:aws:sns:us-east-1:284845684968:incident-notification"
  }
  function_iam_role = "arn:aws:iam::284845684968:role/LambdaRoleExample"
  runtime           = "python3.9"
  handler           = "lks-handle-success.restart_service_handler"
  layers            = ["arn:aws:lambda:us-east-1:284845684968:layer:IRS-Layers:3"]
}
