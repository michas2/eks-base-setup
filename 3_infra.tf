##################################################################################
# create a single ALB forwarding all data to the default nginx to manage ingesses
##################################################################################

locals {
  alb_ns = "kube-system"
}

resource "helm_release" "alb" {
  name       = "alb"

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = local.alb_ns

  set {
    name  = "clusterName"
    value = module.eks.cluster_id
  }
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.alb_role.iam_role_arn
  }
}

module "alb_role" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name = "alb"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn     = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.alb_ns}:alb-aws-load-balancer-controller"]
    }
  }
}

# don't use something like ${helm_release.nginx.name}, or it will create a dependency cycle
# terraform needs to create the alb first and afterwards inject the generated adress to nginx
resource "kubernetes_ingress_v1" "alb" {
  wait_for_load_balancer = true
  metadata {
    name = "alb"
    namespace = local.alb_ns
    annotations = {
      "alb.ingress.kubernetes.io/scheme" = "internet-facing"
      "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTP\": 80}, {\"HTTPS\":443}]"
      "alb.ingress.kubernetes.io/ssl-redirect" = "443"
      "alb.ingress.kubernetes.io/certificate-arn" = var.cert
      "alb.ingress.kubernetes.io/target-type" = "ip"
    }
  }
  spec {
    ingress_class_name = "alb"
    default_backend {
      service {
        name = "nginx-ingress-nginx-controller"
        port {
          name = "http"
        }
      }
    }
  }
}

#####################################################################
resource "helm_release" "nginx" {
  name       = "nginx"

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "kube-system"

  set {
    name  = "controller.service.type"
    value = "ClusterIP"
  }
  set {
    name  = "controller.publishService.enabled"
    value = "false"
  }
  set {
    name  = "controller.extraArgs.publish-status-address"
    value = kubernetes_ingress_v1.alb.status.0.load_balancer.0.ingress.0.hostname
  }
  set {
    name  = "controller.config.use-forwarded-headers"
    value = "true"
  }
  set {
    name  = "controller.ingressClassResource.default"
    value = "true"
  }
}
