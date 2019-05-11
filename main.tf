provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

terraform {
  backend "s3" {
    bucket  = "dummy-lambdas-bucket"
    key     = "terraform.tfstate"
    region  = "us-west-1"
    encrypt = true
  }
}

module "lambda_module" {
  source = "./modules/lambda_module"
}

# module "ec2_module" {
#   source = "./modules/ec2_module"
# }

module "load_balancer_module" {
  source = "./modules/load_balancer_module"
}
