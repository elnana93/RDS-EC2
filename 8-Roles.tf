
# Role (trust policy ONLY)
resource "aws_iam_role" "lab_ec2_role" {
  name = "lab-ec2-secrets-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Permissions (what the role can do)
resource "aws_iam_role_policy" "lab_ec2_permissions" {
  name = "lab-ec2-permissions"
  role = aws_iam_role.lab_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Allow your EC2 instance to read the DB secret
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        # Tighten this to your real secret ARN if you have it
        # I got tired of replaceing arn credentials when I terraform destroy/create, so fould
        # this online
        Resource = "arn:aws:secretsmanager:us-west-2:676373376093:secret:lab/rds/mysql-*"
      },

      # To get my secrets
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:ListSecrets"]
        Resource = "*"
      },

      # Allow basic EC2 read-only troubleshooting from inside the instance
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeRouteTables",
          "ec2:DescribeVpcs"
        ]
        Resource = "*"
      },

      # RDS describe permissions for troubleshooting
      {
        Effect = "Allow"
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBSubnetGroups"
        ]
        Resource = "*"
      },


      # Allow EC2 to read Lambda config (verification / troubleshooting)

      {
        Effect = "Allow"
        Action = [
          "lambda:GetFunctionConfiguration",
          "lambda:GetFunction"
        ]
        Resource = "arn:aws:lambda:us-west-2:676373376093:function:RotationSchedule-MySQLSingleUser-Lambda"
      },

      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetResourcePolicy"
        ]
        Resource = "arn:aws:secretsmanager:us-west-2:676373376093:secret:lab/rds/mysql-*"
      }


    ]
  })
}

# Instance Profile (this is what EC2 attaches)
resource "aws_iam_instance_profile" "lab_ec2_profile" {
  name = "lab-ec2-secrets-profile"
  role = aws_iam_role.lab_ec2_role.name
}


























# Trust policy so Lambda can assume the role
resource "aws_iam_role" "rotation_lambda_role" {
  name = "rotation-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# CloudWatch Logs (required for debugging)
resource "aws_iam_role_policy_attachment" "rotation_logs" {
  role       = aws_iam_role.rotation_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# OPTIONAL: only if Lambda is in VPC (private subnets)
resource "aws_iam_role_policy_attachment" "rotation_vpc" {
  role       = aws_iam_role.rotation_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}


resource "aws_iam_role_policy" "rotation_secrets" {
  name = "rotation-secrets-policy"
  role = aws_iam_role.rotation_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecretVersionStage",
          "secretsmanager:ListSecretVersionIds"
        ]
        Resource = aws_secretsmanager_secret.rds_mysql.arn
      },
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetRandomPassword"]
        Resource = "*"
      }
    ]
  })
}
