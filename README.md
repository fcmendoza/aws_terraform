
# aws_terraform

Create a `secret.tfvars` file inside this folder with the AWS access and secret keys:

```bash
$ touch secret.tfvars
$ echo "access_key = \"MYACCESSKEYGOESHERE\"" >> secret.tfvars
$ echo "secret_key = \"MYSECRETKEYGOESHERE\"" >> secret.tfvars
```

Change the `terraform` section in main.tf to point to a bucket you have access to or remove the `terraform` section if you don't want to save the state file in a remote location.

Then plan and run terraform:

```bash
$ terraform init
$ terraform plan -var-file="secret.tfvars"
$ terraform apply -var-file="secret.tfvars"
```

# lambda and API Gateway

For the lambda we need a main.zip file in this directory. We can download https://s3-us-west-1.amazonaws.com/dummy-lambdas-bucket/92d19d2614deca3ebd709d84b3358dde (private object) and rename it as `main.zip`.
