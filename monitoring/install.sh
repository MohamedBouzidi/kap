#!/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

kubectl create -k $SCRIPT_DIR/metrics-server
kubectl create -k $SCRIPT_DIR
kubectl create -k $SCRIPT_DIR/elasticsearch
kubectl wait -n elastic-system --for=condition=ready pod --selector=app.kubernetes.io/name=elastic-operator --timeout=600s
bash $SCRIPT_DIR/jaeger/scripts/install.sh