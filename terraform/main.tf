provider "ddcloud" {
	region					= "AU"
	
	auto_create_tag_keys	= true
}

#################
# Local variables
#
# Run setup.py to generate local-vars.json (where these values are supplied).

variable "client_ip" 				{ }
variable "ssh_public_key_file"		{ }
variable "ssh_bootstrap_password"	{ }

#########
# Globals

variable "datacenter" 				{ default = "AU10" }

#########
# Network

variable "networkdomain_name"		{ default = "Rancher" }
variable "primary_network"			{ default = "10.0.12.0/24" }

#########
# Outputs

output "rancher_host_private_ip" {
	value = "${ddcloud_server.rancher_host.primary_adapter_ipv4}"
}
output "rancher_host_public_ip" {
	value = "${ddcloud_nat.rancher_host.public_ipv4}"
}
