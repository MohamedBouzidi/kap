#!/bin/env bash

export SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

function loading() {
    pid=$1
    msg=$2

    declare arr=(
        ""
        "."
        ".."
        "..."
    )

    while kill -0 $pid
    do
        for i in ${arr[@]}
        do
            echo "[-] ${msg}${i}"
            sleep 0.2
            tput cuu1
            tput el
        done
    done
    echo "[*] $msg"
}

#### INSTALL NAMESPACE

kubectl create -k $SCRIPT_DIR/..

#### INSTALL CONSUL

kubectl create -k $SCRIPT_DIR/../consul

echo

while [ -n "$(kubectl get pods --selector app.kubernetes.io/name=consul --selector component=server --namespace vault > /dev/null 2>&1)" ]
do
    sleep 1
done
kubectl wait --namespace vault --for=condition=Ready --selector app.kubernetes.io/name=consul --selector component=server pod --timeout=300s > /dev/null 2>&1 &
pid=$!

loading $pid "Waiting for Consul to be ready"

echo

#### INSTALL VAULT

kubectl create -k $SCRIPT_DIR/../vault

echo

while [ "$(kubectl get statefulset/vault -n vault -o jsonpath='{.status.availableReplicas}')" -eq "0" ]
do
    sleep 1
done
kubectl wait --namespace vault --for=condition=Ready --selector app.kubernetes.io/name=vault --selector component=server pod --timeout=300s > /dev/null 2>&1 &
pid=$!

loading $pid "Waiting for Vault to be ready"

echo

#### SETUP VAULT

bash $SCRIPT_DIR/init_vault.sh

bash $SCRIPT_DIR/enable_pki.sh

bash $SCRIPT_DIR/create_clusterissuer.sh

#### INSTALL CLUSTER ISSUER

kubectl create -f $SCRIPT_DIR/../kap-issuer.yml