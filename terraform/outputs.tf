output "cluster_name" {
  value = module.eks.cluster_name
}

output "region" {
  value = var.aws_region
}

output "update_kubeconfig_cmd" {
  value = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region}"
}


data "kubernetes_service" "ingress_nginx_public" {
  metadata {
    name      = "ingress-nginx-public-ingress-nginx-controller"
    namespace = "ingress-nginx-public"
  }
  depends_on = [helm_release.ingress_nginx_public]
}

data "kubernetes_service" "ingress_nginx_internal" {
  metadata {
    name      = "ingress-nginx-internal-ingress-nginx-controller"
    namespace = "ingress-nginx-internal"
  }
  depends_on = [helm_release.ingress_nginx_internal]
}

output "public_nlb_hostname" {
  value = try(data.kubernetes_service.ingress_nginx_public.status[0].load_balancer[0].ingress[0].hostname, "")
}

output "internal_nlb_hostname" {
  value = try(data.kubernetes_service.ingress_nginx_internal.status[0].load_balancer[0].ingress[0].hostname, "")
}