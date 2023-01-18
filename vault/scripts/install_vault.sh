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

kubectl create -k $SCRIPT_DIR/..

echo

kubectl wait --for=condition=Ready --selector app.kubernetes.io/name=vault --selector component=server --timeout=60s pod > /dev/null 2>&1 &
pid=$!

loading $pid "Waiting for Vault to be ready"

bash $SCRIPT_DIR/init_vault.sh

bash $SCRIPT_DIR/enable_pki.sh

bash $SCRIPT_DIR/create_clusterissuer.sh