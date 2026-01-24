

resource "aws_security_group" "sg_ec2_lab" {
  name        = "sgroup-ec2-lab"
  description = "Allow SSH and 3306"
  vpc_id      = aws_vpc.vpc["myvpc"].id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_cidr_blocks
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-ec2-lab"
  }
}

resource "aws_security_group" "sg_rds_lab" {
  name   = "sgroup-rds-lab"
  vpc_id = aws_vpc.vpc["myvpc"].id

  # ✅ Allow MySQL from EC2 SG only
  ingress {
    description     = "MySQL from EC2"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_ec2_lab.id]

    # No need to create a separate security_group_rule resource. 
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-rds-lab"
  }
}
