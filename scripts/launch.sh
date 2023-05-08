#!/bin/env bash

bash ./cluster/create_cluster.sh

kubectl create -k ./cert-manager
kubectl wait -n cert-manager --for=condition=ready pod --selector=app.kubernetes.io/name=cert-manager --timeout=120s

kubectl create -k ./monitoring/prometheus-operator
kubectl wait -n monitoring --for=condition=ready pod --selector=app.kubernetes.io/name=prometheus-operator --timeout=120s

kubectl create -k ./ingress-nginx
kubectl wait -n ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=240s

bash ./external-dns/install.sh

kubectl apply -f dashboard/recommended.yaml
echo
echo "DASHBOARD TOKEN:"
bash dashboard/get_dashboard_token.sh
echo

bash ./vault/scripts/install_vault.sh

kubectl create -k ./portainer
kubectl wait -n portainer --for=condition=ready pod --selector=app.kubernetes.io/name=portainer --timeout=180s

kubectl create -k ./monitoring/prometheus
kubectl wait -n monitoring --for=condition=ready pod --selector=app.kubernetes.io/name=prometheus --timeout=180s

kubectl create -k ./monitoring/grafana
kubectl wait -n monitoring --for=condition=ready pod --selector=app.kubernetes.io/name=grafana --timeout=180s

kubectl create -k ./monitoring/cadvisor
kubectl wait -n monitoring --for=condition=ready pod --selector=app.kubernetes.io/name=cadvisor --timeout=240s

kubectl create -k ./monitoring/kube-state-metrics
kubectl wait -n monitoring --for=condition=ready pod --selector=app.kubernetes.io/name=kube-state-metrics --timeout=240s

kubectl create -k ./monitoring/metrics-server
kubectl wait -n kube-system --for=condition=ready pod --selector=app.kubernetes.io/name=metrics-server --timeout=240s

kubectl create -k ./monitoring/node-exporter
kubectl wait -n kube-system --for=condition=ready pod --selector=app.kubernetes.io/name=node-exporter --timeout=240s

kubectl create -k ./traefik-ingress
kubectl wait -n traefik --for=condition=ready pod --selector=app.kubernetes.io/name=traefik-ingress-controller --timeout=120s

kubectl create -k ./jenkins
kubectl wait -n jenkins --for=condition=ready pod --selector=app.kubernetes.io/name=jenkins --timeout=360s