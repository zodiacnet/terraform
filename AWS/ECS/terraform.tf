provider "aws" {
  region = "${var.aws_region}"
}

resource "aws_ecs_cluster" "Production" {
  name = "${var.appname}"
}

resource "aws_ecr_repository" "dockerrepo" {
  name = "${var.appname}"
}

resource "aws_ecs_task_definition" "tskdef" {
  family = "${var.appname}"

  container_definitions = <<-EOF
[
  {
    "name": "${var.appname}",
    "image": "089393603951.dkr.ecr.ap-southeast-2.amazonaws.com/${var.appname}:latest",
    "cpu": 256,
    "memory": 256,
    "essential": true,
    "portMappings": [
     {
        "containerPort": 8080,
        "hostPort": 0
      }
    ]
  }
]
    EOF
}

resource "aws_iam_role" "ecsServiceRole" {
  name = "${var.appname}-ecsServiceRole"

  assume_role_policy = <<-EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
  EOF
  assume_role_policy = <<-EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}  
  EOF
}

resource "aws_iam_role" "ecsInstanceRole" {
  name = "${var.appname}-ecs"

  assume_role_policy = <<-EOF
{
"Version": "2012-10-17",
"Statement": [
  {
    "Effect": "Allow",
    "Principal": {
      "Service": "ecs.amazonaws.com"
    },
    "Action": "sts:AssumeRole"
  }
]
}
    EOF
}

resource "aws_iam_role_policy" "ecsPolicy" {
  name = "${var.appname}-instance-policy"
  role = "${aws_iam_role.ecsInstanceRole.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "autoscaling:Describe*",
                "autoscaling:UpdateAutoScalingGroup",
                "cloudformation:CreateStack",
                "cloudformation:DeleteStack",
                "cloudformation:DescribeStack*",
                "cloudformation:UpdateStack",
                "cloudwatch:GetMetricStatistics",
                "ec2:Describe*",
                "elasticloadbalancing:*",
                "ecs:*",
                "iam:ListInstanceProfiles",
                "iam:ListRoles",
                "iam:PassRole"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "instanceProfile" {
  name  = "${var.appname}-instance-profile"
  roles = ["${aws_iam_role.ecsInstanceRole.name}"]
}

resource "aws_iam_policy_attachment" "rolePolicy" {
  name       = "${var.appname}-ecsServiceRole1"
  roles      = ["${aws_iam_role.ecsServiceRole.id}"]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerServiceFullAccess"
}

resource "aws_alb_target_group" "dcl_alb_tg" {
  name     = "${var.appname}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"

  depends_on = ["aws_alb.dcl-lb"]
}

resource "aws_alb" "dcl-lb" {
  name            = "${var.appname}-alb"
  internal        = false
  security_groups = ["${aws_security_group.lb_sg.id}"]
  subnets         = "${var.subnets}"

  depends_on = ["aws_security_group.lb_sg"]
}

resource "aws_alb_listener" "front_end" {
  load_balancer_arn = "${aws_alb.dcl-lb.id}"
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.dcl_alb_tg.id}"
    type             = "forward"
  }
}

resource "aws_security_group" "lb_sg" {
  description = "access tot he applicacion ELB"
  vpc_id      = "${var.vpc_id}"
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
    to_port     = 8080
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_service" "srvc" {
  name                               = "${var.appname}"
  cluster                            = "${var.appname}"
  task_definition                    = "${aws_ecs_task_definition.tskdef.family}"
  desired_count                      = 1
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100
  iam_role                           = "${aws_iam_role.ecsServiceRole.arn}"

  load_balancer {
    target_group_arn = "${aws_alb_target_group.dcl_alb_tg.arn}"
    container_name   = "${var.appname}"
    container_port   = 8080
  }

  depends_on = ["aws_alb_target_group.dcl_alb_tg", "aws_iam_role.ecsServiceRole"]
}

resource "aws_launch_configuration" "dcl_lc" {
  name_prefix   = "testpoint-${var.appname}"
  image_id      = "ami-2afbde4a"
  instance_type = "t2.small"

  lifecycle {
    create_before_destroy = true
  }

  iam_instance_profile = "${aws_iam_instance_profile.instanceProfile.name}"
  key_name             = "${var.key_name}"

  user_data = <<-EOF
  #!/bin/bash
  echo ECS_CLUSTER="${var.appname}" >> /etc/ecs/ecs.config
  EOF
}

resource "aws_autoscaling_group" "dcl_as" {
  name                 = "${var.appname}"
  launch_configuration = "${aws_launch_configuration.dcl_lc.name}"
  min_size             = 1
  max_size             = 2
  vpc_zone_identifier  = ["${var.subnets[0]}"]
}

resource "aws_route53_record" "dcl_record" {
  zone_id = "Z1VXM80ILEGRIR"
  name    = "${var.appname}.highperformance.com"
  type    = "CNAME"
  ttl     = "300"
  records = ["${aws_alb.dcl-lb.dns_name}"]
}

resource "aws_autoscaling_policy" "agents-scale-up" {
  name                   = "agents-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.dcl_as.name}"
}

resource "aws_autoscaling_policy" "agents-scale-down" {
  name                   = "agents-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.dcl_as.name}"
}

resource "aws_cloudwatch_metric_alarm" "dcl-memory-high" {
  alarm_name          = "${var.appname}-mem-util-high-agents"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu for high utilization on agent hosts"

  alarm_actions = [
    "${aws_autoscaling_policy.agents-scale-up.arn}",
  ]

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.dcl_as.name}"
  }
}

resource "aws_cloudwatch_metric_alarm" "dcl-memory-low" {
  alarm_name          = "${var.appname}-mem-util-low-agents"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "40"
  alarm_description   = "This metric monitors ec2 cpu for low utilization on agent hosts"

  alarm_actions = [
    "${aws_autoscaling_policy.agents-scale-down.arn}",
  ]

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.dcl_as.name}"
  }
}
