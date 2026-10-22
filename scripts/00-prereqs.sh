#!/usr/bin/env bash
# Install/verify CLI tools (Linux/macOS w/ brew). Adjust for your OS.
set -euo pipefail
for t in aws eksctl kubectl helm docker git jq curl; do
  command -v $t >/dev/null || echo "MISSING: $t  (install it first)"
done
aws sts get-caller-identity
# eksctl:  https://eksctl.io/installation/   |  kubectl: https://kubernetes.io/docs/tasks/tools/
# argocd CLI (optional): brew install argocd
