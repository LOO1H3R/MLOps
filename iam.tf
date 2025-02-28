# iam.tf
# Rol para Lambda
resource "aws_iam_role" "lambda_role" {
  name = "mnist-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}
# Política básica para Lambda
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
# Política para acceder a S3 desde Lambda
resource "aws_iam_role_policy" "lambda_s3_access" {
  name = "mnist-lambda-s3-access"
  role = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.main.arn}/*"
      }
    ]
  })
}
# Rol para Step Functions
resource "aws_iam_role" "step_functions_role" {
  name = "mnist-step-functions-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "sagemaker.amazonaws.com"
        }
      }
    ]
  })
}
# Política para Step Functions
resource "aws_iam_role_policy" "step_functions_policy" {
  name = "mnist-step-functions-policy"
  role = aws_iam_role.step_functions_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "iam:PassRole",
          "events:PutRule",
          "events:PutTargets",
          "sagemaker:CreateModel",
          "sagemaker:CreateEndpointConfig",
          "sagemaker:CreateEndpoint",
          "sagemaker:CreateTrainingJob",
          "sagemaker:CreateTransformJob",
          "sagemaker:CreateProcessingJob",
          "sagemaker:DescribeTrainingJob",
          "sagemaker:DescribeProcessingJob",
          "sagemaker:DescribeModel",
          "sagemaker:DeleteModel",
          "sagemaker:StopTrainingJob",
          "sagemaker:StopProcessingJob",
          "sagemaker:AddTags",
          "cloudwatch:PutMetricData",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:CreateLogGroup",
          "logs:DescribeLogStreams",
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = [
          "*",
          aws_iam_role.sagemaker_role.arn # ARN del rol de SageMaker
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ],
        Resource = "arn:aws:s3:::terraform-bucket-luther-wisaa/*",
      },
      {
        Effect   = "Allow"
        Action   = "s3:ListBucket"                                  # Permiso específico para listar el bucket
        Resource = "arn:aws:s3:::terraform-bucket-luther-wisaa" # Especifica el bucket
      }
    ]
  })
}
# Rol para SageMaker
resource "aws_iam_role" "sagemaker_role" {
  name = "mnist-sagemaker-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "sagemaker.amazonaws.com"
        }
      }
    ]
  })
}
# Política para SageMaker
resource "aws_iam_role_policy_attachment" "sagemaker_full" {
  role       = aws_iam_role.sagemaker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}
