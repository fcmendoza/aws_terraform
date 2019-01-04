
# aws_terraform

Create a `secret.tfvars` file inside this folder with the AWS access and secret keys:

```bash
$ touch secret.tfvars
$ echo "access_key = \"MYACCESSKEYGOESHERE\"" >> secret.tfvars
$ echo "secret_key = \"MYSECRETKEYGOESHERE\"" >> secret.tfvars
```

Then plan and run terraform:

```bash
$ terraform plan -var-file="secret.tfvars"
$ terraform apply -var-file="secret.tfvars"
```