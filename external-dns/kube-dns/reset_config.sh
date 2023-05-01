#!/bin/env bash

export SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

kubectl replace -n kube-system -f $SCRIPT_DIR/coredns.initial.yml
kubectl rollout restart deployment/coredns -n kube-system