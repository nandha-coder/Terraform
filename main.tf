## Use us-east-1 region before initilizing this environment
## VPC Creation and make it as a Default Tenancy

provider "aws" {
   region  = var.region
}

# Create a VPC

resource "aws_vpc" "mainvpc" {
  cidr_block       = var.vpc_cidr_range
  instance_tenancy = "default"

  tags = {
    Name = "mainvpc"
  }
}

## Subnet 1

resource "aws_subnet" "private_subnet_1" {
  vpc_id     = aws_vpc.mainvpc.id
  cidr_block = var.private_subnet_1
  availability_zone = var.availability_zone_pvt_1

  tags = {
    Name = "private_subnet_1"
  }
}

## Subnet 2

resource "aws_subnet" "private_subnet_2" {
  vpc_id     = aws_vpc.mainvpc.id
  cidr_block = var.private_subnet_2
  availability_zone = var.availability_zone_pvt_2

  tags = {
    Name = "private_subnet_2"
  }
}

## Subnet 3

resource "aws_subnet" "public_subnet_1" {
  vpc_id     = aws_vpc.mainvpc.id
  cidr_block = var.public_subnet_1
  availability_zone = var.availability_zone_pub_1

  tags = {
    Name = "public_subnet_1"
  }
}

## Subnet 4

resource "aws_subnet" "public_subnet_2" {
  vpc_id     = aws_vpc.mainvpc.id
  cidr_block = var.public_subnet_2
  availability_zone = var.availability_zone_pub_2

  tags = {
    Name = "public_subnet_2"
  }
}

## Security Group
/*
resource "aws_security_group" "main_sg" {
  name        = "main_sg"
  vpc_id      = aws_vpc.mainvpc.id
## Ingress Rules
  ingress {
    from_port       = 0
    to_port         = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
## Egress Rules
  egress {
    from_port       = 0
    to_port         = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "main_sg"
  }
}
*/
resource "aws_vpc_security_group_ingress_rule" "ingress_rule" {
  security_group_id = aws_vpc.mainvpc.default_security_group_id
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 0
  ip_protocol = "-1"
  to_port     = 0
}
resource "aws_vpc_security_group_egress_rule" "egress_rule" {
  security_group_id = aws_vpc.mainvpc.default_security_group_id
  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
  }
resource "aws_internet_gateway" "maininternetgateway" {
  vpc_id = aws_vpc.mainvpc.id

  tags = {
    Name = "maininternetgateway"
  }
}


#========== Route Table =========

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.mainvpc.id

  route {
    cidr_block = var.vpc_cidr_range
    gateway_id = "local"
        }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.maininternetgateway.id
  }

  tags = {
    Name = "public_route_table"
  }
}



resource "aws_route_table_association" "rta_private1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "rta_private2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "rta_public_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}
resource "aws_route_table_association" "rta_public_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}


resource "aws_instance" "webserver-1" {
  ami           = var.instance_ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.private_subnet_1.id
  security_groups = [aws_vpc.mainvpc.default_security_group_id]
  associate_public_ip_address = var.instance_public_ip
  user_data       = base64encode(file("svr1.sh"))

  tags = {
    Name = "webserver-1"
  }
}

resource "aws_instance" "webserver-2" {
  ami           = var.instance_ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.private_subnet_2.id
  security_groups = [aws_vpc.mainvpc.default_security_group_id]
  associate_public_ip_address = var.instance_public_ip
  user_data       = base64encode(file("svr2.sh"))

  tags = {
    Name = "webserver-2"
  }
}



resource "aws_lb" "myloadbalancer" {
  name               = "myloadbalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.main_sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  enable_deletion_protection = false

  tags = {
    Environment = "mainLB"
        Name            = "mainLB"
  }
}

output Loadbalancer_URL {
value = "http://${aws_lb.myloadbalancer.dns_name}"
}

##  Target Group

resource "aws_lb_target_group" "targetgroup1" {
  name     = "targetgroup1"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.mainvpc.id
}

## Target Group Attachment

resource "aws_lb_target_group_attachment" "attachment_1" {
  target_group_arn = aws_lb_target_group.targetgroup1.arn
  target_id        = aws_instance.webserver-1.id
  port             = 80
}


resource "aws_lb_target_group_attachment" "attachment_2" {
  target_group_arn = aws_lb_target_group.targetgroup1.arn
  target_id        = aws_instance.webserver-2.id
  port             = 80
}

## Listener

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.myloadbalancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.targetgroup1.arn
  }
}
