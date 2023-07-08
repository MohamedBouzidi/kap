#!/bin/env bash

export SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
mkdir -p /home/user/.kube
kind get kubeconfig --name kind > /home/user/.kube/config
sed -i -e 's/127\.0\.0\.1:6443/host\.docker\.internal:39673/g' /home/user/.kube/config