#!/bin/env bash

export SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export ETCD_ENDPOINT=$(kubectl get svc/etcd -n external-dns -o jsonpath='{.spec.clusterIP}')

envsubst < $SCRIPT_DIR/configmap.yml | tee | kubectl apply -f -

kubectl apply -f $SCRIPT_DIR/rbac
kubectl apply -f $SCRIPT_DIR/deployment.yml
kubectl apply -f $SCRIPT_DIR/service.yml