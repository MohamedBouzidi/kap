#!/bin/env bash

echo "[-] Creating Cluster Issuer"

export SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
VAULT_SS_CA_SECRET=$(kubectl get secret/vault-ss-ca-secret --namespace vault -o jsonpath='{.data}')
echo $VAULT_SS_CA_SECRET | jq -r '."tls.crt" | @base64d' > $SCRIPT_DIR/vault-ca.crt
echo $VAULT_SS_CA_SECRET | jq -r '."tls.key" | @base64d' > $SCRIPT_DIR/vault-ca.key

kubectl delete secret/vault-ca-secret --namespace cert-manager
kubectl create secret tls vault-ca-secret --namespace cert-manager --cert=$SCRIPT_DIR/vault-ca.crt --key=$SCRIPT_DIR/vault-ca.key

kubectl apply -f $SCRIPT_DIR/../kap-issuer.yml

echo "[*] Cluster Issuer created"