variable "source_dir" {
  type        = string
  description = "Шлях до папки з вихідним кодом Lambda"
}

variable "role_arn" {
  type        = string
  description = "ARN IAM ролі для цієї функції"
}

variable "dynamodb_table_name" {
  type        = string
  description = "Назва таблиці DynamoDB для доступу"
}