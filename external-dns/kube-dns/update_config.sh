#!/bin/env bash

export SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export COREDNS_ADDRESS=$(kubectl get svc/coredns -n external-dns -o jsonpath='{.spec.clusterIP}')

envsubst < $SCRIPT_DIR/coredns.yml | kubectl replace -n kube-system -f -

kubectl rollout restart deployment/coredns -n kube-system
