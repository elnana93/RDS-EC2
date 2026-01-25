




data "aws_ami" "al2023" {
  most_recent = true
  owners      = var.ami_owners

  filter {
    name   = "name"
    values = [var.ami_name_pattern]
  }
}

locals {
  startup_b64 = base64encode(file("${path.module}/startup.sh"))
}

resource "aws_instance" "lab_ec2_app" {
  ami                  = data.aws_ami.al2023.id
  instance_type        = var.instance_type
  key_name             = var.key_name
  iam_instance_profile = aws_iam_instance_profile.lab_ec2_profile.name

  vpc_security_group_ids = [aws_security_group.sg_ec2_lab.id]
  subnet_id              = aws_subnet.public_subnet["public_a"].id

  user_data_replace_on_change = true

  tags = merge(
    { Name = var.instance_name },
    var.extra_tags
  )

  # inside your aws_instance resource:
  user_data = <<-EOF
#!/bin/bash
set -euxo pipefail

printf '%s' '${local.startup_b64}' | base64 -d > /usr/local/bin/startup.sh
chmod +x /usr/local/bin/startup.sh

/usr/local/bin/startup.sh > /var/log/startup.log 2>&1
EOF


}

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
        Resource = "*"
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
      }

    ]
  })
}


# Instance Profile (this is what EC2 attaches)
resource "aws_iam_instance_profile" "lab_ec2_profile" {
  name = "lab-ec2-secrets-profile"
  role = aws_iam_role.lab_ec2_role.name
}

output "lab_ec2_instance_profile_name" {
  value = aws_iam_instance_profile.lab_ec2_profile.name
}

output "lab_ec2_public_ip" {
  value = aws_instance.lab_ec2_app.public_ip
}

output "lab_ec2_public_dns" {
  value = aws_instance.lab_ec2_app.public_dns
}

output "lab_ec2_public_url" {
  value = "http://${coalesce(aws_instance.lab_ec2_app.public_dns, aws_instance.lab_ec2_app.public_ip)}"
}

output "lab_ec2_ssh_command" {
  description = "SSH command to connect to the EC2 instance (Amazon Linux 2023)."
  value       = "ssh -i ${path.module}/${var.key_name}.pem ec2-user@${coalesce(aws_instance.lab_ec2_app.public_dns, aws_instance.lab_ec2_app.public_ip)}"
}
