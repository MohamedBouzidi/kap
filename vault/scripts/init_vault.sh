#!/bin/env bash


export SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export VAULT_STATUS=$(kubectl exec vault-0 -n vault -- vault operator init -status)

echo $VAULT_STATUS

if [ "$VAULT_STATUS" != "Vault is initialized" ]
then
	echo "[-] Initializing Vault"
	kubectl exec vault-0 -n vault -- vault operator init -key-shares=1 -key-threshold=1 -format=json > $SCRIPT_DIR/cluster-keys.json
	bash $SCRIPT_DIR/unseal_vault.sh
fi

echo "[*] Vault is initialized"
export VAULT_TOKEN=$(cat $SCRIPT_DIR/cluster-keys.json | jq -r ".root_token")
kubectl delete secret/vault-root-token --namespace vault
kubectl create secret generic vault-root-token --namespace vault --from-literal=token=$VAULT_TOKEN
echo Vault Token in secret/vault-root-token
