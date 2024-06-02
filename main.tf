resource "aws_vpc" "mainvpc" {
  cidr_block       = "10.244.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "mainvpc"
  }
}
resource "aws_subnet" "private_subnet_1" {
  vpc_id     = aws_vpc.mainvpc.id
  cidr_block = "10.244.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "private_subnet_1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id     = aws_vpc.mainvpc.id
  cidr_block = "10.244.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "private_subnet_2"
  }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id     = aws_vpc.mainvpc.id
  cidr_block = "10.244.128.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "public_subnet_1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id     = aws_vpc.mainvpc.id
  cidr_block = "10.244.127.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "public_subnet_2"
  }
}


resource "aws_security_group" "main_sg" {
  name        = "main_sg"
  vpc_id      = aws_vpc.mainvpc.id


  ingress {
    from_port       = 0
    to_port         = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
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



resource "aws_internet_gateway" "maininternetgateway" {
  vpc_id = aws_vpc.mainvpc.id

  tags = {
    Name = "maininternetgateway"
  }
}


#========== Route Table =========
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.mainvpc.id

  route {
    cidr_block = "10.244.0.0/16"
    gateway_id = "local"
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.maininternetgateway.id
  }


  tags = {
    Name = "private_route_table"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.mainvpc.id

  route {
    cidr_block = "10.244.0.0/16"
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
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "rta_private2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_route_table.id
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
  ami           = "ami-00beae93a2d981137"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_subnet_1.id
  key_name	= "us-east-1" 
  security_groups = [aws_security_group.main_sg.id]
  associate_public_ip_address = true
  user_data       = base64encode(file("userdata1.sh"))

  tags = {
    Name = "webserver-1"
  }
}

resource "aws_instance" "webserver-2" {
  ami           = "ami-00beae93a2d981137"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_subnet_2.id
  key_name	= "us-east-1"
  security_groups = [aws_security_group.main_sg.id]
  associate_public_ip_address = true
  user_data       = base64encode(file("userdata2.sh"))

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
	Name 		= "mainLB"
  }
}

output Loadbalancername {
value = aws_lb.myloadbalancer.dns_name
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
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.targetgroup1.arn
  }
}