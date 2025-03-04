
variable "config_file" {
  type    = string
  default = "rocky8-kickstart.cfg"
}

variable "cpu" {
  type    = string
  default = "2"
}

variable "destination_server" {
  type    = string
  default = "download.goffinet.org"
}

variable "disk_size" {
  type    = string
  default = "40000"
}

variable "headless" {
  type    = string
  default = "true"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:fe77cc293a2f2fe6ddbf5d4bc2b5c820024869bc7ea274c9e55416d215db0cc5"
}

variable "iso_url" {
  type    = string
  default = "https://download.rockylinux.org/pub/rocky/8.6/isos/x86_64/Rocky-8.6-x86_64-boot.iso"
}

variable "name" {
  type    = string
  default = "rocky"
}

variable "ram" {
  type    = string
  default = "2048"
}

variable "ssh_password" {
  type    = string
  default = "testtest"
}

variable "ssh_username" {
  type    = string
  default = "root"
}

variable "version" {
  type    = string
  default = "8"
}

/*
server {
    listen 80;
    location / {
         proxy_pass http://127.0.0.1:9000;
    }
}
*/

source "qemu" "rocky8" {
  accelerator      = "kvm"
  boot_command     = ["<up><wait><tab><wait> inst.text inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/http/${var.config_file}<enter><wait>"]
  boot_wait        = "40s"
  disk_cache       = "none"
  disk_compression = true
  disk_discard     = "unmap"
  disk_interface   = "virtio"
  disk_size        = var.disk_size
  format           = "qcow2"
  headless         = var.headless
  http_directory   = "."
  iso_checksum     = var.iso_checksum
  iso_url          = var.iso_url
  net_device       = "virtio-net"
  output_directory = "artifacts/qemu/${var.name}${var.version}"
  qemu_binary      = "/usr/bin/qemu-system-x86_64"
  qemuargs         = [["-m", "${var.ram}M"], ["-smp", "${var.cpu}"]]
  shutdown_command = "sudo /usr/sbin/shutdown -h now"
  ssh_password     = var.ssh_password
  ssh_username     = var.ssh_username
  ssh_wait_timeout = "30m"
}

build {
  sources = ["source.qemu.rocky8"]

  provisioner "shell" {
    execute_command = "{{ .Vars }} sudo -E bash '{{ .Path }}'"
    inline          = ["yum -y install epel-release", "yum repolist", "yum -y install ansible"]
  }

  provisioner "ansible-local" {
    playbook_dir  = "ansible"
    playbook_file = "ansible/playbook.yml"
  }

#  post-processor "shell-local" {
#    environment_vars = ["IMAGE_NAME=${var.name}", "IMAGE_VERSION=${var.version}", "DESTINATION_SERVER=${var.destination_server}"]
#    script           = "scripts/push-image.sh"
#  }
}
