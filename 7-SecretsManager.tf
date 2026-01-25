
# Generate a strong password
resource "random_password" "db" {
  length  = 24
  special = true
}

# Create the secret container
resource "aws_secretsmanager_secret" "rds_mysql" {
  name = "lab/rds/mysql"
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
}











/* 

# Enable rotation for the existing secret: lab/rds/mysql
resource "aws_secretsmanager_secret_rotation" "lab_rds_mysql" {
  secret_id           = aws_secretsmanager_secret.rds_mysql.id
  rotation_lambda_arn = var.rotation_lambda_arn

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