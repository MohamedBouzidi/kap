resource "libvirt_cloudinit_disk" "commoninit" {
    name = "commoninit.iso"
    user_data = templatefile("${path.module}/cloud_init.cfg", {})
}

resource "libvirt_domain" "kap-domain" {
	name = "kap-instance"
	memory = "512"
	vcpu = 1

    cloudinit = libvirt_cloudinit_disk.commoninit.id

	network_interface {
		network_id = libvirt_network.kap_network.id
		wait_for_lease = true
		hostname = "kap-instance"
	}

    console {
        type = "pty"
        target_port = "0"
        target_type = "serial"
    }

    console {
        type = "pty"
        target_type = "virtio"
        target_port= "1"
    }

    disk {
        volume_id = libvirt_volume.kap-instance.id
    }

    graphics {
        type = "spice"
        listen_type = "address"
        autoport = true
    }
}