source "vagrant" "example" {
  communicator = "ssh"
  source_path = "generic/ubuntu2004"
  provider = "virtualbox"
}

build {
  sources = [
    "source.vagrant.example"
  ]

  provisioner "shell" {
    script = "bootstrap.sh"
  }

  post-processor "manifest" {
    output = "manifest.json"
  }
}
