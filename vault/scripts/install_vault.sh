#!/bin/env bash

export SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

#### INSTALL NAMESPACE
kubectl create -k $SCRIPT_DIR/..
kubectl wait -n vault --for=condition=ready certificate/vault-ss-cert --timeout=120s

#### INSTALL CONSUL
kubectl create -k $SCRIPT_DIR/../consul
until [[ "$(kubectl get pods -n vault -l app.kubernetes.io/name=consul -o jsonpath='{.items}')" != "[]" ]]; do sleep 5; done
kubectl wait -n vault --for=condition=Ready -l app.kubernetes.io/name=consul pod --timeout=180s

#### INSTALL VAULT
kubectl create -k $SCRIPT_DIR/../vault
until [[ "$(kubectl get pods -n vault -l app.kubernetes.io/name=vault -o jsonpath='{.items}')" != "[]" ]]; do sleep 5; done
kubectl wait -n vault --for=condition=Ready -l app.kubernetes.io/name=vault pod --timeout=180s

#### SETUP VAULT
bash $SCRIPT_DIR/init_vault.sh
bash $SCRIPT_DIR/enable_pki.sh
bash $SCRIPT_DIR/create_clusterissuer.sh