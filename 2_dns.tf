################################################################################
# create a DNS subzone managed by the cluster
################################################################################

locals {
  external_dns_ns = "kube-system"
}

data "aws_route53_zone" "main" {
  name = var.parent_zone
}

resource "aws_route53_zone" "zone" {
  name = "eks.${data.aws_route53_zone.main.name}"
}

resource "aws_route53_record" "zone" {
  allow_overwrite = true
  name            = aws_route53_zone.zone.name
  ttl             = 172800
  type            = "NS"
  zone_id         = data.aws_route53_zone.main.zone_id

  records = [
    aws_route53_zone.zone.name_servers[0],
    aws_route53_zone.zone.name_servers[1],
    aws_route53_zone.zone.name_servers[2],
    aws_route53_zone.zone.name_servers[3],
  ]
}

module "external_dns_role" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name = "external_dns"
  attach_external_dns_policy = true

  oidc_providers = {
    main = {
      provider_arn     = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.external_dns_ns}:external-dns"]
    }
  }
}

resource "helm_release" "external-dns" {
  name       = "external-dns"

  repository = "https://charts.bitnami.com/bitnami"
  chart      = "external-dns"
  namespace  = local.external_dns_ns

  set {
    name  = "domainFilters"
    value = "{${aws_route53_zone.zone.name}}"
  }
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.external_dns_role.iam_role_arn
  }
  set {
    name  = "policy"
    value = "sync"
  }
}
