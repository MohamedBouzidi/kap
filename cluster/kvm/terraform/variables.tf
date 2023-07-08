variable "libvirt_connection_uri" {
    type = string
    description = "URI to connect to libvirt"
}

variable "domain" {
	type = string
	default = "dev.local"
	description = "Domain for KAP"
}

variable "cidr" {
	type = string
	default = "172.16.0.0/16"
	description = "CIDR for KAP"
}

variable "image_path" {
	type = string
	default = "/workspaces/kap/cluster/kvm/image-server/jammy-server-cloudimg-amd64.img"
	description = "Path to QCOW2 image"
}

variable "kvm_host" {
	type = string
	description = "KVM host address"
}

variable "kvm_sudo_user" {
	type = string
	description = "KVM host sudo user"
}

variable "kvm_sudo_password" {
	type = string
	description = "KVM host sudo password"
	sensitive = true
}