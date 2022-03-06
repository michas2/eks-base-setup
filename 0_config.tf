################################################################################
# parameters and configurations of providers
################################################################################

variable "region" {
  type = string
  default = "eu-north-1"
}
variable "cluster_name" {
  type = string
  default = "example"
}
variable "cluster_version" {
  type = string
  default = "1.21"
}
# expect existing route53 parent zone
variable "parent_zone" {
  type = string
  #default = "example.com"
}
# expect existing certificate
variable "cert" {
  type = string
  #default = "arn:aws:acm:eu-north-1:xxx:certificate/xxx"
}

################################################################################

terraform {
  required_version = ">= 0.13.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.72"
    }
  }
}

provider "aws" {
  region = var.region
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1alpha1"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_id]
      command     = "aws"
    }
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_id]
    command     = "aws"
  }
}
