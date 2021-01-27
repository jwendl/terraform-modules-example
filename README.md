# Terraform Modules Example

This is an example of how to setup Terraform using modules. It also provides another example of how to not use modules. Both of these are for illustration purposes only to show the differences between moduels in Terraform.

The example application builds a Functions application with Application Insights and Azure SQL Server services connected together.

The supporting blog series can be found at <https://jwendl.net/2021/01/26/01-terraform-intro/>

## Installing Terraform

This depends on the system, but here I will show using Windows with Ubuntu 20.04 on WSL

The following commands will install Terraform for your shell.

``` bash
wget https://releases.hashicorp.com/terraform/0.14.5/terraform_0.14.5_linux_amd64.zip -O terraform.zip
unzip terraform.zip
sudo cp terraform /usr/local/bin
terraform -version
```

This should show you the version of terraform you are running.

``` bash
❯ terraform -version
Terraform v0.14.5
```

## Running this example:

``` bash
terraform init
terraform plan -out tf.plan -var-file values.tfvars
terraform apply tf.plan
```
