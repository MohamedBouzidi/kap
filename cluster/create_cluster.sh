#!/bin/env bash

export SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
kind create cluster --config=<(envsubst < $SCRIPT_DIR/kind-config.yml)
sed -i -e 's/0\.0\.0\.0:9443/${KIND_IP}:9443/g' /home/user/.kube/config
