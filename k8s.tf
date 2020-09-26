module "instance-module" {
  source               = "femnad/instance-module/gcp"
  version              = "0.6.1"
  github_user          = "femnad"
  prefix               = "pre"
  project              = "foolproj"
  ssh_user             = "femnad"
  preemptible          = true
  service_account_file = ""
  image                = "ubuntu-minimal-2004-focal-v20200917"
  machine_type         = "e2-medium"
}


module "dns-module" {
  source           = "femnad/dns-module/gcp"
  version          = "0.3.0"
  dns_name         = "k8s.fcd.dev."
  instance_ip_addr = module.instance-module.instance_ip_addr
  managed_zone     = "fcd-dev"
  project          = "foolproj"
}
