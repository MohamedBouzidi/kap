#!/bin/env bash

bash ./cluster/create_cluster.sh

kubectl create -k ./cert-manager
kubectl wait -n cert-manager --for=condition=ready pod --selector=app.kubernetes.io/name=cert-manager --timeout=120s

kubectl create -k ./monitoring/prometheus-operator
kubectl wait -n monitoring --for=condition=ready pod --selector=app.kubernetes.io/name=prometheus-operator

kubectl create -k ./ingress-nginx
kubectl wait -n ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=180s

bash ./vault/scripts/install_vault.sh

kubectl create -k ./monitoring/prometheus
kubectl wait -n monitoring --for=condition=ready pod --selector=app.kubernetes.io/name=prometheus-operated

kubectl create -k ./monitoring/grafana
kubectl wait -n monitoring --for=condition=ready pod --selector=app.kubernetes.io/name=grafana --timeout=180s

kubectl create -k ./monitoring/elasticsearch
kubectl wait -n elastic-system --for=condition=ready pod --selector=app.kubernetes.io/name=elastic-operator --timeout=180s

kubectl create -k ./monitoring/jaeger-operator
kubectl wait -n jaeger --for=condition=ready pod --selector=app.kubernetes.io/name=jaeger-operator --timeout=120s

kubectl create -k ./traefik-ingress
kubectl wait -n traefik --for=condition=ready pod --selector=app.kubernetes.io/name=traefik-ingress-controller --timeout=120s

bash ./monitoring/jaeger/scripts/create_secrets.yml
kubectl create -f ./monitoring/jaeger/traefik.yml
kubect wait -n traefik --for=condition=ready pod --selector=name=jaeger-traefik --timeout=120s