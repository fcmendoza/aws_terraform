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

  security_groups = [ "ssh_access", "rdp_access", "http_access" ] # these groups already exist

  provisioner "remote-exec" {
    inline = ["sudo apt-get update"]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${file(var.ssh_key_private)}"
    }
  }

  provisioner "remote-exec" {
    inline = ["sudo ln -s /usr/bin/python3 /usr/bin/python"]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${file(var.ssh_key_private)}"
    }
  }

  provisioner "remote-exec" {
    inline = ["echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDsuEeoHyMkBsH0l/i0fukUAzryn0KxAVgloGEX4uuk4FL82n1mQOEyPcIIp/PZWRmkGU9Ixyzcrsyf/X3Bs4yO8y7hovUbAw9S4NIRvNw71wkqbrUTklvFjMxcuf7EVqYiQd9cUX7/NxFKtOB/+ZM6ft/Ta3ZMi1mlH+1CPwvXx8MYhXCT/OEjGlZx1RAAT9iuXobXIEFgX8KB52cmDkC8WdkHgBwMtiixkFhXOOhwYg2qhYUzUzfXxI63DP7WAolqAsUYIk38jY4jmezK20XclVETyYSweA7gvZ7hn9smI2tbwMGxnfKtOooTpgueX7xaQZs60HyXP8GgbKfsoxcD ubuntu@ip-172-31-4-133' >> ~/.ssh/authorized_keys"]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${file(var.ssh_key_private)}"
    }
  }

  # This is where we configure the instance with ansible-playbook
  #provisioner "local-exec" {
  #    command = "sleep 120; ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu --private-key ./deployer.pem -i '${aws_instance.jenkins_master.public_ip},' master.yml"
  #}

  # This is where we configure the instance with ansible-playbook
  #provisioner "local-exec" {
  #    command = "ansible-playbook -u ubuntu --private-key ~/.ssh/my_rsa_dos -i '13.56.19.160,' apache_all.yml"
  #}
}