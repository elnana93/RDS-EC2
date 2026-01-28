

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


  tags = {
    Name = "lab-rds-mysql"
  }
  /* tags = {

    SecretAccess = "lab-rds-mysql"

  }  */

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


data "aws_secretsmanager_secret_rotation" "mysql_rotation_cfg" {
  secret_id  = aws_secretsmanager_secret.rds_mysql.arn
  depends_on = [aws_cloudformation_stack.rds_mysql_rotation]
}

output "rotation_lambda_name_from_secret" {
  value = try(
    split(":", split("function:", data.aws_secretsmanager_secret_rotation.mysql_rotation_cfg.rotation_lambda_arn)[1])[0],
    null
  )
}












/* 
output "rds_mysql_rotation_stack_outputs" {
  value = aws_cloudformation_stack.rds_mysql_rotation.outputs
} */


/* output "rotation_lambda_name" {
  value = aws_cloudformation_stack.rds_mysql_rotation.outputs["RotationLambdaName"]
}

output "rotation_lambda_arn" {
  value = aws_cloudformation_stack.rds_mysql_rotation.outputs["RotationLambdaArn"]
}
 */