#!/bin/env bash

VALID_ARGS=$(getopt -o n: --long namespace: -- "$@")

eval set -- "$VALID_ARGS"
while [ : ]; do
    case "$1" in
        -n | --namespace ) NAMESPACE=$2; shift ;;
        -- ) shift; break ;;
        * ) break ;;
    esac
done

echo NAMESPACE: $NAMESPACE

kubectl delete secret/regcred --namespace $NAMESPACE