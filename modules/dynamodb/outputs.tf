output "table_arn" {
  value       = aws_dynamodb_table.this.arn
  description = "ARN створеної таблиці"
}

output "table_name" {
  value = aws_dynamodb_table.this.name
}