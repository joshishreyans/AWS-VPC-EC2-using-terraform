# AWS-VPC-EC2-using-terraform
This is a terraform project which creates a VPC, subnet, route table, internet gateway, security group, network interface and an EC2 instance with apache server.

- In the main.tf file replace the YOUR_ACCESS_KEY_ID and YOUR_SECRET_KEY with your access credentials obtained from AWS in line 12 and 13.
- Generate an EC2 instance key and put the name of the key in place of NAME_OF_YOUR_EC2_INSTANCE_KEY in line 131.
- Run terraform init to get the AWS plugins.
- Run terraform apply to deploy the infrastructure on AWS.
