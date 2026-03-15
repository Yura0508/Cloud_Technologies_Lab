# --- SNS ТОПІКИ ---
resource "aws_sns_topic" "alerts" {
  name = "lambda-error-alerts"
}

# --- ПІДПИСКИ (Email) ---
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "@gmail.com"
}

# --- IAM РОЛЬ ДЛЯ NOTIFIER ---
resource "aws_iam_role" "notifier_role" {
  name = "lambda-notifier-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "lambda.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy_attachment" "notifier_logs" {
  role       = aws_iam_role.notifier_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# --- АРХІВАЦІЯ ТА LAMBDA ---
data "archive_file" "notifier_zip" {
  type        = "zip"
  source_dir  = "builds/slack-notifier"
  output_path = "builds/slack-notifier.zip"
}

resource "aws_lambda_function" "notifier" {
  filename         = data.archive_file.notifier_zip.output_path
  function_name    = "univ-lab4-notifier"
  role             = aws_iam_role.notifier_role.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  source_code_hash = data.archive_file.notifier_zip.output_base64sha256

  environment {
    variables = {
      # ПРАВИЛЬНО: ТІЛЬКИ ЧИСТИЙ ТЕКСТ БЕЗ ДУЖОК
      SLACK_WEBHOOK_URL = "https://hooks.slack.com"
    }
  }
}

# --- ПІДПИСКА LAMBDA НА SNS ---
resource "aws_sns_topic_subscription" "slack_sub" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.notifier.arn
}

resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.notifier.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alerts.arn
}

# --- КЕРУВАННЯ ЛОГАМИ ТА ПІДПИСКИ ---
locals {
  functions = ["get-all-courses", "save-course", "get-course", "update-course", "delete-course", "get-all-authors"]
}

resource "aws_cloudwatch_log_group" "monitored_groups" {
  for_each = toset(local.functions)
  name     = "/aws/lambda/univ-lab1-${each.value}"
  retention_in_days = 14
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.notifier.function_name
  principal     = "logs.eu-central-1.amazonaws.com"
}

resource "aws_cloudwatch_log_subscription_filter" "error_subs" {
  for_each        = toset(local.functions)
  name            = "${each.value}-error-filter"
  log_group_name  = aws_cloudwatch_log_group.monitored_groups[each.value].name
  filter_pattern  = "?ERROR ?Exception ?error"
  destination_arn = aws_lambda_function.notifier.arn
}

# --- ALARMS ДЛЯ КОНСОЛІ ---
resource "aws_cloudwatch_log_metric_filter" "alarm_filter" {
  name           = "LambdaErrorMetricFilter"
  pattern        = "ERROR"
  log_group_name = aws_cloudwatch_log_group.monitored_groups["delete-course"].name

  metric_transformation {
    name      = "CriticalErrorCount"
    namespace = "Univ/LambdaMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "visible_alarm" {
  alarm_name          = "univ-lab4-lambda-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "CriticalErrorCount"
  namespace           = "Univ/LambdaMetrics"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm for Lambda errors. Triggered by ERROR pattern."
  alarm_actions       = [aws_sns_topic.alerts.arn]
}