# This is to optionally manage the CloudWatch Log Group for the Lambda Function.
# If skipping this resource configuration, also add "logs:CreateLogGroup" to the IAM policy below.
resource "aws_cloudwatch_log_group" "log_group_ref" {
  name              = "/aws/lambda/${aws_lambda_function.lambda_function_ref.function_name}"
  retention_in_days = 14
}

# See also the following AWS managed policy: AWSLambdaBasicExecutionRole
# Here we're creating a policy (permissions policy) that is similar to AWS's AWSLambdaBasicExecutionRole.
resource "aws_iam_policy" "iam_policy_for_lambda_logging_ref" {
  name = "lambda_logging_iam_policy"
  path = "/"
  description = "IAM policy for logging from a lambda."
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role" "iam_role_for_lambda_ref" {
  name = "go_lambda_iam_role"
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

# Add permissions (permission policies) to the role
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role = "${aws_iam_role.iam_role_for_lambda_ref.name}"
  policy_arn = "${aws_iam_policy.iam_policy_for_lambda_logging_ref.arn}"
}

resource "aws_lambda_function" "lambda_function_ref" {
  filename         = "main.zip"
  function_name    = "multiendpoint_go_lambda"
  role             = "${aws_iam_role.iam_role_for_lambda_ref.arn}"
  handler          = "main"
  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("main.zip"))}"
  source_code_hash = "${filebase64sha256("main.zip")}"
  runtime          = "go1.x"
}

resource "aws_api_gateway_rest_api" "api_gateway_ref" {
    name        = "api_gateway_go_lambda"
    description = "Proxy to handle requests to our API."
    endpoint_configuration {
        types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "api_gateway_ref_resource_ref" {
  rest_api_id = "${aws_api_gateway_rest_api.api_gateway_ref.id}"
  parent_id   = "${aws_api_gateway_rest_api.api_gateway_ref.root_resource_id}"
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "api_gateway_method_ref" {
  rest_api_id   = "${aws_api_gateway_rest_api.api_gateway_ref.id}"
  resource_id   = "${aws_api_gateway_resource.api_gateway_ref_resource_ref.id}"
  http_method   = "ANY"
  authorization = "NONE"
#   request_parameters = {
#     "method.request.path.proxy" = true
#   }
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id = "${aws_api_gateway_rest_api.api_gateway_ref.id}"
  resource_id = "${aws_api_gateway_resource.api_gateway_ref_resource_ref.id}"
  http_method = "${aws_api_gateway_method.api_gateway_method_ref.http_method}"
  integration_http_method = "ANY"
  type                    = "AWS_PROXY" #LAMBDA_PROXY
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.lambda_function_ref.arn}/invocations"
}

resource "aws_lambda_permission" "lambda_permission_ref" {
  //statement_id  = "AllowMyDemoAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda_function_ref.function_name}"
  principal     = "apigateway.amazonaws.com"
  # The /*/*/* part allows invocation from any stage, method and resource path
  # within API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.api_gateway_ref.execution_arn}/*/*/*"
}
