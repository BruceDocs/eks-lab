#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
REGION=${REGION:-ca-central-1}; TAG=${TAG:-1.0.0}
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
REPO=$ACCOUNT.dkr.ecr.$REGION.amazonaws.com/orders-service
aws ecr describe-repositories --repository-names orders-service --region $REGION >/dev/null 2>&1 || \
  aws ecr create-repository --repository-name orders-service --region $REGION
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT.dkr.ecr.$REGION.amazonaws.com
docker build --platform linux/amd64 -t $REPO:$TAG app/orders-service
docker push $REPO:$TAG
# point the GitOps manifest at the image
sed -i.bak "s#image: .*orders-service.*#image: $REPO:$TAG#" gitops/manifests/orders-app/deployment.yaml && rm -f gitops/manifests/orders-app/deployment.yaml.bak
echo "Now: git add -A && git commit -m 'orders image $TAG' && git push"
