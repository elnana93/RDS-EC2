############################
# EC2 IAM ROLE + POLICIES + INSTANCE PROFILE
############################

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

# Runtime: only what the app needs
resource "aws_iam_role_policy" "lab_ec2_permissions" {
  name = "lab-ec2-permissions"
  role = aws_iam_role.lab_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadDbSecret"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_secretsmanager_secret.rds_mysql.arn
      }
    ]
  })
}

resource "aws_iam_instance_profile" "lab_ec2_profile" {
  name = "lab-ec2-secrets-profile"
  role = aws_iam_role.lab_ec2_role.name
}

# Troubleshooting / instructor verification (optional)
resource "aws_iam_role_policy" "lab_ec2_troubleshooting" {
  name = "lab-ec2-troubleshooting"
  role = aws_iam_role.lab_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadSecretResourcePolicyOnly"
        Effect   = "Allow"
        Action   = ["secretsmanager:GetResourcePolicy"]
        Resource = aws_secretsmanager_secret.rds_mysql.arn
      },
      {
        Sid    = "RdsDescribeOnly"
        Effect = "Allow"
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBSubnetGroups"
        ]
        Resource = "*"
      },
      {
        Sid    = "Ec2DescribeOnly"
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
      {
        Sid    = "LambdaReadRotationFunctionOnly"
        Effect = "Allow"
        Action = [
          "lambda:GetFunctionConfiguration",
          "lambda:GetFunction"
        ]
        Resource = "arn:aws:lambda:us-west-2:676373376093:function:RotationSchedule-MySQLSingleUser-Lambda"
      },
      {
        Sid    = "IamIntrospectRoleOnly"
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:ListRolePolicies",
          "iam:GetRolePolicy",
          "iam:ListAttachedRolePolicies"
        ]
        Resource = aws_iam_role.lab_ec2_role.arn
      },
      {
        Sid      = "IamGetInstanceProfileOnly"
        Effect   = "Allow"
        Action   = ["iam:GetInstanceProfile"]
        Resource = aws_iam_instance_profile.lab_ec2_profile.arn
      },
      {
        Sid    = "IamReadAwsManagedPoliciesOnly"
        Effect = "Allow"
        Action = [
          "iam:GetPolicy",
          "iam:GetPolicyVersion"
        ]
        Resource = "arn:aws:iam::aws:policy/*"
      }
    ]

  })
}
