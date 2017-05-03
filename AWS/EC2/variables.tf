variable "ami" {
	description = "AMI to be used to launch the instances"
}

variable "instance_type" {
	type = "map"
	description = "types for the Prod, staging and Dev instances"

	default = {
		prod = "m3.large"
		stage = "m1.small"
		dev = "m1.small"
	} 
}

variable "subnet" {
	description = "private subnet where the instance it's going to be launched"
}

variable "key_name" {
	description = "name of the key that it's going to be used, this mus be created on the AWS console"

}

variable "env" {
	description = "Name of the application, global environment, it's going to be used to name the instances"

}

variable "hostedzone" {
	description = "id of the hosted zone where the records are going to be created"

}

variable "sub_domain" {
	description = "subdomain that it's going to be used as base to create the env records (value+dev.somedomain.com), by default this value it's going to correspond to the production env"

}

variable "pub_subnet" {
	description = "public subnet where the Load Balancers are going to be launched"
}
