## Central Location for Few IMportant Variables.

## This Variables should be evaluated before applying the terraform project.

variable "region" {
default = "us-east-1"
}
variable "vpc_cidr_range" {
default = "10.244.0.0/16"
}
variable "private_subnet_1" {
default = "10.244.1.0/24"
}
variable "availability_zone_pvt_1" {
default ="us-east-1a"
}

variable "private_subnet_2" {
default = "10.244.2.0/24"
}
variable "availability_zone_pvt_2" {
default ="us-east-1b"
}

variable "public_subnet_1" {
default = "10.244.128.0/24"
}
variable "availability_zone_pub_1" {
default ="us-east-1a"
}
variable "public_subnet_2" {
default = "10.244.127.0/24"
}
variable "availability_zone_pub_2" {
default ="us-east-1b"
}
