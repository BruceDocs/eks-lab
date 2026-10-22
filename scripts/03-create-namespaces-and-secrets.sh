#!/usr/bin/env bash
# Secrets are created out-of-band (NOT stored in Git). In real life use External Secrets / Sealed Secrets.
set -euo pipefail
for ns in kafka mysql monitoring team-a team-b; do
  kubectl create ns $ns --dry-run=client -o yaml | kubectl apply -f -
done
ROOT_PW=$(openssl rand -hex 12); APP_PW=$(openssl rand -hex 12); GRAFANA_PW=${GRAFANA_PW:-admin123}
kubectl -n mysql create secret generic mysql-credentials \
  --from-literal=root-password="$ROOT_PW" --from-literal=app-user=orders --from-literal=app-password="$APP_PW" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl -n team-a create secret generic mysql-credentials \
  --from-literal=username=orders --from-literal=password="$APP_PW" \
  --dry-run=client -o yaml | kubectl apply -f -
echo "MySQL root pw: $ROOT_PW   app pw: $APP_PW   (Grafana admin pw: $GRAFANA_PW - set in gitops/argocd/apps/kube-prometheus-stack.yaml)"
