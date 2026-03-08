output "function_name" {
  value       = aws_lambda_function.this.function_name
  description = "Назва створеної Lambda функції"
}

output "function_arn" {
  value       = aws_lambda_function.this.arn
  description = "ARN створеної функції"
}