variable "host_ips"	{ type = "list" }
variable "username" { default = "root" }
variable "password" { }
variable "ssh_key"  { }

resource "null_resource" "install_ssh_key" {
	count = "${length(var.host_ips)}"

	# Install our SSH public key.
	provisioner "remote-exec" {
		inline = [
			"mkdir -p ~/.ssh",
			"chmod 700 ~/.ssh",
			"echo '${var.ssh_key}' > ~/.ssh/authorized_keys",
			"chmod 600 ~/.ssh/authorized_keys",
			"passwd -d ${var.username}"
		]

		connection {
			type 		= "ssh"
			
			user 		= "${var.username}"
			password 	= "${var.password}"

			host 		= "${element(var.host_ips, count.index)}"
		}
	}
}
