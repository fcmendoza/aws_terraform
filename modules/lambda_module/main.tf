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
  function_name  = "multiendpoint_go_lambda"
  s3_bucket      = "dummy-lambdas-bucket"
  s3_key         = "main.zip"
  handler        = "main"
  runtime        = "go1.x"
  role           = "${aws_iam_role.iam_role_for_lambda_ref.arn}"
  tags = {
      s3_bucket   = "s3://dummy-lambdas-bucket"
      s3_filename = "main.zip"
      #timestamp   = "${timestamp()}"
      timestamp   = "2019-05-05T04:12:52Z"
  }
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

resource "aws_api_gateway_integration" "api_gateway_integration_ref" {
  rest_api_id = "${aws_api_gateway_rest_api.api_gateway_ref.id}"
  resource_id = "${aws_api_gateway_resource.api_gateway_ref_resource_ref.id}"
  http_method = "${aws_api_gateway_method.api_gateway_method_ref.http_method}"
  integration_http_method = "POST" # Lambda function can only be invoked via POST.
  type                    = "AWS_PROXY" # LAMBDA_PROXY
  uri                     = "${aws_lambda_function.lambda_function_ref.invoke_arn}"
  # uri is lambda's invoke_arn. e.g.: arn:aws:apigateway:us-west-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-west-1:349352983199:function:multiendpoint_go_lambda/invocations
}

resource "aws_lambda_permission" "lambda_permission_ref" {
  #statement_id  = "AllowMyDemoAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda_function_ref.function_name}"
  principal     = "apigateway.amazonaws.com"
  # The /*/*/* part allows invocation from any stage, method and resource path
  # within API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.api_gateway_ref.execution_arn}/*/*/*"
  # source_arn' base is api gateways's "execution_arn". e.g.: arn:aws:execute-api:us-west-1:349352983199:0vc88vpz54
}

resource "aws_api_gateway_deployment" "api_gateway_deployment_ref" {
  depends_on = [
    "aws_api_gateway_integration.api_gateway_integration_ref"
  ]

  rest_api_id = "${aws_api_gateway_rest_api.api_gateway_ref.id}"
  stage_name  = "test"
}

#
# Create an ACM certificate
#

resource "aws_acm_certificate" "cert" {
  domain_name       = "api.losgatos.cloud"
  validation_method = "DNS"
  tags = {
    Environment = "test"
    Name = "api_losgatos_cloud_acm"
  }
  lifecycle {
    create_before_destroy = true
  }
}

data "aws_route53_zone" "zone" {
  name         = "losgatos.cloud."
  private_zone = false
}

resource "aws_route53_record" "aws_route53_record_cert_validation_ref" {
  name    = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_type}"
  zone_id = "${data.aws_route53_zone.zone.id}"
  records = ["${aws_acm_certificate.cert.domain_validation_options.0.resource_record_value}"]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "aws_acm_cert_validation_ref" {
  certificate_arn         = "${aws_acm_certificate.cert.arn}"
  validation_record_fqdns = ["${aws_route53_record.aws_route53_record_cert_validation_ref.fqdn}"]
}

#
# Create a custom domain name in API Gateway
#

resource "aws_api_gateway_domain_name" "domain" {
  domain_name              = "api.losgatos.cloud"
  regional_certificate_arn = "${aws_acm_certificate_validation.aws_acm_cert_validation_ref.certificate_arn}"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_base_path_mapping" "base_path_mapping" {
  api_id      = "${aws_api_gateway_rest_api.api_gateway_ref.id}"
  domain_name = "${aws_api_gateway_domain_name.domain.domain_name}"
  stage_name  = "${aws_api_gateway_deployment.api_gateway_deployment_ref.stage_name}"
}

#
# Create an A Recordset in Route 53
#

resource "aws_route53_record" "aws_route53_record_for_api_gateway_ref" {
  name    = "${aws_api_gateway_domain_name.domain.domain_name}"
  type    = "A"
  zone_id = "${data.aws_route53_zone.zone.id}"
  alias {
    evaluate_target_health = true
    name                   = "${aws_api_gateway_domain_name.domain.regional_domain_name}"
    zone_id                = "${aws_api_gateway_domain_name.domain.regional_zone_id}"
  }
}
