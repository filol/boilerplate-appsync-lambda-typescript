locals {
  tags = {
    Project = var.namespace
    Owner   = "fdex24@gmail.com"
  }
}

# -----------------------------------------------------------------------------
# Lambda: function Hello World
# -----------------------------------------------------------------------------
data "archive_file" "function_archive" {
  type        = "zip"
  source_dir  = "${path.module}/../dist"
  output_path = "${path.module}/../dist/function.zip"
}

resource "aws_lambda_function" "lambdaHello" {
  filename         = data.archive_file.function_archive.output_path
  function_name    = "${var.namespace}-lambda-hello-ts"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.function_archive.output_base64sha256

  # Lambda Runtimes can be found here: https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html
  runtime     = "nodejs12.x"
  timeout     = "30"
  memory_size = 128
}

# -----------------------------------------------------------------------------
# AppSync: General
# -----------------------------------------------------------------------------
data "local_file" "schema" {
  filename = "${path.module}/../schema.graphql"
}

resource "aws_appsync_graphql_api" "_" {
  authentication_type = "API_KEY"
  name                = replace(var.namespace, "-", "_")

  schema = file("${path.module}/../schema.graphql")
}


# -----------------------------------------------------------------------------
# AppSync: IAM
# -----------------------------------------------------------------------------
data "template_file" "lambda_target_policy" {
  template = file("${path.module}/policies/lambda-policy.json")
  vars = {
    POLICY_ARN = aws_lambda_function.lambdaHello.arn
  }
}

resource "aws_iam_role" "lambda-role" {
  name               = "${aws_lambda_function.lambdaHello.function_name}-Role"
  assume_role_policy = file("${path.module}/policies/lambda-role.json")
}

resource "aws_iam_policy" "lambda_invoke_lambda" {
  name = "${aws_iam_role.lambda-role.name}-Policy"

  policy = data.template_file.lambda_target_policy.rendered
}

# -----------------------------------------------------------------------------
# AppSync: DataSource
# -----------------------------------------------------------------------------
//module "lambda-datasource" {
//  source = "./modules/lambda-datasource"
//
//  name                     = "datasourcelambdahello"
//  api_id                   = aws_appsync_graphql_api._.id
//  lambda_function_arn      = aws_lambda_function.lambdaHello.arn
//  invoke_lambda_policy_arn = aws_iam_policy.lambda_invoke_lambda.arn
//  role_name_prefix         = var.namespace
//  description              = "Datasource that call the Hello lambda"
//}

resource "aws_appsync_datasource" "lambda_datasource" {
  api_id      = aws_appsync_graphql_api._.id
  description = "Datasource that call the Hello lambda"

  lambda_config {
    function_arn = aws_lambda_function.lambdaHello.arn
  }

  name             = "datasourcelambdahello"
  service_role_arn = aws_iam_role.lambda_datasource_role.arn
  type             = "AWS_LAMBDA"
}


# -----------------------------------------------------------------------------
# AppSync: Resolver
# -----------------------------------------------------------------------------
resource "aws_appsync_resolver" "helloworld_lambda" {
  api_id      = aws_appsync_graphql_api._.id
  field       = "hello"
  type        = "Query"
  data_source = aws_appsync_datasource.lambda_datasource.name

  request_template = <<EOF
{
    "version" : "2017-02-28",
    "operation": "Invoke",
    "payload": {
    	"resolve": "hello"
    }
}
EOF

  response_template = <<EOF
    $util.toJson($context.result)
EOF
}