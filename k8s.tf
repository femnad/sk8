module "instance-module" {
  source               = "femnad/instance-module/gcp"
  version              = "0.7.1"
  github_user          = "femnad"
  project              = "foolproj"
  ssh_user             = "femnad"
}


module "dns-module" {
  source           = "femnad/dns-module/gcp"
  version          = "0.3.0"
  dns_name         = "k8s.fcd.dev."
  instance_ip_addr = module.instance-module.instance_ip_addr
  managed_zone     = "fcd-dev"
  project          = "foolproj"
}
