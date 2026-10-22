#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
eksctl create cluster -f infra/eks-cluster.yaml          # ~15-20 min
aws eks update-kubeconfig --name lab-eks --region ca-central-1
# gp3 as default storage class
kubectl annotate sc gp2 storageclass.kubernetes.io/is-default-class- --overwrite || true
kubectl apply -f infra/storageclass-gp3.yaml
kubectl get nodes -o wide
