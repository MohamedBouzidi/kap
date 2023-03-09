#!/bin/env bash

bash ./cluster/create_cluster.sh

kubectl create -k ./cert-manager
kubectl wait -n cert-manager --for=condition=ready pod --selector=app.kubernetes.io/name=cert-manager --timeout=120s

kubectl create -k ./monitoring/prometheus-operator
kubectl wait -n monitoring --for=condition=ready pod --selector=app.kubernetes.io/name=prometheus-operator

kubectl create -k ./ingress-nginx
kubectl wait -n ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=180s

bash ./vault/scripts/install_vault.sh

kubectl create -k ./portainer
kubectl wait -n portainer --for=condition=ready pod --selector=app.kubernetes.io/name=portainer --timeout=180s

kubectl create -k ./monitoring/prometheus
kubectl wait -n monitoring --for=condition=ready pod --selector=app.kubernetes.io/name=prometheus-operated

kubectl create -k ./monitoring/grafana
kubectl wait -n monitoring --for=condition=ready pod --selector=app.kubernetes.io/name=grafana --timeout=180s

kubectl create -k ./monitoring/cadvisor
kubectl wait -n monitoring --for=condition=ready pod --selector=app.kubernetes.io/name=cadvisor --timeout=240s

kubectl create -k ./monitoring/kube-state-metrics
kubectl wait -n monitoring --for=condition=ready pod --selector=app.kubernetes.io/name=kube-state-metrics --timeout=240s

kubectl create -k ./monitoring/metrics-server
kubectl wait -n kube-system --for=condition=ready pod --selector=app.kubernetes.io/name=metrics-server --timeout=240s

kubectl create -k ./monitoring/elasticsearch
kubectl wait -n elastic-system --for=condition=ready pod --selector=app.kubernetes.io/name=elastic-operator --timeout=600s

kubectl create -k ./monitoring/jaeger-operator
kubectl wait -n jaeger --for=condition=ready pod --selector=app.kubernetes.io/name=jaeger-operator --timeout=240s

kubectl create -k ./traefik-ingress
kubectl wait -n traefik --for=condition=ready pod --selector=app.kubernetes.io/name=traefik-ingress-controller --timeout=120s

bash ./monitoring/jaeger/scripts/create_secrets.sh
kubectl create -f ./monitoring/jaeger/traefik.yml
kubectl wait -n traefik --for=condition=ready pod --selector=app=jaeger-traefik --timeout=240s

kubectl create -k ./jenkins
kubectl wait -n jenkins --for=condition=ready pod --selector=app.kubernetes.io/name=jenkins --timeout=360s