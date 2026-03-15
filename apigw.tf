# 1. Створення самого REST API
resource "aws_api_gateway_rest_api" "this" {
  name        = module.labels.id
  description = "API for Course Application"
}

# 2. Опис ресурсів (шляхів)
resource "aws_api_gateway_resource" "authors" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "authors"
}

resource "aws_api_gateway_resource" "courses" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "courses"
}

resource "aws_api_gateway_resource" "course_id" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.courses.id
  path_part   = "{id}"
}

# 3. Інтеграції для ВСІХ 6 функцій 
# Використовуємо locals для зручності управління методами
locals {
  lambda_integrations = {
    "authors_get"    = { res = aws_api_gateway_resource.authors.id, method = "GET",    lambda = module.get_all_authors_lambda }
    "courses_get"    = { res = aws_api_gateway_resource.courses.id, method = "GET",    lambda = module.get_all_courses_lambda }
    "courses_post"   = { res = aws_api_gateway_resource.courses.id, method = "POST",   lambda = module.save_course_lambda }
    "course_id_get"  = { res = aws_api_gateway_resource.course_id.id, method = "GET",  lambda = module.get_course_lambda }
    "course_id_put"  = { res = aws_api_gateway_resource.course_id.id, method = "PUT",  lambda = module.update_course_lambda }
    "course_id_del"  = { res = aws_api_gateway_resource.course_id.id, method = "DELETE", lambda = module.delete_course_lambda }
  }
}

resource "aws_api_gateway_method" "methods" {
  for_each      = local.lambda_integrations
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = each.value.res
  http_method   = each.value.method
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integrations" {
  for_each                = local.lambda_integrations
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = each.value.res
  http_method             = aws_api_gateway_method.methods[each.key].http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = each.value.lambda.invoke_arn # Використовуємо output з модуля
}

# 4. Налаштування CORS (Вимога Домену 2) 
module "cors" {
  for_each = {
    authors   = aws_api_gateway_resource.authors.id
    courses   = aws_api_gateway_resource.courses.id
    course_id = aws_api_gateway_resource.course_id.id
  }
  source          = "squidfunk/api-gateway-enable-cors/aws"
  version         = "0.3.3"
  api_id          = aws_api_gateway_rest_api.this.id
  api_resource_id = each.value
}

# 5. Дозволи для Lambda 
resource "aws_lambda_permission" "apigw_lambda" {
  for_each      = local.lambda_integrations
  statement_id  = "AllowAPIGatewayInvoke-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda.function_name # Беремо ім'я прямо з модуля
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}

# 6. Розгортання API (Deployment + Stage) 
resource "aws_api_gateway_deployment" "this" {
  depends_on  = [aws_api_gateway_integration.integrations]
  rest_api_id = aws_api_gateway_rest_api.this.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "v1" {
  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = "v1"
}

# Вивід URL  API
output "base_url" {
  value = "${aws_api_gateway_stage.v1.invoke_url}/"
}