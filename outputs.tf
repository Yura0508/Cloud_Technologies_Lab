output "courses_table_arn" {
  value       = module.courses_table.table_arn
  description = "ARN таблиці курсів"
}

output "authors_table_arn" {
  value       = module.authors_table.table_arn
  description = "ARN таблиці авторів"
}