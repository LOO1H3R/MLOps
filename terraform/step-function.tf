# step-function.tf

resource "aws_sfn_state_machine" "pipeline" {
  name     = "mnist-pipeline"
  role_arn = aws_iam_role.step_functions_role.arn

  definition = <<EOF
  {
    "Comment": "MNIST Pipeline",
    "StartAt": "PreprocessData",
    "QueryLanguage": "JSONata",
    "States": {
      "PreprocessData": {
        "Resource": "${aws_lambda_function.preprocess.arn}",
        "Type": "Task",
        "Next": "Standardization"
      },

      "Standardization": {
        "Resource": "arn:aws:states:::sagemaker:createProcessingJob.sync",
        "Arguments": {
          "ProcessingResources": {
            "ClusterConfig": {
              "InstanceCount": 1,
              "InstanceType": "ml.t3.medium",
              "VolumeSizeInGB": 10
            }
          },
          "ProcessingInputs": [
            {
              "InputName": "input-1",
              "S3Input": {
                "S3Uri": "s3://terraform-bucket-luther-wisa/input/raw.csv",
                "LocalPath": "/opt/ml/processing/input",
                "S3DataType": "S3Prefix",
                "S3InputMode": "File",
                "S3DataDistributionType": "FullyReplicated",
                "S3CompressionType": "None"
              }
            },
            {
              "InputName": "code",
              "S3Input": {
                "S3Uri": "s3://terraform-bucket-luther-wisa/code/transform.py",
                "LocalPath": "/opt/ml/processing/input/code",
                "S3DataType": "S3Prefix",
                "S3InputMode": "File",
                "S3DataDistributionType": "FullyReplicated",
                "S3CompressionType": "None"
              }
            }
          ],
          "ProcessingOutputConfig": {
            "Outputs": [
              {
                "OutputName": "train_data",
                "S3Output": {
                  "S3Uri": "s3://terraform-bucket-luther-wisa/train",
                  "LocalPath": "/opt/ml/processing/output/train",
                  "S3UploadMode": "EndOfJob"
                }
              }
            ]
          },
          "AppSpecification": {
            "ImageUri": "257758044811.dkr.ecr.us-east-2.amazonaws.com/sagemaker-scikit-learn:0.20.0-cpu-py3",
            "ContainerEntrypoint": [
              "python3",
              "/opt/ml/processing/input/code/transform.py"
            ]
          },
          "StoppingCondition": {
            "MaxRuntimeInSeconds": 300
          },
          "RoleArn": "arn:aws:iam::312051717074:role/mnist-step-functions-role",
          "ProcessingJobName": "{% $states.context.Execution.Name %}"
        },
        "Type": "Task",
        "Next": "Train model (XGBoost)"
      },

      "Train model (XGBoost)": {
        "Resource": "arn:aws:states:::sagemaker:createTrainingJob.sync",
        "Arguments": {
          "AlgorithmSpecification": {
            "TrainingImage": "825641698319.dkr.ecr.us-east-2.amazonaws.com/xgboost:latest",
            "TrainingInputMode": "File"
          },
          "OutputDataConfig": {
            "S3OutputPath": "s3://terraform-bucket-luther-wisa/models"
          },
          "StoppingCondition": {
            "MaxRuntimeInSeconds": 86400
          },
          "ResourceConfig": {
            "InstanceCount": 1,
            "InstanceType": "ml.t3.medium",
            "VolumeSizeInGB": 30
          },
          "RoleArn": "arn:aws:iam::312051717074:role/mnist-step-functions-role",
          "InputDataConfig": [
            {
              "DataSource": {
                "S3DataSource": {
                  "S3DataDistributionType": "ShardedByS3Key",
                  "S3DataType": "S3Prefix",
                  "S3Uri": "s3://terraform-bucket-luther-wisa/train"
                }
              },
              "ChannelName": "train",
              "ContentType": "text/csv"
            }
          ],
          "HyperParameters": {
            "objective": "reg:logistic",
            "eval_metric": "rmse",
            "num_round": "5"
          },
          "TrainingJobName": "{% $states.context.Execution.Name %}"
        },
        "Type": "Task",
        "Next": "SageMaker CreateModel"
      },

      "SageMaker CreateModel": {
        "Resource": "arn:aws:states:::sagemaker:createModel",
        "Arguments": {
          "ExecutionRoleArn": "arn:aws:iam::312051717074:role/mnist-step-functions-role",
          "ModelName": "mnist-xgboost-model",
          "PrimaryContainer": {
            "Image": "825641698319.dkr.ecr.us-east-2.amazonaws.com/xgboost:latest",
            "ModelDataUrl": "{% $states.input.ModelArtifacts.S3ModelArtifacts %}"
          }
        },
        "Type": "Task",
        "Next": "SageMaker CreateEndpointConfig"
      },

      "SageMaker CreateEndpointConfig": {
        "Type": "Task",
        "Resource": "arn:aws:states:::sagemaker:createEndpointConfig",
        "Arguments": {
          "EndpointConfigName": "mnist-endpoint-config",
          "ProductionVariants": [
            {
              "ModelName": "mnist-xgboost-model",
              "VariantName": "AllTraffic",
              "InitialInstanceCount": 1,
              "InstanceType": "ml.m5.large"
            }
          ]
        },
        "Next": "SageMaker CreateEndpoint"
      },

      "SageMaker CreateEndpoint": {
        "Type": "Task",
        "Resource": "arn:aws:states:::sagemaker:createEndpoint",
        "Arguments": {
          "EndpointName": "mnist-endpoint",
          "EndpointConfigName": "mnist-endpoint-config"
        },
        "End": true
      }
    }
  }
  EOF
}
