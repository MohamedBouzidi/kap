#!/bin/env bash

export SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export ETCD_ENDPOINT=$(kubectl get svc/etcd -n external-dns -o jsonpath='{.spec.clusterIP}')
echo $SCRIPT_DIR
echo $ETCD_ENDPOINT
envsubst < $SCRIPT_DIR/coredns.yml | tee | kubectl apply -f -
