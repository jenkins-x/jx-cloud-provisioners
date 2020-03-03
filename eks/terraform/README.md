# <WIP> Terraform script to create an EKS cluster and some extra infrastructure

## Setup

Run Terraform:

```
terraform init
terraform apply -var '<cluster_name>' -var 'region=<region>' -var 'account_id=<aws_account_id>' -var 'vault_user=<iam_username_for_vault>' -var 'vpc_name=<vpc_name>' -var 'create_vault_resources=true'
```
