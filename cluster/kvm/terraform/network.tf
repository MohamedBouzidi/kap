resource "null_resource" "kap_bridge" {
	connection {
	  type = "ssh"
	  user = var.kvm_sudo_user
	  password = var.kvm_sudo_password
	  host = var.kvm_host
	}

	provisioner "remote-exec" {
		inline = [
			"iptables -I FORWARD 1 -o virbr2 -d 172.17.0.0/16 -m conntrack --ctstate NEW,RELATED,ESTABLISHED --ctoriglist 10.188.0.0/32 -j ACCEPT"
		]
	}
}

resource "libvirt_network" "kap_network" {
	name = "kap-network"
	mode = "nat"
    autostart = true
	domain = var.domain
	addresses = [var.cidr]
	dhcp {
		enabled = true
	}
}
