#!/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

kubectl delete -k $SCRIPT_DIR/../gitlab/gitlab-runner
kubectl delete -k $SCRIPT_DIR/../gitlab/gitlab
kubectl delete -k $SCRIPT_DIR/../gitlab/registry
kubectl delete -k $SCRIPT_DIR/../gitlab

kubectl delete -k $SCRIPT_DIR/../argocd
kubectl delete -k $SCRIPT_DIR/../sonarqube
kubectl delete -k $SCRIPT_DIR/../traefik-ingress

kubectl delete -f $SCRIPT_DIR/../monitoring/jaeger
kubectl delete -k $SCRIPT_DIR/../monitoring/jaeger-operator
kubectl delete -k $SCRIPT_DIR/../monitoring/elasticsearch
kubectl delete -k $SCRIPT_DIR/../monitoring/metrics-server
kubectl delete -k $SCRIPT_DIR/../monitoring

kubectl delete -f dashboard/recommended.yaml

kubectl delete -f $SCRIPT_DIR/../vault/kap-issuer.yml
kubectl delete -k $SCRIPT_DIR/../vault/vault
kubectl delete -k $SCRIPT_DIR/../vault/consul
kubectl delete -k $SCRIPT_DIR/../vault

bash $SCRIPT_DIR/../external-dns/remove.sh
kubectl delete -k $SCRIPT_DIR/../ingress-nginx
kubectl delete -k $SCRIPT_DIR/../cert-manager