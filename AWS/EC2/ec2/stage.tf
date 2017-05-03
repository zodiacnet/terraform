resource "aws_instance" "stage"{
  ami = "${var.ami}"
  instance_type = "${lookup(var.instance_type,stage)}"

  subnet_id = "${var.subnet}"
  key_name = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.instance_sg.id}"]

  tags { 
    Name = "staging-${var.env}"
    env  = "Staging"
    application = "${var.env}"
    role = "${var.env}"
    configuration_management = "ansible"
  }

  depends_on = ["aws_security_group.instance_sg"]
}

