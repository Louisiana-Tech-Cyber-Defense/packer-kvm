
variable "config_file" {
  type    = string
  default = "centos9-kickstart.cfg"
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
  default = "sha256:d6dccd66ba317a2825821fe92169a53079df95b04581c065a8244f67303e1f46"
}

variable "iso_url" {
  type    = string
  default = "http://mirror.stream.centos.org/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-20220531.0-x86_64-boot.iso"
}

variable "name" {
  type    = string
  default = "centos"
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
  default = "9"
}

source "qemu" "centos9" {
  accelerator      = "kvm"
  boot_command     = ["<tab><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs> inst.text inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/http/${var.config_file}<enter><wait>"]
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
  qemuargs         = [["-m", "${var.ram}M"], ["-smp", "${var.cpu}"], ["-cpu", "host"]]
  shutdown_command = "sudo /usr/sbin/shutdown -h now"
  ssh_password     = var.ssh_password
  ssh_username     = var.ssh_username
  ssh_wait_timeout = "30m"
}

build {
  sources = ["source.qemu.centos9"]

  provisioner "shell" {
    execute_command = "{{ .Vars }} sudo -E bash '{{ .Path }}'"
    inline          = ["dnf -y install epel-release", "dnf repolist", "dnf -y install ansible"]
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
