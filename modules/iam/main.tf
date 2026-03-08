module "this" {
  source  = "cloudposse/label/null"
  version = "0.25.0"
  name    = var.name
  context = var.context
}

# 1. Роль для Lambda-функцій вашого проекту
resource "aws_iam_role" "this" {
  name               = module.this.id
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
  tags = module.this.tags
}

# 2. Виправлена політика з унікальним іменем для DynamoDB
resource "aws_iam_policy" "dynamodb" {
  name   = "${module.this.id}-db-policy" # Змінено суфікс для уникнення Error 409
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = var.dynamodb_actions
      Effect   = "Allow"
      Resource = var.dynamodb_table_arn
    }]
  })
}

# 3. Прив'язка нової політики до ролі
resource "aws_iam_role_policy_attachment" "dynamodb_attach" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.dynamodb.arn
}