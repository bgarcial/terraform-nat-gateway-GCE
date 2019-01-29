
provider "google" {
  # credentials = "${file("genial-theory-227508-aeae7b21b36b.json")}"
  project = "${var.project}" #ProjectID GCP
  region  = "${var.region}"
  zone    = "${var.zone}"
}

resource "google_container_cluster" "k8s_cluster" {
  name               = "testing1"
  zone               = "europe-west2-a"
  initial_node_count = 3

  # additional_zones = [
    # "europe-west2-b",
    # "europe-west2-c",
  # ]

  master_auth {
    username = "bgarcial"
    password = "tkjKKErlweoikjsdfwerlkjestin1234"
  }

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
    # tags = [ "${var.network_name}-squid" ]
    
  }

  network    = "${google_compute_network.default.self_link}"
  subnetwork =  "${google_compute_subnetwork.default.self_link}"

  min_master_version = "1.11.6-gke.0"
  node_version       = "1.11.6-gke.0"
}


resource "google_compute_route" "gke-master-default-gw" {
  count            = 1
  name             = "masterroutes"
  dest_range       = "0.0.0.0/0"
  network          = "${google_compute_network.default.self_link}"
  next_hop_gateway = "default-internet-gateway"
  tags             = ["${var.network_name}-squid"]
  priority         = 700
}

#https://www.terraform.io/docs/providers/google/r/compute_network.html
resource "google_compute_network" "default" {
  name                    = "${var.network_name}"
  
  #  (Optional) If set to true, this network will be created 
  # in auto subnet mode, and Google will create a subnet for 
  # each region automatically. If set to false, a custom 
  # subnetted network will be created that can support 
  # google_compute_subnetwork resources. Defaults to true.
  auto_create_subnetworks = "false"
  
}

# https://www.terraform.io/docs/providers/google/r/compute_subnetwork.html
resource "google_compute_subnetwork" "default" {
  name          = "${var.network_name}"
  
  # The range of internal addresses that are owned 
  # by this subnetwork. Provide this property when 
  # you create the subnetwork. For example, 10.0.0.0/8 or 
  # 192.168.0.0/16. Ranges must be unique and non-overlapping 
  # within a network. Only IPv4 is supported.
  ip_cidr_range = "10.127.0.0/20"

  # (Required) The network this subnet belongs to. 
  # Only networks that are in the distributed mode can have subnetworks.
  network       = "${google_compute_network.default.self_link}"

  region        = "${var.region}"

  # (Optional) Whether the VMs in this subnet can access 
  # Google services without assigned external IP addresses.
  private_ip_google_access = true
}

module "nat" {
  source        = "../"
  name          = "${var.network_name}-"
  region        = "${var.region}"
  zone          = "${var.zone}"
  tags          = ["${var.network_name}-squid"]
  network       = "squid-nat-example"
  subnetwork    = "squid-nat-example"
  squid_enabled = "true"
}

# https://www.terraform.io/docs/providers/google/d/datasource_compute_instance.html
# resource "google_compute_instance" "vm" {
#   name                      = "${var.network_name}-vm"
#   zone                      = "${var.zone}"
#   tags                      = ["${var.network_name}-ssh", "${var.network_name}-squid"]
  
#   # The machine type to create
#   machine_type              = "f1-micro"
#   allow_stopping_for_update = true

#   # The boot disk for the instance
#   boot_disk {

#     # Parameters with which a disk was created alongside the 
#     # instance. 
#     initialize_params {
#       # The image from which this disk was initialised.
#       image = "${var.vm_image}"
#     }
#   }

#   network_interface {
#     subnetwork    = "${google_compute_subnetwork.default.name}"
#     access_config = []
#   }
# }

# # https://www.terraform.io/docs/providers/google/r/compute_firewall.html
# resource "google_compute_firewall" "vm-ssh" {
#   name    = "${var.network_name}-ssh"
#   network = "${google_compute_subnetwork.default.name}"

#   allow {
#     protocol = "tcp"
#     ports    = ["22"]
#   }

#   # (Optional) If source ranges are specified, the firewall will 
#   # apply only to traffic that has source IP address in these ranges. 
#   # These ranges must be expressed in CIDR format. One or both of 
#   # sourceRanges and sourceTags may be set. If both properties are set, 
#   # the firewall will apply to traffic that has source IP address 
#   # within sourceRanges OR the source IP that belongs to a tag listed 
#   # in the sourceTags property. The connection does not need to match 
#   # both properties for the firewall to apply. Only IPv4 is supported
#   # In other words allow traffic from the range specified.
#   source_ranges = ["0.0.0.0/0"]

#   # (Optional) A list of instance tags indicating sets of instances 
#   # located in the network that may make network connections as 
#   # specified in allowed[]. If no targetTags are specified, the firewall rule applies to all instances on the specified network.
#   target_tags   = ["${var.network_name}-ssh"]
# }


// Since we aren't using the NAT on the test VM, add separate firewall rule for the squid proxy.
resource "google_compute_firewall" "nat-squid" {
  name    = "${var.network_name}-squid"
  network = "${google_compute_subnetwork.default.name}"

  allow {
    protocol = "tcp"
    ports    = ["3128"]
  }

  source_tags = ["${var.network_name}-squid"]
  target_tags = ["inst-${module.nat.routing_tag_zonal}"]
}

# https://www.terraform.io/docs/configuration/outputs.html
# Outputs define values that will be highlighted to the user 
# when Terraform applies, and can be queried easily using 
# the output command. output variables as a way to organize 
# data to be easily queried and shown back to the Terraform user
# outputs show information when terraform apply command finish

output "nat-host" {
  value = "${module.nat.instance}"
}

output "nat-ip" {
  value = "${module.nat.external_ip}"
}

# output "vm-host" {
#   # self_link The URI of the created resource.
#   value = "${google_compute_instance.vm.self_link}"
# }

