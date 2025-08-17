resource "helm_release" "ingress_nginx_internal" {
  name             = "ingress-nginx-internal"
  namespace        = "ingress-nginx-internal"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.10.1"
  create_namespace = true
  force_update     = true
  wait             = false
  timeout          = 1200
  values = [<<YAML
controller:
  ingressClass: internal
  ingressClassByName: true
  ingressClassResource:
    name: internal
    controllerValue: "k8s.io/ingress-nginx-internal"
  extraArgs:
    controller-class: "k8s.io/ingress-nginx-internal"
    watch-ingress-without-class: "false"
  publishService:
    enabled: true
  service:
    type: LoadBalancer
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
      service.beta.kubernetes.io/aws-load-balancer-internal: "true"
YAML
  ]
}
