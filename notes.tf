
/*

git commit -m "Almost done with the lab"

curl -I http://ec2-16-147-224-181.us-west-2.compute.amazonaws.com

after you ssh into your ec2 
check the logs here 

sudo systemctl status nginx --no-pager
curl -I http://localhost
ls -la /usr/share/nginx/html | head
sudo tail -n 80 /var/log/startup.log

terraform apply -replace="aws_instance.lab_ec2_app"

*/


/* 

List all security groups in a region

    Lets Goooooooo!

aws ec2 describe-security-groups \
      --region us-west-2 \
      --query "SecurityGroups[].{GroupId:GroupId,Name:GroupName,VpcId:VpcId}" \
      --output table
____________________________________________________________
Inspect a specific security group (inbound & outbound rules)

        RDS SG

      aws ec2 describe-security-groups \
      --group-ids sg-0a1a4397a0bf30371 \
      --region us-west-2 \
      --output json


        EC2 SG

      aws ec2 describe-security-groups \
      --group-ids sg-04c839603b222487c \
      --region us-west-2 \
      --output json
______________________________________________________________


      Verify which resources are using the security group EC2 instances

    aws ec2 describe-instances \
      --filters Name=instance.group-id,Values=sg-04c839603b222487c \
      --region us-west-2 \
      --query "Reservations[].Instances[].InstanceId" \
      --output table
______________________________________________________________

RDS instances

    aws rds describe-db-instances \
      --region us-west-2 \
      --query "DBInstances[?contains(VpcSecurityGroups[].VpcSecurityGroupId, 'sg-0a1a4397a0bf30371')].DBInstanceIdentifier" \
      --output table
______________________________________________________________

List all RDS instances

    aws rds describe-db-instances \
      --region us-west-2 \
      --query "DBInstances[].{DB:DBInstanceIdentifier,Engine:Engine,Public:PubliclyAccessible,Vpc:DBSubnetGroup.VpcId}" \
      --output table
______________________________________________________________

Inspect a specific RDS instance

    aws rds describe-db-instances \
      --db-instance-identifier lab-mysql \
      --region us-west-2 \
      --output json
______________________________________________________________

Verify RDS security groups explicitly

    aws rds describe-db-instances \
      --db-instance-identifier lab-mysql \
      --region us-west-2 \
      --query "DBInstances[].VpcSecurityGroups[].VpcSecurityGroupId" \
      --output table

_____________________________________________________________

Verify RDS subnet placement

    aws rds describe-db-subnet-groups \
      --region us-west-2 \
      --query "DBSubnetGroups[].{Name:DBSubnetGroupName,Vpc:VpcId,Subnets:Subnets[].SubnetIdentifier}" \
      --output table


      What you’re verifying
    Private subnets only
    No IGW route
    Correct AZ spread

    ______________________________________________________________
    Verify Network Exposure (Fast Sanity Checks)
Check if RDS is publicly reachable (quick flag)

    aws rds describe-db-instances \
      --db-instance-identifier lab-mysql \
      --region us-west-2 \
      --query "DBInstances[].PubliclyAccessible" \
      --output text

Expected output: false
______________________________________________________________
Verify Secrets Manager (Existence, Metadata, Access)

    aws secretsmanager list-secrets \
      --region us-west-2 \
      --query "SecretList[].{Name:Name,ARN:ARN,Rotation:RotationEnabled}" \
      --output table

What you’re verifying
    Secret exists
    Rotation state is known
    Naming is intentional

______________________________________________________________
Describe a specific secret (NO value exposure)

    aws secretsmanager describe-secret \
  --secret-id lab/rds/mysql \
  --region us-west-2 \
  --output json




Key fields to check
    RotationEnabled
    KmsKeyId
    LastChangedDate
    LastAccessedDate

This command is always safe. It does not expose the secret value.


 */




