resource "aws_instance" "prod"{
  ami = "${var.ami}"
  instance_type = "${lookup(var.instance_type,prod)}"

  subnet_id = "${var.subnet}"
  key_name = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.instance_sg.id}"]

  tags { 
    Name = "production-${var.env}"
    env  = "Prod"
    application = "${var.env}"
    role = "${var.env}"
    configuration_management = "ansible"
  }

  depends_on = ["aws_security_group.instance_sg"]
}

