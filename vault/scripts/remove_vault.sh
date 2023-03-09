#!/bin/env bash

export SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

kubectl delete -k $SCRIPT_DIR/../vault
kubectl delete -k $SCRIPT_DIR/../consul
kubectl delete -k $SCRIPT_DIR/..