terraform {
  required_version = ">= 1.3.7"
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      version = "0.7.1"
    }
    null = {
      source = "hashicorp/null"
      version = "3.2.1"
    }
  }
}
