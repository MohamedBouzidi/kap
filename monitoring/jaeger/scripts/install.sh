#!/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

kubectl create -k $SCRIPT_DIR/../operator
kubectl wait -n jaeger --for=condition=ready pod --selector=app.kubernetes.io/name=jaeger-operator --timeout=600s

bash $SCRIPT_DIR/create_secrets.sh

kubectl create -f $SCRIPT_DIR/../instance
kubectl wait -n jaeger --for=condition=ready pod --selector=app=jaeger-kap --timeout=240s
