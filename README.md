# EKS + Kafka + MySQL + Spring Boot + Argo CD + Observability + RBAC (lab)

Region default: ca-central-1. Cluster: `lab-eks`, 3 x m5.large (~US$0.30/h for nodes + control plane; delete when done).

## Layout
```
infra/        eksctl cluster config (EKS, EBS CSI, access entries mode) + gp3 StorageClass
scripts/      numbered bootstrap / verify / cleanup scripts
gitops/       everything Argo CD syncs (push this folder to YOUR Git repo)
  argocd/       root app (app-of-apps) + child Applications (helm charts & manifests)
  manifests/    rbac, mysql(+mysqld-exporter), kafka(Strimzi KRaft+JMX), monitoring-extras(ServiceMonitor/PodMonitor/Probe/alerts), orders-app
app/orders-service   Spring Boot 3 (Java 17): REST -> MySQL + Kafka producer/consumer, Micrometer + JMX exporter
```

## Run order
```bash
./scripts/00-prereqs.sh
./scripts/01-create-cluster.sh                # EKS + 3 nodes
./scripts/02-install-argocd.sh                # Argo CD
./scripts/03-create-namespaces-and-secrets.sh # secrets are NOT in Git
./scripts/04-build-push-app.sh                # build image -> ECR, patch deployment.yaml
git init && git add -A && git commit -m lab && git remote add origin <YOUR_REPO> && git push -u origin main
REPO_URL=<YOUR_REPO_URL> ./scripts/05-bootstrap-gitops.sh   # (run BEFORE the commit/push if you prefer: it rewrites REPO_URL_PLACEHOLDER; then commit+push)
./scripts/06-rbac-iam-mapping.sh              # IAM users -> K8s groups/users
./scripts/07-verify.sh
```
Note: 05 substitutes the repo URL into gitops/ files, so run its sed step, commit and push, then apply root app (the script pauses for that).

## UIs
```bash
kubectl -n argocd port-forward svc/argocd-server 8080:443          # https://localhost:8080 admin/<initial secret>
kubectl -n monitoring port-forward svc/kps-grafana 3000:80         # admin / admin123 (lab)
kubectl -n monitoring port-forward svc/prometheus-operated 9090    # Prometheus
```

## Useful checks
```bash
kubectl -n kafka get kafka,kafkanodepool,kafkatopic
kubectl -n kafka exec lab-kafka-dual-role-0 -- bin/kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic orders
kubectl -n mysql exec sts/mysql -c mysql -- sh -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "select * from ordersdb.orders"'
# Prometheus queries: up, mysql_up, kafka_server_replicamanager_underreplicatedpartitions, probe_success, jvm_memory_used_bytes{application="orders-service"}
```
GitOps test: change `replicas: 2` -> 3 in gitops/manifests/orders-app/deployment.yaml, push, watch Argo sync. Then `kubectl scale` manually to see selfHeal revert it.

## RBAC model (gitops/manifests/rbac/01-rbac.yaml)
| Level | Subject | Scope | Permission |
|---|---|---|---|
| Group | platform-admins | cluster | cluster-admin |
| Group | all-engineers | cluster | read namespaces/nodes only |
| Team | team-a-devs / team-a-leads | ns team-a | edit / admin |
| Team | team-b-devs | ns team-b | edit |
| User | carol | team-a (+Grafana port-forward in monitoring) | custom Role: pod + logs read-only |

IAM -> K8s mapping uses EKS Access Entries (script 06). Test without real logins using impersonation (script 07 bottom), e.g.
`kubectl auth can-i create deployments -n team-b --as=alice --as-group=team-a-devs` -> no.

## Notes / production hardening
- Pin Helm chart versions (ranges in the Application files are placeholders); Strimzi 0.46 <-> Kafka 3.9.0 (KRaft). Adjust together when upgrading.
- Replace lab secrets (Grafana password, MySQL root exporter) with External Secrets / Sealed Secrets; create a dedicated MySQL exporter user.
- Add Ingress/ALB + TLS, NetworkPolicies, PodDisruptionBudgets, Argo CD SSO + AppProjects for real multi-team setups.
- Cleanup: `./scripts/99-cleanup.sh` (also delete leftover EBS volumes / ECR if any).
