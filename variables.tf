
variable "project" {
  default = "genial-theory-227508" #ProjectID GCP
}

variable region {
  default = "europe-west2"
}

variable zone {
  default = "europe-west2-a"
}

variable network_name {
  default = "squid-nat-example"
}

variable "vm_image" {
  default = "projects/debian-cloud/global/images/family/debian-9"
  # default = "projects/ubuntu-os-cloud/global/images/ubuntu-1810-cosmic-v20190110"
  # In GCE > Images there are many images.
}
