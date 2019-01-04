variable "access_key" {}
variable "secret_key" {}
variable "region" {
  default = "us-west-1"
}
variable "ssh_key_private" {
    default = "~/my_ore_keypair.pem"
}