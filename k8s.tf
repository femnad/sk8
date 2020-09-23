module "instance-module" {
  source  = "femnad/instance-module/gcp"
  version = "0.6.1"
  github_user = "femnad"
  prefix = "pre"
  project = "foolproj"
  ssh_user = "femnad"
  preemptible = true
  service_account_file = ""
  image = "ubuntu-minimal-2004-focal-v20200917"
}
