# These are the hosts that will be used as worker nodes.
resource "ddcloud_server" "worker" {
	count					= "${var.worker_count}"

	name					= "worker-${format("%02d", count.index + 1)}"
	description				= "Worker ${format("%02d", count.index + 1)}"
	admin_password			= "${var.ssh_bootstrap_password}"

	auto_start				= true

	memory_gb				= 8
	cpu_count				= 4
	cpu_speed				= "STANDARD"
	cores_per_cpu			= 1

	networkdomain			= "${ddcloud_networkdomain.rancher.id}"

	primary_network_adapter {
		vlan				= "${ddcloud_vlan.primary.id}"
		ipv4				= "${cidrhost(var.primary_network, 20 + count.index)}"
	}

	dns_primary				= "8.8.8.8"
	dns_secondary			= "8.8.4.4"

	disk {
		scsi_unit_id		= 0
		size_gb				= 20
		speed				= "STANDARD"
	}

	image					= "Ubuntu 14.04 2 CPU"

	tag {
		name                = "roles"
		value				= "worker"
	}
}

# The worker must be publicly accessible for provisioning.
resource "ddcloud_nat" "worker" {
	count			= "${var.worker_count}"

	networkdomain	= "${ddcloud_networkdomain.rancher.id}"
	private_ipv4	= "${element(ddcloud_server.worker.*.primary_adapter_ipv4, count.index)}"
}
resource "ddcloud_address_list" "workers" {
	name			= "Workers"
	ip_version		= "IPv4"

	addresses		= [ "${ddcloud_nat.worker.*.public_ipv4}" ]

	networkdomain	= "${ddcloud_networkdomain.rancher.id}"
}
resource "ddcloud_firewall_rule" "worker_ssh_in" {
	name						= "worker.ssh.inbound"
	placement					= "first"
	action						= "accept"
	enabled						= true

	ip_version					= "ipv4"
	protocol					= "tcp"

	source_address_list			= "${ddcloud_address_list.clients.id}"

	destination_address_list	= "${ddcloud_address_list.workers.id}"
	destination_port			= 22 # SSH

	networkdomain				= "${ddcloud_networkdomain.rancher.id}"
}

# Install an SSH key so that Ansible doesnt make us jump through hoops to authenticate.
resource "null_resource" "install_ssh_key" {
	count = "${var.worker_count}"

	# Install our SSH public key.
	provisioner "remote-exec" {
		inline = [
			"mkdir -p ~/.ssh",
			"chmod 700 ~/.ssh",
			"echo '${file(var.ssh_public_key_file)}' > ~/.ssh/authorized_keys",
			"chmod 600 ~/.ssh/authorized_keys",
			"passwd -d root"
		]

		connection {
			type 		= "ssh"
			
			user 		= "root"
			password 	= "${var.ssh_bootstrap_password}"

			host 		= "${element(ddcloud_nat.worker.*.public_ipv4, count.index)}"
		}
	}
}
