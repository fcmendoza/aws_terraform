
# aws_terraform

Create a `secret.tfvars` file inside this folder with the AWS access and secret keys:

```bash
$ touch secret.tfvars
$ echo "access_key = \"MYACCESSKEYGOESHERE\"" >> secret.tfvars
$ echo "secret_key = \"MYSECRETKEYGOESHERE\"" >> secret.tfvars
```

Then plan and run terraform:

```bash
$ terraform init
$ terraform plan -var-file="secret.tfvars"
$ terraform apply -var-file="secret.tfvars"
```

# lambda and API Gateway

For the lambda we need a main.zip file in this directory. We can download https://s3-us-west-1.amazonaws.com/dummy-lambdas-bucket/92d19d2614deca3ebd709d84b3358dde (private object) and rename it as `main.zip`.
