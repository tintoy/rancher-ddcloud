# This is the NFS host used to serve data volumes.
#
# All other host node provisioning is performed from this host (by Rancher) using docker-machine-driver-ddcloud.
resource "ddcloud_server" "storage_host" {
	name					= "storage"
	description				= "Storage (NFS) host"
	admin_password			= "${var.ssh_bootstrap_password}"

	auto_start				= true

	memory_gb				= 8
	cpu_count				= 2
	cpu_speed				= "STANDARD"
	cores_per_cpu			= 1

	networkdomain			= "${ddcloud_networkdomain.rancher.id}"

	primary_network_adapter {
		vlan				= "${ddcloud_vlan.primary.id}"
		ipv4				= "${cidrhost(var.primary_network, 30)}"
	}

	dns_primary				= "8.8.8.8"
	dns_secondary			= "8.8.4.4"

	disk {
		scsi_unit_id		= 0
		size_gb				= 20
		speed				= "STANDARD"
	}

    disk {
		scsi_unit_id		= 1
		size_gb				= 60
		speed				= "STANDARD"
	}

	image					= "Ubuntu 14.04 2 CPU"

	tag {
		name                = "roles"
		value				= "storage"
	}
}

# The Rancher host must be publicly accessible for provisioning.
resource "ddcloud_nat" "storage_host" {
	networkdomain	= "${ddcloud_networkdomain.rancher.id}"
	private_ipv4	= "${ddcloud_server.storage_host.primary_adapter_ipv4}"
}
resource "ddcloud_firewall_rule" "storage_host_ssh_in" {
	name				= "storage.host.ssh.inbound"
	placement			= "first"
	action				= "accept"
	enabled				= true

	ip_version			= "ipv4"
	protocol			= "tcp"

	source_address_list	= "${ddcloud_address_list.clients.id}"

	destination_address	= "${ddcloud_nat.storage_host.public_ipv4}"
	destination_port	= 22 # SSH

	networkdomain		= "${ddcloud_networkdomain.rancher.id}"
}

# Install an SSH key so that Ansible doesnt make us jump through hoops to authenticate.
resource "null_resource" "storage_host_ssh" {
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

			host 		= "${ddcloud_nat.storage_host.public_ipv4}"
		}
	}
}
