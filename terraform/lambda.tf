data "archive_file" "preprocess" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/preprocess"
  output_path = "${path.module}/lambda/preprocess.zip"
}

resource "aws_lambda_function" "preprocess" {
  function_name    = "mnist-preprocess"
  runtime          = "python3.8"
  handler          = "lambda_function.lambda_handler"
  timeout          = 60
  memory_size      = 256
  role             = aws_iam_role.lambda_role.arn
  filename         = data.archive_file.preprocess.output_path
  source_code_hash = data.archive_file.preprocess.output_base64sha256

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.main.bucket
    }
  }
}
