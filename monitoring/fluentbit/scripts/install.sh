#!/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

export ES_USERNAME="elastic"
export ES_PASSWORD=$(kubectl get secret/kap-elastic-es-elastic-user -n elastic-system -o jsonpath='{.data.elastic}' | base64 -d)

envsubst < $SCRIPT_DIR/../configmap.yml | kubectl create -f-

ES_CA_FILE=$(mktemp)
kubectl get secret/kap-elastic-es-http-certs-public -o jsonpath='{.data.ca\.crt}' -n elastic-system | base64 -d > $ES_CA_FILE
kubectl delete secret/kap-elastic-ca -n monitoring
kubectl create secret generic kap-elastic-ca --type=Opaque --from-file=ca.crt=$ES_CA_FILE -n monitoring
rm $ES_CA_FILE

kubectl create -k $SCRIPT_DIR/..
kubectl wait -n monitoring --for=condition=ready pod --selector=app=fluentbit --selector=release=fluentbit --timeout=300s
