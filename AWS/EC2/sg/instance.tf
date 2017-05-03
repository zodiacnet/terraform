resource "aws_security_group" "instance_sg" {
  description = "general security group for the instances"
  vpc_id      = "${data.vpc.vpc_id}"
  name        = "${var.appname}-lb-sg"

  ingress {
    protocol    = "tcp"
    from_port   = 0
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 0
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol = "tcp"
    from_port = 0
    to_port = 22
    cidr_blocs = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}