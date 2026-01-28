
/*

git commit -m "Updated"

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

   aws secretsmanager describe-secret \
  --secret-id lab/rds/mysql \
  --region us-west-2 \
  --query "{Name:Name,ARN:ARN,RotationEnabled:RotationEnabled,RotationLambdaARN:RotationLambdaARN}" \
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



aws secretsmanager get-resource-policy \
      --secret-id lab/rds/mysql \
      --region us-west-2 \
      --output json




Key fields to check
    RotationEnabled
    KmsKeyId
    LastChangedDate
    LastAccessedDate

This command is always safe. It does not expose the secret value.



aws lambda get-function-configuration \
  --function-name RotationSchedule-MySQLSingleUser-Lambda \
  --region us-west-2 \
  --query 'VpcConfig.SecurityGroupIds' \
  --output table


aws secretsmanager describe-secret \
  --secret-id arn:aws:secretsmanager:us-west-2:676373376093:secret:lab/rds/mysql-BxFfMI \
  --region us-west-2 \
  --query '{RotationEnabled:RotationEnabled, RotationLambdaARN:RotationLambdaARN}' \
  --output table




_______________________________________________________________


aws lambda get-function-configuration \
  --function-name RotationSchedule-MySQLSingleUser-Lambda \
  --region us-west-2 \
  --query 'VpcConfig' \
  --output table



aws lambda get-function-configuration \
  --function-name RotationSchedule-MySQLSingleUser-Lambda \
  --region us-west-2 \
  --query 'VpcConfig.{Subnets:SubnetIds,SecurityGroups:SecurityGroupIds,VpcId:VpcId}' \
  --output table


aws secretsmanager get-resource-policy \
      --secret-id lab/rds/mysql \
      --region us-west-2 \
      --output json


 aws ec2 describe-instances \
      --filters Name=tag:Name,Values=MyInstance \
      --region us-west-2 \
      --query "Reservations[].Instances[].InstanceId" \
      --output text


 */




/* 
Come back for this 

aws iam get-role-policy \
  --role-name lab-ec2-secrets-role \
  --policy-name lab-ec2-permissions \
  --query 'PolicyDocument.Statement' \
  --output json



aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" \
  --region us-west-2 \
  --query "Reservations[].Instances[].{InstanceId:InstanceId,State:State.Name,Name:Tags[?Key=='Name']|[0].Value,PrivateIp:PrivateIpAddress,PublicIp:PublicIpAddress}" \
  --output table


aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=lab_ec2_app" "Name=instance-state-name,Values=running" \
  --region us-west-2 \
  --query "Reservations[].Instances[].{InstanceId:InstanceId,Name:Tags[?Key=='Name']|[0].Value}" \
  --output table



aws iam get-instance-profile \
      --instance-profile-name lab_ec2_profile \
      --query "InstanceProfile.Roles[].RoleName" \
      --output text


 aws secretsmanager describe-secret \
      --secret-id lab/rds/mysql \
      --region us-west-2

 



aws iam get-policy-version \
      --policy-arn arn:aws:iam::aws:policy/SecretsManagerReadWrite \
      --version-id v5 \
      --output json



aws ec2 describe-instances \
  --instance-ids i-099e73181e5810705 \
  --region us-west-2 \
  --query "Reservations[0].Instances[0].SecurityGroups" \
  --output table






 */



/* 

 Verify IAM Role Permissions (Critical)
List policies attached to the role

 
 aws iam list-attached-role-policies \
  --role-name lab-ec2-secrets-role \
  --output table


aws iam list-role-policies \
  --role-name lab-ec2-secrets-role \
  --output table


aws iam get-role-policy \
  --role-name lab-ec2-secrets-role \
  --policy-name lab-ec2-permissions \
  --output json
 
 
 
  */