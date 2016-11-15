# The top-level container for our resources.
resource "ddcloud_networkdomain" "rancher" {
	name		= "${var.networkdomain_name}"
	description	= "Rancher on CloudControl."

	datacenter	= "${var.datacenter}"
}

# The primary VLAN.
resource "ddcloud_vlan" "primary" {
	name				= "Rancher Primary"

	ipv4_base_address	= "${element(split("/", var.primary_network), 0)}"
	ipv4_prefix_size	= "${element(split("/", var.primary_network), 1)}"

	networkdomain		= "${ddcloud_networkdomain.rancher.id}"
}
