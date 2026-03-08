variable "dynamodb_table_arn" {
  type        = string
  description = "ARN таблиці DynamoDB, до якої надається доступ"
}

variable "dynamodb_actions" {
  type    = list(string)
  default = ["dynamodb:Scan", "dynamodb:GetItem"] # За замовчуванням тільки читання
}