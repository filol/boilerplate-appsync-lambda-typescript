data "aws_iam_policy_document" "lambda_assume_role_document" {
  version = "2012-10-17"

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    effect = "Allow"
  }
}

data "aws_iam_policy_document" "lambda_document" {
  version = "2012-10-17"

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "cloudwatch:PutMetricData",
      "kms:*",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "lambda_policy" {
  policy = data.aws_iam_policy_document.lambda_document.json
}

resource "aws_iam_role" "lambda_role" {
  name               = "${var.namespace}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_document.json

}

resource "aws_iam_policy_attachment" "lambda_attachment" {
  name = "${var.namespace}-attachment"

  roles = [
    aws_iam_role.lambda_role.name,
  ]

  policy_arn = aws_iam_policy.lambda_policy.arn
}

# -----------------------------------------------------------------------------
# AppSync: DataSource
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "datasource_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      identifiers = [
        "appsync.amazonaws.com",
      ]
      type = "Service"
    }
  }
}

resource "aws_iam_role" "lambda_datasource_role" {
  assume_role_policy = data.aws_iam_policy_document.datasource_assume_role.json
  name               = "${var.namespace}-appsync-lambda-datasource"
}

resource "aws_iam_role_policy_attachment" "invoke_lambda" {
  policy_arn = aws_iam_policy.lambda_invoke_lambda.arn
  role       = aws_iam_role.lambda_datasource_role.name
}
