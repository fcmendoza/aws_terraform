
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
