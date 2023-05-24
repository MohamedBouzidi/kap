#!/bin/env bash

SCRIPT_DIR=$(cd -- "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
SONARQUBE_CA_FILE=$(mktemp)

if kubectl get secret/vault-cert --namespace vault
then
    kubectl create -k $SCRIPT_DIR/..
    kubectl delete secret/sonarqube-ca-secret --namespace gitlab
    kubectl get secret/vault-cert --namespace vault -o jsonpath='{.data.ca\.crt}' | base64 -d > $SONARQUBE_CA_FILE
    kubectl create secret generic sonarqube-ca-secret --type=Opaque --from-file=ca.crt=$SONARQUBE_CA_FILE --namespace gitlab
    rm $SONARQUBE_CA_FILE
else
    echo Could not find Vault secret
    exit 1
fi