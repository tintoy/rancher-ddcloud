#####
# DNS

provider "aws" {
	region     = "us-west-2"
	access_key = "${var.aws_access_key}"
	secret_key = "${var.aws_secret_key}"
}

#################
# Local variables
#
# Run setup.py to generate local-vars.json (where these values are supplied).
#
# variable "dns_domain_name"		{ }
# variable "dns_subdomain_name"	{ }
# variable "dns_hosted_zone_id"	{ }
# variable "aws_access_key"		{ }
# variable "aws_secret_key"		{ }

# Rancher
resource "aws_route53_record" "rancher_host" {
	type    = "A"
    ttl     = 60
    zone_id = "${var.dns_hosted_zone_id}"

    name    = "manage.${var.dns_subdomain_name}.${var.dns_domain_name}"
    records = ["${ddcloud_nat.rancher_host.public_ipv4}"]   
}
resource "aws_route53_record" "rancher_host_node" {
	type    = "A"
    ttl     = 60
    zone_id = "${var.dns_hosted_zone_id}"

    name    = "node.${var.dns_subdomain_name}.${var.dns_domain_name}"
    records = ["${ddcloud_server.rancher_host.primary_adapter_ipv4}"]   
}

# Workers
resource "aws_route53_record" "worker" {
	type    = "A"
    ttl     = 60
    zone_id = "${var.dns_hosted_zone_id}"

    name    = "${var.dns_subdomain_name}.${var.dns_domain_name}"
    records = ["${ddcloud_nat.worker.*.public_ipv4}"]   
}
resource "aws_route53_record" "worker_node" {
	count	= "${var.worker_count}"

    type    = "A"
    ttl     = 60
    zone_id = "${var.dns_hosted_zone_id}"

    name    = "${element(ddcloud_server.worker.*.name, count.index)}.node.${var.dns_subdomain_name}.${var.dns_domain_name}"
    records = ["${element(ddcloud_server.worker.*.primary_adapter_ipv4, count.index)}"]   
}