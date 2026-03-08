output "function_name" {
  value       = aws_lambda_function.this.function_name
  description = "Назва створеної Lambda функції"
}

output "arn" {
  value       = aws_lambda_function.this.arn
  description = "ARN створеної функції"
}

#  виправить помилку в apigw.tf
output "invoke_arn" {
  value       = aws_lambda_function.this.invoke_arn
  description = "ARN для виклику функції через API Gateway"
}