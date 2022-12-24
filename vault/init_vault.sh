#!/bin/env bash

export SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export VAULT_STATUS=$(kubectl exec vault-0 -n vault -- vault operator init -status)

echo $VAULT_STATUS

if [ "$VAULT_STATUS" != "Vault is initialized" ]
then
	kubectl exec vault-0 -n vault -- vault operator init -key-shares=1 -key-threshold=1 -format=json > $SCRIPT_DIR/cluster-keys.json
	export VAULT_UNSEAL_KEY=$(cat $SCRIPT_DIR/cluster-keys.json | jq -r ".unseal_keys_b64[]")
	kubectl exec vault-0 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY
	kubectl exec vault-1 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY
	kubectl exec vault-2 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY
fi

export VAULT_TOKEN=$(cat $SCRIPT_DIR/cluster-keys.json | jq -r ".root_token")
echo Vault Token: $VAULT_TOKEN
