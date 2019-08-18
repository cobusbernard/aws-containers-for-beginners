output "alb_dns" {
    value = "${aws_alb.webinar_alb.dns_name}"
}