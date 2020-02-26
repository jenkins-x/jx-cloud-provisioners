// Jenkins X Resources

resource "kubernetes_namespace" "jx" {
  depends_on = [module.eks]
  metadata {
    name = local.jenkins-x-namespace
  }
  lifecycle {
    ignore_changes = [
      metadata[0].labels,
      metadata[0].annotations,
    ]
  }
}

resource "kubernetes_namespace" "cert-manager" {
  depends_on = [module.eks]
  metadata {
    name = local.cert-manager-namespace
  }
  lifecycle {
    ignore_changes = [
      metadata[0].labels,
      metadata[0].annotations,
    ]
  }
}

resource "aws_s3_bucket" "logs-jenkins-x" {
  count = var.enable_logs_storage ? 1 : 0
  bucket_prefix = "logs-${var.cluster_name}-"
  acl    = "private"

  tags = {
    Owner = "Jenkins-x"
  }
}

resource "aws_s3_bucket" "reports-jenkins-x" {
  count = var.enable_reports_storage ? 1 : 0
  bucket_prefix = "reports-${var.cluster_name}-"
  acl    = "private"

  tags = {
    Owner = "Jenkins-x"
  }
}

resource "aws_s3_bucket" "repository-jenkins-x" {
  count = var.enable_repository_storage ? 1 : 0
  bucket_prefix = "repository-${var.cluster_name}-"
  acl    = "private"

  tags = {
    Owner = "Jenkins-x"
  }
}

# Route53

data "aws_route53_zone" "apex_domain_zone" {
  name = "${var.apex_domain}."
}

resource "aws_route53_zone" "subdomain_zone" {
  count = var.create_and_configure_subdomain ? 1 : 0
  name = join(".", [var.subdomain, var.apex_domain])
}

resource "aws_route53_record" "subdomain_ns_delegation" {
  count = var.create_and_configure_subdomain ? 1 : 0
  zone_id = data.aws_route53_zone.apex_domain_zone.zone_id
  name    = join(".", [var.subdomain, var.apex_domain])
  type    = "NS"
  ttl     = 30
  records = [
    "${aws_route53_zone.subdomain_zone[0].name_servers.0}",
    "${aws_route53_zone.subdomain_zone[0].name_servers.1}",
    "${aws_route53_zone.subdomain_zone[0].name_servers.2}",
    "${aws_route53_zone.subdomain_zone[0].name_servers.3}",
  ]
}

# jx-requirements.yml file generation

resource "local_file" "jx-requirements" {
  depends_on = [
    aws_s3_bucket.logs-jenkins-x,
    aws_kms_key.kms_vault_unseal,
    aws_s3_bucket.vault-unseal-bucket,
    aws_dynamodb_table.vault-dynamodb-table,
  ]
  content = templatefile("${path.module}/jx-requirements-eks.yml.tpl", {
    cluster_name                = var.cluster_name
    region                      = var.region
    enable_logs_storage         = var.enable_logs_storage
    logs_storage_bucket         = aws_s3_bucket.logs-jenkins-x[0].id
    enable_reports_storage      = var.enable_reports_storage
    reports_storage_bucket      = aws_s3_bucket.reports-jenkins-x[0].id
    enable_repository_storage   = var.enable_repository_storage
    repository_storage_bucket   = aws_s3_bucket.repository-jenkins-x[0].id
    create_vault_resources      = var.create_vault_resources
    vault_kms_key               = var.create_vault_resources ? aws_kms_key.kms_vault_unseal[0].id : null
    vault_bucket                = var.create_vault_resources ? aws_s3_bucket.vault-unseal-bucket[0].id : null
    vault_dynamodb_table        = var.create_vault_resources ? aws_dynamodb_table.vault-dynamodb-table[0].id : null
    vault_user                  = var.vault_user
    enable_external_dns         = var.enable_external_dns
    domain                      = trimprefix(join(".", [var.subdomain, var.apex_domain]), ".")
    enable_tls                  = var.enable_tls
    tls_email                   = var.tls_email
    use_production_letsencrypt  = var.production_letsencrypt
  })
  filename = "${path.module}/jx-requirements-eks.yml"
}