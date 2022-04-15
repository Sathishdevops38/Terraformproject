resource "aws_iam_role" "Lambda_IAM" {
  name = "Lambda_IAM"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_function" "lambda" {
  # If the file is not in the current working directory you will need to include a 
  # path.module in the filename.
  filename      = var.filename
  function_name = var.function_name
  role          = aws_iam_role.Lambda_IAM.arn
  handler       = var.handler
  description   = var.description

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  #source_code_hash = filebase64sha256("lambda.zip")

  runtime = var.runtime

  environment {
    variables = {
      env = "dev"
    }
  }
  tags = {
    Name = "${var.env_prefix}-Lambda"
  }
}