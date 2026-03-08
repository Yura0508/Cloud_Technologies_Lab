# 2. SNS Topic - основний (для помилок Lambda в eu-central-1)
resource "aws_sns_topic" "alerts" {
  name = "univ-lab4-alerts"
}

# 2.1 SNS Topic - спеціально для Billing (обов'язково в us-east-1)
resource "aws_sns_topic" "billing_alerts_us_east_1" {
  provider = aws.us_east_1
  name     = "univ-lab4-billing-alerts"
}

# 3. Підписка через Email на обидва топіки
resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "urijkisil2007@gmail.com"
}

resource "aws_sns_topic_subscription" "billing_email_alert" {
  provider  = aws.us_east_1
  topic_arn = aws_sns_topic.billing_alerts_us_east_1.arn
  protocol  = "email"
  endpoint  = "urijkisil2007@gmail.com"
}

# 4. Явне створення Log Group
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/univ-lab1-get-all-courses"
  retention_in_days = 14
}

# 5. IAM Роль для Lambda Slack
resource "aws_iam_role" "slack_role" {
  name = "univ-lab4-slack-notifier-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "slack_logs" {
  role       = aws_iam_role.slack_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# 6. Архівація коду
data "archive_file" "slack_zip" {
  type        = "zip"
  source_dir  = "builds/slack-notifier"
  output_path = "builds/slack-notifier.zip"
}

# 7. Створення Lambda-функції для Slack (Node.js 20)
resource "aws_lambda_function" "slack_notifier" {
  filename         = data.archive_file.slack_zip.output_path
  function_name    = "univ-lab4-slack-notifier"
  role             = aws_iam_role.slack_role.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  source_code_hash = data.archive_file.slack_zip.output_base64sha256

  environment {
    variables = {
      # Видалено квадратні дужки та Markdown-посилання для коректної роботи
      SLACK_WEBHOOK_URL = "https://hooks.slack.com/services/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"
    }
  }
}

# 8. CloudWatch Metric Filter
resource "aws_cloudwatch_log_metric_filter" "lambda_errors" {
  name           = "LambdaErrorFilter"
  pattern        = "ERROR"
  log_group_name = aws_cloudwatch_log_group.lambda_log_group.name

  metric_transformation {
    name      = "CriticalErrorCount"
    namespace = "Univ/LambdaMetrics"
    value     = "1"
  }
}

# 9. Alarm на помилки в Lambda (eu-central-1)
resource "aws_cloudwatch_metric_alarm" "lambda_error_alarm" {
  alarm_name          = "univ-lab4-lambda-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "CriticalErrorCount"
  namespace           = "Univ/LambdaMetrics"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm на помилки Lambda"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}

# 10. Billing Alarm (us-east-1) - ВИПРАВЛЕНО
resource "aws_cloudwatch_metric_alarm" "billing_alarm" {
  provider            = aws.us_east_1
  alarm_name          = "univ-lab4-billing-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = 21600
  statistic           = "Maximum"
  threshold           = 5
  alarm_description   = "Alarm на перевищення бюджету $5"
  
  # Тепер посилається на топік у тому ж регіоні (us-east-1)
  alarm_actions       = [aws_sns_topic.billing_alerts_us_east_1.arn]

  dimensions = {
    Currency = "USD"
  }
}

# 11. Дозволи для SNS (основний топік + білінг топік)
resource "aws_lambda_permission" "sns_to_slack" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slack_notifier.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alerts.arn
}

resource "aws_lambda_permission" "sns_billing_to_slack" {
  statement_id  = "AllowExecutionFromBillingSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slack_notifier.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.billing_alerts_us_east_1.arn
}

# 12. Підписка Lambda на обидва SNS топіки
resource "aws_sns_topic_subscription" "slack_subscription" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_notifier.arn
}

resource "aws_sns_topic_subscription" "slack_billing_subscription" {
  provider  = aws.us_east_1
  topic_arn = aws_sns_topic.billing_alerts_us_east_1.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_notifier.arn
}