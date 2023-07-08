#!/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

bash $SCRIPT_DIR/../cluster/kind/create_cluster.sh

kubectl create -k $SCRIPT_DIR/../cert-manager
kubectl wait -n cert-manager --for=condition=ready pod --selector=app.kubernetes.io/instance=cert-manager --timeout=120s
kubectl wait --for=condition=Available apiservice v1.cert-manager.io --timeout=60s
kubectl wait --for=condition=Available apiservice v1.acme.cert-manager.io --timeout=60s

sleep 60

kubectl create namespace monitoring
kubectl create -k $SCRIPT_DIR/../monitoring/prometheus-operator
kubectl wait -n monitoring --for=condition=ready pod --selector=app.kubernetes.io/name=prometheus-operator --timeout=120s

kubectl create -k $SCRIPT_DIR/../ingress-nginx
kubectl wait -n ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=240s

bash $SCRIPT_DIR/../external-dns/install.sh
bash $SCRIPT_DIR/../vault/scripts/install_vault.sh

bash $SCRIPT_DIR/../monitoring/install.sh
# kubectl apply -f $SCRIPT_DIR/../dashboard/recommended.yaml

kubectl create -k $SCRIPT_DIR/../traefik-ingress
kubectl wait -n traefik --for=condition=ready pod --selector=app.kubernetes.io/name=traefik-ingress-controller --timeout=300s

kubectl create -k $SCRIPT_DIR/../keycloak
kubectl wait -n keycloak --for=condition=ready pod --selector=app=keycloak --selector=release=keycloak --selector=role=web --timeout=300s

bash $SCRIPT_DIR/../gitlab/install.sh
bash $SCRIPT_DIR/../sonarqube/scripts/install.sh
bash $SCRIPT_DIR/../gitlab/gitlab-runner/scripts/install.sh
bash $SCRIPT_DIR/../argocd/scripts/install.sh

# kubectl create -k $SCRIPT_DIR/../jenkins
# kubectl wait -n jenkins --for=condition=ready pod --selector=app.kubernetes.io/name=jenkins --timeout=360s

# kubectl create -k $SCRIPT_DIR/../portainer
# kubectl wait -n portainer --for=condition=ready pod --selector=app.kubernetes.io/name=portainer --timeout=180s