resource "aws_route53_record" "dev" {
	zone_id = "${var.hostedzone}"
	name = "${var.env}-dev"
	type = "A"

	alias {
		name = "${aws_elb.dev.dns_name}"
		zone_id = "{aws_elb.dev.zone_id}"
		evaluate_target_health = true
	}

	depends_on = ["aws_elb.dev"]
}