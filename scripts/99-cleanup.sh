#!/usr/bin/env bash
set -euo pipefail
kubectl -n argocd delete application root --ignore-not-found --wait=true   # cascades (finalizer)
kubectl delete pvc -A --all --wait=false || true
eksctl delete cluster -f infra/eks-cluster.yaml --wait
aws ecr delete-repository --repository-name orders-service --force --region ca-central-1 || true
