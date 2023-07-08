resource "libvirt_pool" "cluster" {
  name = "cluster"
  type = "dir"
  path = "/opt/kvm/pool"
}

resource "libvirt_volume" "kap-instance" {
	name = "kap-instance"
	pool = libvirt_pool.cluster.name
	source = var.image_path
	format = "qcow2"
}