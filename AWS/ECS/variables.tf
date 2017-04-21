variable "appname" {
  description = "Name of the application, can be the subdomain name without '.com' this is also goign to be used to create the route53 record"
}

variable "key_name" {
  description = "Name of the ssh key to use, this must have been created on AWS console"
}

variable "aws_region" {
  description = "Desired Availability Zone to lauch the instance"
  default     = "us-west-1"
}

variable "subnet_id" {
  description = "VPC Subnet ID to use"
  default     = "subnet-0360925a"
}

variable "vpc_id" {
  description = "VPC id to use on the infrastructure creation"
  default = "vpc-057d5060"
}

variable "subnets" {
  type = "list"
  description = "list of subnets that it's going to be used to setup the ELB the first one it's going to be used as default subnet and the second one as anothere zone so the two subnets must be on different zones"
  default = ["subnet-a27795c6", "subnet-0e4a6257"]
}

variable "instance" {
  description = "Instance type"
}

variable "aws_amis" {
  default = {
    "ap-southeast-2" = "ami-2afbde4a"
  }
}
