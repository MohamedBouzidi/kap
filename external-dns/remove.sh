#!/bin/env bash

export SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

bash $SCRIPT_DIR/kube-dns/reset_config.sh

kubectl delete -f $SCRIPT_DIR/coredns/rbac
kubectl delete -k $SCRIPT_DIR