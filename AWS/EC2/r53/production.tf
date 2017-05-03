resource "aws_route53_record" "prod" {
    zone_id = "${var.hostedzone}"
    name = "${var.env}"
    type = "A"

    alias {
        name = "${aws_elb.prod.dns_name}"
        zone_id = "${aws_elb.prod.zone_id}"
        evaluate_target_health = true
    }

    depends_on = ["aws_elb.prod"]
}