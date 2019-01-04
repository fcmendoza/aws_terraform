provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

resource "aws_instance" "example" {
  ami = "ami-063aa838bd7631e0b" # Ubuntu 18.04 LTS
  instance_type = "t2.micro"
  key_name = "my_ore_keypair"

  tags = {
    Name = "terransibuntu"
  }

  security_groups = [ "ssh_access", "rdp_access" ]

  provisioner "remote-exec" {
    inline = ["sudo apt-get update"]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${file(var.ssh_key_private)}"
    }
  }
}