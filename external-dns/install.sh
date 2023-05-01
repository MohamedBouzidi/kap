#!/bin/env bash

export SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

kubectl create -k $SCRIPT_DIR

kubectl create -k $SCRIPT_DIR/etcd
kubectl wait --for=condition=Ready --selector app=external-dns-etcd pod --namespace external-dns --timeout=120s

kubectl create -k $SCRIPT_DIR/external-dns
kubectl wait --for=condition=Ready --selector app=external-dns pod --namespace external-dns --timeout=120s

bash $SCRIPT_DIR/coredns/install_coredns.sh
kubectl wait --for=condition=Ready --selector app=coredns pod --namespace external-dns --timeout=120s

bash $SCRIPT_DIR/kube-dns/update_config.sh