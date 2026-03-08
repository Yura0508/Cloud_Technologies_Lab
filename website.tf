# 1. S3 бакет для файлів фронтенду
resource "aws_s3_bucket" "frontend" {
  bucket = "${module.labels.id}-frontend"
  tags   = module.labels.tags
}

# Налаштування статичного хостингу
resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  index_document { suffix = "index.html" }
  error_document { key = "index.html" }
}

# 2. CloudFront OAI (для безпечного доступу)
resource "aws_cloudfront_origin_access_identity" "this" {
  comment = "OAI for ${module.labels.id}"
}

# 3. Доступ CloudFront до S3
resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "s3:GetObject"
      Effect    = "Allow"
      Resource  = "${aws_s3_bucket.frontend.arn}/*"
      Principal = { AWS = aws_cloudfront_origin_access_identity.this.iam_arn }
    }]
  })
}

# 4. CloudFront Distribution (CDN)
resource "aws_cloudfront_distribution" "frontend" {
  origin {
    domain_name = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.frontend.bucket}"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.this.cloudfront_access_identity_path
    }
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.frontend.bucket}"
    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }
    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# 5. Вивід фінального посилання
output "website_url" {
  value = "https://${aws_cloudfront_distribution.frontend.domain_name}"
}