provider "libvirt" {
  uri = var.libvirt_connection_uri
}

provider "null" {
}