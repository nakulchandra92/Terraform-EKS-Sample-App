resource "helm_release" "ingress_nginx_public" {
  name             = "ingress-nginx-public"
  namespace        = "ingress-nginx-public"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.10.1"
  create_namespace = true
  force_update     = true
  wait             = false
  timeout          = 1200
  values = [<<YAML
controller:
  ingressClass: public
  ingressClassByName: true
  ingressClassResource:
    name: public
    controllerValue: "k8s.io/ingress-nginx-public"
  extraArgs:
    controller-class: "k8s.io/ingress-nginx-public"
    watch-ingress-without-class: "false"
  publishService:
    enabled: true
  service:
    type: LoadBalancer
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
YAML
  ]
}
