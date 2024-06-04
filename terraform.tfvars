## This Variables should be evaluated before applying the terraform project.
region = "us-east-1"
vpc_cidr_range = "10.244.0.0/16"

private_subnet_1 = "10.244.1.0/24"
availability_zone_pvt_1 = "us-east-1a"

private_subnet_2 = "10.244.2.0/24"
availability_zone_pvt_2 = "us-east-1b"

public_subnet_1 = "10.244.128.0/24"
availability_zone_pub_1 = "us-east-1a"

public_subnet_2 = "10.244.127.0/24"
availability_zone_pub_2 = "us-east-1b"


instance_type = "t2.micro"
instance_ami_id = "ami-00beae93a2d981137"
instance_public_ip = "true"
