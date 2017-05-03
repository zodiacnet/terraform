resource "aws_route53_record" "stage" {
	zone_id = "${var.hostedzone}"
	name = "${var.env}-staging"
	type = "A"

	alias {
		name = "${aws_elb.stage.dns_name}"
		zone_id = "${aws_elb.stage.zone_id}"
		evaluate_target_health = true
	}

	depends_on = ["aws_elb.stage"]
}