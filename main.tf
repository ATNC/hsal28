provider "aws" {
  region = "eu-central-1"  # Change to your preferred region
}

resource "aws_s3_bucket" "image_bucket" {
  bucket = "hsal28-image-conversion-bucket"  # Change to your desired bucket name

  tags = {
    Name        = "ImageConversionBucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.image_bucket.id
  acl    = "private"
}

resource "aws_iam_role" "lambda_role" {
  name = "hsal28_lambda_image_conversion_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "hsal28_lambda_image_conversion_policy"
  description = "IAM policy for image conversion Lambda function"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:s3:::hsal28-image-conversion-bucket/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_lambda_function" "image_conversion_function" {
  filename         = "lambda_image_conversion.zip"
  function_name    = "hsal28_image_conversion_function"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = filebase64sha256("lambda_image_conversion.zip")

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.image_bucket.bucket
    }
  }

  tags = {
    Name        = "ImageConversionFunction"
    Environment = "Dev"
  }
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.image_conversion_function.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.image_bucket.arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.image_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.image_conversion_function.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".jpeg"

  }

  depends_on = [aws_lambda_permission.allow_s3]
}