#!/bin/env bash

export SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

kubectl delete pods -l app=consul -l component=connect-injector -n vault
kubectl rollout restart deployment/consul-consul-connect-injector -n vault
kubectl wait --for=condition=Ready -l app=consul -l component=connect-injector -n vault pod --timeout=300s

kubectl delete pods -l app.kubernetes.io/instance=vault -l component=server -l vault-sealed=true -l vault-initialized=false -n vault
kubectl rollout restart statefulset/vault -n vault
kubectl wait --for=condition=Ready -l app.kubernetes.io/instance=vault -l component=server -n vault pod --timeout=300s

bash $SCRIPT_DIR/unseal_vault.sh