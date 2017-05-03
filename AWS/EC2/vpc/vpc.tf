data "aws_subnet" "vpc" {
	id = "${var.subnet}"
}