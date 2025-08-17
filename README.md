#  AWS/EKS + NGINX Ingress (public `/get`, private `/post` & `/put`)

This repository provisions a minimal AWS infrastructure with Terraform and deploys a simple web app ([`kennethreitz/httpbin`](https://hub.docker.com/r/kennethreitz/httpbin/)) on Kubernetes (EKS).

**Goal**  
- Expose **`/get`** publicly on the internet.  
- Expose **`/post`** and **`/put`** **only inside the VPC** (private/internal).

**Approach (simple & robust):**
- EKS cluster with worker nodes **in private subnets**.
- Two lightweight **NGINX Ingress Controllers** (installed via Helm):
  - `public` class → **internet-facing** Network Load Balancer (Service `LoadBalancer`)
  - `internal` class → **internal** Network Load Balancer
- Two `Ingress` objects route:
  - Public Ingress: only `/get` → app
  - Internal Ingress: `/post` and `/put` → app

> Using NGINX Ingress avoids extra IAM/IRSA setup required by the AWS Load Balancer Controller (ALB), keeping the solution small and easy to understand while still satisfying **L7 path-based** exposure (public vs internal).

---

## Repository layout

```
.
├── README.md
├── k8s
│   ├── namespace.yaml
│   ├── httpbin-deployment.yaml
│   ├── httpbin-service.yaml
│   ├── ingress-public.yaml
│   └── ingress-internal.yaml
└── terraform
    ├── versions.tf
    ├── providers.tf
    ├── variables.tf
    ├── vpc.tf
    ├── eks.tf
    ├── helm-public-nginx.tf
    ├── helm-internal-nginx.tf
    └── outputs.tf
```

---

## Prerequisites

- An AWS account with credentials configured (e.g., via `aws configure`).
- **Terraform ≥ 1.5**, **kubectl**, **AWS CLI ≥ 2**, and **Helm** (Helm is used by Terraform provider).
- Sane IAM permissions (VPC, EKS, EC2, IAM, ELB/NLB).

> ⚠️ **Costs**: EKS control plane, a NAT gateway, and two NLBs incur hourly charges. This repo is designed for short-lived demos—**apply, verify, and destroy**. Free-tier cannot fully cover EKS/NAT/NLB. See **Cleanup** below.

---

## Quick start

```bash
# 1) Provision AWS infra + EKS + two NGINX ingress controllers
cd terraform
terraform init
terraform apply -auto-approve

# 2) Update kubeconfig to access the new cluster
aws eks update-kubeconfig --name demo-httpbin --region eu-west-1

# 3) Deploy the app + ingresses
cd ..
kubectl apply -f k8s/
```
```bash
# Public NLB (internet-facing)
PUBLIC=$(kubectl -n ingress-nginx-public get svc ingress-nginx-public-controller \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "PUBLIC=$PUBLIC"

# Internal NLB (private/VPC-only)
INTERNAL=$(kubectl -n ingress-nginx-internal get svc ingress-nginx-internal-controller \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "INTERNAL=$INTERNAL"
```
### Test

**Public (should work for /get only):**
```bash
curl -s "http://$PUBLIC/get" | jq .
curl -s -o /dev/null -w "%{http_code}\n" "http://$PUBLIC/post"   # expect 404
curl -s -o /dev/null -w "%{http_code}\n" -X PUT "http://$PUBLIC/put" # expect 404

```

**Internal (test from inside the cluster):**
```bash
# POST
kubectl -n app-httpbin run curl-post --image=curlimages/curl:8.8.0 \
  --rm -it --restart=Never -- \
  curl -s -X POST "http://$INTERNAL/post" -d 'hello=world' | jq .

# PUT
kubectl -n app-httpbin run curl-put --image=curlimages/curl:8.8.0 \
  --rm -it --restart=Never -- \
  curl -s -X PUT "http://$INTERNAL/put" -d 'hello=world' | jq .

# Optional: confirm /get is blocked internally
kubectl -n app-httpbin run curl-get --image=curlimages/curl:8.8.0 \
  --rm -it --restart=Never -- \
  curl -s -o /dev/null -w "%{http_code}\n" "http://$INTERNAL/get"
```
## Cleanup 

```bash
# Remove app & ingress first (releases LB resources sooner)
kubectl delete -f k8s/ || true

# Tear down infra
cd terraform
terraform destroy -auto-approve
```

---



