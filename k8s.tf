provider "google" {
  project = "foolproj"
  region  = "europe-west-1"
  zone    = "europe-west1-c"
}

data "http" "ipinfo" {
  url = "https://ipinfo.io/json"
}

data "http" "github" {
  url = "https://api.github.com/users/femnad/keys"
}

locals {
  ssh_format_spec = "femnad:%s user@host"
}

resource "google_compute_network" "network" {
  name = "k8s-network"
}

resource "google_compute_firewall" "firewall-rule" {
  name    = "k8s-ssh-allower"
  network = google_compute_network.network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = [format("%s/32", jsondecode(data.http.ipinfo.body).ip)]
}

resource "google_compute_instance" "cpn" {
  name                      = "k8s-cpn"
  machine_type              = "e2-small"
  allow_stopping_for_update = true

  tags = ["k8s-cpn"]

  metadata = {
    ssh-keys = join("\n", formatlist(local.ssh_format_spec, [for key in jsondecode(data.http.github.body) : key.key]))
  }

  network_interface {
    network = google_compute_network.network.name
    access_config {}
  }

  boot_disk {
    initialize_params {
      image = "ubuntu-minimal-2004-focal-v20200917"
    }
  }

  scheduling {
    preemptible       = true
    automatic_restart = false
  }
}

resource "google_compute_instance" "nod" {
  name                      = "k8s-nod"
  machine_type              = "e2-small"
  allow_stopping_for_update = true

  tags = ["k8s-nod"]

  metadata = {
    ssh-keys = join("\n", formatlist(local.ssh_format_spec, [for key in jsondecode(data.http.github.body) : key.key]))
  }

  network_interface {
    network = google_compute_network.network.name
    access_config {}
  }

  boot_disk {
    initialize_params {
      image = "ubuntu-minimal-2004-focal-v20200917"
    }
  }

  scheduling {
    preemptible       = true
    automatic_restart = false
  }
}

resource "google_compute_firewall" "allow-private-from-cpn" {
  name    = "private-allower-cpn"
  network = google_compute_network.network.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["1024-65535"]
  }

  target_tags   = ["k8s-nod"]
  source_ranges = [google_compute_instance.cpn.network_interface[0].network_ip]
}

resource "google_compute_firewall" "allow-private-from-nod" {
  name    = "private-allower-nod"
  network = google_compute_network.network.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["1024-65535"]
  }

  target_tags   = ["k8s-cpn"]
  source_ranges = [google_compute_instance.nod.network_interface[0].network_ip]
}

resource "google_compute_firewall" "allow-api-access" {
  name    = "k8s-api-allower"
  network = google_compute_network.network.name

  allow {
    protocol = "tcp"
    ports    = ["6443"]
  }
  target_tags = ["k8s-cpn"]
  source_ranges = [format("%s/32", jsondecode(data.http.ipinfo.body).ip)]
}

module "dns-module-cpn" {
  source           = "femnad/dns-module/gcp"
  version          = "0.3.0"
  dns_name         = "cpn.fcd.dev."
  instance_ip_addr = google_compute_instance.cpn.network_interface[0].access_config[0].nat_ip
  managed_zone     = "fcd-dev"
  project          = "foolproj"
}

module "dns-module-nod" {
  source           = "femnad/dns-module/gcp"
  version          = "0.3.0"
  dns_name         = "nod.fcd.dev."
  instance_ip_addr = google_compute_instance.nod.network_interface[0].access_config[0].nat_ip
  managed_zone     = "fcd-dev"
  project          = "foolproj"
}
