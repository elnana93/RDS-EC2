
resource "aws_db_subnet_group" "lab_mysql" {
  name = "lab-mysql-subnet-group"
  subnet_ids = [
    aws_subnet.private_subnet["private_a"].id,
    aws_subnet.private_subnet["private_b"].id,
    # aws_subnet.private_subnet["private_c"].id, # optional
  ]

  tags = { Name = "lab-mysql-subnet-group" }
}



resource "aws_db_instance" "lab_mysql" {
  identifier = "lab-mysql"

  engine            = "mysql"
  instance_class    = "db.t3.micro" # free-tier-ish
  allocated_storage = 20
  storage_type      = "gp3"

  username = "admin"

  # ✅ Best practice for labs: RDS generates/stores master password in Secrets Manager
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.lab_mysql.name
  vpc_security_group_ids = [aws_security_group.sg_rds_lab.id]
  publicly_accessible    = false

  multi_az            = false
  deletion_protection = false
  skip_final_snapshot = true

  tags = { Name = "lab-mysql" }
}

output "rds_endpoint" {
  value = aws_db_instance.lab_mysql.address
}

output "rds_secret_arn" {
  value = aws_db_instance.lab_mysql.master_user_secret[0].secret_arn
}
