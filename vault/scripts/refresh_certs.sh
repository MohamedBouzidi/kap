#!/bin/env bash

certs=$(kubectl get certificate -o json -A | jq -r '.items[] | select(.spec.issuerRef.name == "kap-vault-issuer") | [.metadata.name, .metadata.namespace] | join("#")')

for cert in $(echo $certs)
do
    cert=$(echo $cert | sed 's/#/ -n /g')
    sh -c "kubectl delete certificate/$cert"
    sh -c "kubectl delete secret/$cert"
done