output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "cluster_name" {
  value = var.cluster_name
}

output "vault_bucket" {
  value = var.create_vault_resources ? aws_s3_bucket.vault-unseal-bucket[0].arn : null
}

output "vault_dynamodb_table" {
  value = var.create_vault_resources ? aws_dynamodb_table.vault-dynamodb-table[0].arn : null
}

output "vault_kms_key" {
  value = var.create_vault_resources ? aws_kms_key.kms_vault_unseal : null
}

output "logs_bucket" {
  value = aws_s3_bucket.logs-jenkins-x
}