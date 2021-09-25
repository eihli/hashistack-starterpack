packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "hashistack"
  instance_type = "t2.micro"
  region        = "us-east-2"
  source_ami    = "ami-01e80d9e7b6daabcf"
  ssh_username  = "ubuntu"
}

build {
  name = "hashistack"
  sources = [
    "source.amazon-ebs.ubuntu"
  ]

  provisioner "shell" {
    script = "../bootstrap.sh"
  }

  post-processor "manifest" {
    output = "manifest.json"
  }
}
