

locals {
  rotation_subnet_ids_csv = join(",", [
    aws_subnet.private_subnet["private_a"].id,
    aws_subnet.private_subnet["private_b"].id
  ])

  rotation_sg_ids_csv = join(",", [
    aws_security_group.rotation_lambda_sg.id
  ])
}







# Generate a strong password
# Generate a strong password
resource "random_password" "db" {
  length  = 24
  special = true
  /* # Ensures the password isn't regenerated unless explicitly changed
  lifecycle {
    ignore_changes = [length, special]
  } */
}

# Create the secret container
resource "aws_secretsmanager_secret" "rds_mysql" {
  name                    = "lab/rds/mysql"
  recovery_window_in_days = 0 # No recovery window for lab purposes

  #lifecycle { prevent_destroy = true} #use this in the office
}

# Put the secret value (JSON) into Secrets Manager
resource "aws_secretsmanager_secret_version" "rds_mysql" {
  secret_id = aws_secretsmanager_secret.rds_mysql.id

  secret_string = jsonencode({
    username = "admin"
    password = random_password.db.result
    engine   = "mysql"
    host     = aws_db_instance.lab_mysql.address
    port     = aws_db_instance.lab_mysql.port
    dbname   = aws_db_instance.lab_mysql.db_name
  })

  lifecycle {
    # CRITICAL: Prevents Terraform from overwriting the password 
    # if it is rotated by AWS Secrets Manager Rotation or manually in the console.
    ignore_changes = [secret_string]
  }
}






resource "aws_cloudformation_stack" "rds_mysql_rotation" {
  name = "lab-mysql-single-user-rotation"

  capabilities = [
    "CAPABILITY_IAM",
    "CAPABILITY_AUTO_EXPAND"
  ]

  template_body = <<-YAML
    AWSTemplateFormatVersion: '2010-09-09'
    Transform: AWS::SecretsManager-2024-09-16

    Parameters:
      SecretArn:
        Type: String
      DBInstanceId:
        Type: String
      VpcSubnetIds:
        Type: String
      VpcSecurityGroupIds:
        Type: String
      RotationDays:
        Type: Number
        Default: 30

    Resources:
      DbSecretAttachment:
        Type: AWS::SecretsManager::SecretTargetAttachment
        Properties:
          SecretId: !Ref SecretArn
          TargetId: !Ref DBInstanceId
          TargetType: AWS::RDS::DBInstance

      RotationSchedule:
        Type: AWS::SecretsManager::RotationSchedule
        DependsOn: DbSecretAttachment
        Properties:
          SecretId: !Ref SecretArn
          RotationRules:
            AutomaticallyAfterDays: !Ref RotationDays
          HostedRotationLambda:
            RotationType: MySQLSingleUser
            VpcSubnetIds: !Ref VpcSubnetIds
            VpcSecurityGroupIds: !Ref VpcSecurityGroupIds
  YAML

  parameters = {
    SecretArn    = aws_secretsmanager_secret.rds_mysql.arn
    DBInstanceId = aws_db_instance.lab_mysql.identifier

    VpcSubnetIds        = local.rotation_subnet_ids_csv
    VpcSecurityGroupIds = local.rotation_sg_ids_csv

    RotationDays = 30
  }
}
























































/* 

resource "aws_secretsmanager_secret_rotation" "rds_rotation" {
  # Use the ID from the version to ensure initial data exists first
  secret_id           = aws_secretsmanager_secret_version.rds_mysql.secret_id
  rotation_lambda_arn = aws_serverlessapplicationrepository_cloudformation_stack.mysql_rotator.outputs.RotationLambdaARN

  rotation_rules {
    automatically_after_days = 30
  }
}


# This pulls the official AWS RDS MySQL rotation template
resource "aws_serverlessapplicationrepository_cloudformation_stack" "mysql_rotator" {
  name           = "Rotate-RDS-MySQL-Lab"
  application_id = "arn:aws:serverlessrepo:us-west-2:297356107811:applications/SecretsManagerRDSMySQLRotationSingleUser"
  capabilities   = ["CAPABILITY_IAM", "CAPABILITY_RESOURCE_POLICY"]
  
  parameters = {
    endpoint = "https://secretsmanager.${var.aws_region}.amazonaws.com"
    functionName        = "rds-mysql-rotator"
    #vpcSubnetIds        = join(",", var.private_subnets)
    vpcSecurityGroupIds = aws_security_group.rotation_lambda_sg.id
  }
}
 */



/* 
variable "rotation_lambda_arn" {
  type        = string
  description = "The ARN of the Lambda function that rotates the secret"
}
 */




















/* # Enable rotation for the existing secret: lab/rds/mysql
resource "aws_secretsmanager_secret_rotation" "lab_rds_mysql" {
  secret_id           = aws_secretsmanager_secret.rds_mysql.id
  rotation_lambda_arn = aws_lambda_function.secretsmanager_rotation_mysql.arn

  # Console "Schedule expression builder" -> Hours: 24
  rotation_rules {
    schedule_expression = "rate(24 hours)"
    # Console "Window duration" -> 4h
    duration = "4h"
  }

  # Console checkbox: "Rotate immediately when the secret is stored"
  rotate_immediately = true
}
 */




/* 
resource "aws_secretsmanager_secret_target_attachment" "db_attachment" {
  secret_id  = aws_secretsmanager_secret.rds_mysql.id
  target_id  = aws_db_instance.lab_mysql.id
  target_type = "AWS::RDS::DBInstance"
} */