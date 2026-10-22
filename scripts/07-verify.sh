#!/usr/bin/env bash
set -uo pipefail
echo "== Argo apps";            kubectl -n argocd get applications
echo "== Pods";                 kubectl get pods -A | egrep 'kafka|mysql|monitoring|team-a'
echo "== Create order via app"
kubectl -n team-a port-forward svc/orders-service 8081:8080 >/dev/null & PF=$!; sleep 3
curl -s -X POST localhost:8081/api/orders -H 'Content-Type: application/json' -d '{"product":"book","quantity":2}'; echo
sleep 3; curl -s localhost:8081/api/orders; echo
curl -s localhost:8081/actuator/prometheus | head -5
kill $PF
echo "== Kafka topic content"
kubectl -n kafka run kcat-$RANDOM --rm -i --restart=Never --image=quay.io/strimzi/kafka:0.46.0-kafka-3.9.0 -- \
  bin/kafka-console-consumer.sh --bootstrap-server lab-kafka-kafka-bootstrap:9092 --topic orders --from-beginning --timeout-ms 8000
echo "== MySQL rows"
kubectl -n mysql exec sts/mysql -c mysql -- sh -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "select * from ordersdb.orders"'
echo "== Prometheus targets (down ones)"
kubectl -n monitoring port-forward svc/prometheus-operated 9090 >/dev/null & PF=$!; sleep 3
curl -s localhost:9090/api/v1/targets | jq -r '.data.activeTargets[]|select(.health!="up")|.scrapePool+" "+.health'
curl -s 'localhost:9090/api/v1/query?query=probe_success' | jq -r '.data.result[]|.metric.instance+" "+.value[1]'
kill $PF
echo "== RBAC checks (impersonation)"
c() { printf '%-70s' "$*"; kubectl auth can-i "$@" && true; }
c create deployments -n team-a --as=alice --as-group=team-a-devs
c create deployments -n team-b --as=alice --as-group=team-a-devs
c get secrets          -n team-a --as=tina  --as-group=team-a-leads
c create rolebindings  -n team-a --as=tina  --as-group=team-a-leads
c create rolebindings  -n team-a --as=alice --as-group=team-a-devs
c get pods/log         -n team-a --as=carol
c delete pods          -n team-a --as=carol
c '*' '*' --all-namespaces --as=admin1 --as-group=platform-admins
