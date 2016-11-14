# This is the primary Docker host that will run Rancher.
#
# All other host node provisioning is performed from this host (by Rancher) using docker-machine-driver-ddcloud.
resource "ddcloud_server" "rancher_host" {
	name					= "rancher"
	description				= "Rancher Host"
	admin_password			= "${var.ssh_bootstrap_password}"

	auto_start				= true

	memory_gb				= 8
	cpu_count				= 2
	cpu_speed				= "STANDARD"
	cores_per_cpu			= 1

	networkdomain			= "${ddcloud_networkdomain.rancher.id}"
	primary_adapter_vlan	= "${ddcloud_vlan.primary.id}"
	primary_adapter_ipv4	= "${cidrhost(var.primary_network, 10)}"

	dns_primary				= "8.8.8.8"
	dns_secondary			= "8.8.4.4"

	disk {
		scsi_unit_id		= 0
		size_gb				= 20
		speed				= "STANDARD"
	}

	os_image_name			= "Ubuntu 14.04 2 CPU"
}

# The Rancher host must be publicly accessible for provisioning.
resource "ddcloud_nat" "rancher_host" {
	networkdomain	= "${ddcloud_networkdomain.rancher.id}"
	private_ipv4	= "${ddcloud_server.rancher_host.primary_adapter_ipv4}"
}
resource "ddcloud_firewall_rule" "rancher_host_ssh_in" {
	name				= "rancher.host.ssh.inbound"
	placement			= "first"
	action				= "accept"
	enabled				= true

	ip_version			= "ipv4"
	protocol			= "tcp"

	source_address		= "${var.client_ip}"

	destination_address	= "${ddcloud_nat.rancher_host.public_ipv4}"
	destination_port	= 22 # SSH

	networkdomain		= "${ddcloud_networkdomain.rancher.id}"
}

# Install an SSH key so that Ansible doesnt make us jump through hoops to authenticate.
module "rancher_host_ssh" {
	source		= "github.com/DimensionDataResearch/ddcloud-ssh-key"

	host_ip		= "${ddcloud_nat.rancher_host.public_ipv4}"

	username	= "root"
	password	= "${var.ssh_bootstrap_password}"
	ssh_key		= "${file(var.ssh_public_key_file)}"
}
