#!/usr/bin/env bash
# Maps AWS IAM users -> Kubernetes users/groups using EKS Access Entries (no aws-auth edits).
set -euo pipefail
CLUSTER=lab-eks; REGION=ca-central-1
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
map() { # <iam-user> <k8s-username> <groups...>
  local u=$1 k=$2; shift 2
  aws iam get-user --user-name $u >/dev/null 2>&1 || aws iam create-user --user-name $u
  aws eks create-access-entry --cluster-name $CLUSTER --region $REGION \
    --principal-arn arn:aws:iam::$ACCOUNT:user/$u --username $k \
    ${*:+--kubernetes-groups "$@"} || true
}
map lab-admin1 admin1 platform-admins                 # GROUP level  -> cluster-admin
map lab-alice  alice  all-engineers team-a-devs       # TEAM level   -> edit in team-a
map lab-tina   tina   all-engineers team-a-leads      # TEAM level   -> admin in team-a
map lab-bob    bob    all-engineers team-b-devs       # TEAM level   -> edit in team-b
map lab-carol  carol                                  # USER level   -> Role bound to user "carol"
echo "Create access keys per user if you want real logins:  aws iam create-access-key --user-name lab-alice"
echo "Then: aws eks update-kubeconfig --name $CLUSTER --profile <profile>"
