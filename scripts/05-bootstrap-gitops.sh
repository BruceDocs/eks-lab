#!/usr/bin/env bash
# Usage: REPO_URL=https://github.com/<you>/eks-lab.git ./scripts/05-bootstrap-gitops.sh
set -euo pipefail
cd "$(dirname "$0")/.."
: "${REPO_URL:?set REPO_URL to YOUR git repo that contains this folder}"
grep -rl REPO_URL_PLACEHOLDER gitops | xargs -r sed -i.bak "s#REPO_URL_PLACEHOLDER#$REPO_URL#g"
find gitops -name '*.bak' -delete
echo ">> Commit & push the repo first (git add -A; git commit; git push), then press Enter"; read -r _
# private repo? argocd repo add $REPO_URL --username <u> --password <PAT>
kubectl apply -f gitops/argocd/root-app.yaml
kubectl -n argocd get applications -w
