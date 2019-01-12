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
    Name = "terransibuntupache"
  }
  root_block_device = {
    volume_size = 16
  }

  security_groups = [ "ssh_access", "rdp_access", "http_access" ] # these groups already exist

  provisioner "remote-exec" {
    inline = ["sudo apt-get update"]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${file(var.ssh_key_private)}"
    }
  }

  # For some reason we need this on the remote machine so Ansible works.
  provisioner "remote-exec" { 
    inline = ["sudo ln -s /usr/bin/python3 /usr/bin/python"]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${file(var.ssh_key_private)}"
    }
  }

  # This is where we configure the EC2 instance with ansible
  provisioner "local-exec" {
      command = "ansible-playbook -u ubuntu -i '${self.public_ip},' --private-key ~/my_ore_keypair.pem apache_all.yml"
  }
}