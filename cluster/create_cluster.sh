#!/bin/env bash

export SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
kind create cluster --config=$SCRIPT_DIR/kind-config.yml
sed -i -e 's/127\.0\.0\.1:6443/host\.docker\.internal:39673/g' /home/user/.kube/config