module "this" {
  source  = "cloudposse/label/null"
  version = "0.25.0"
  name    = var.name
  context = var.context
}

# Автоматичне створення ZIP-архіву з кодом
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.module}/files/${module.this.id}.zip"
}

resource "aws_lambda_function" "this" {
  function_name    = module.this.id
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  role             = var.role_arn
  handler          = "index.handler"
  runtime          = "nodejs18.x" # Актуальна версія Node.js

  # Передаємо назву таблиці через змінні оточення (Requirement #3)
  environment {
    variables = {
      TABLE_NAME = var.dynamodb_table_name
    }
  }

  tags = module.this.tags
}