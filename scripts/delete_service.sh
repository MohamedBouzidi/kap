#!/bin/env bash

VALID_ARGS=$(getopt -o a:n: --long application:,namespace: -- "$@")

eval set -- "$VALID_ARGS"
while [ : ]; do
    case "$1" in
        -a | --application ) APPLICATION=$2; shift 2 ;;
        -n | --namespace ) NAMESPACE=$2; shift ;;
        -- ) shift; break ;;
        * ) break ;;
    esac
done

echo APPLICATION: $APPLICATION
echo NAMESPACE: $NAMESPACE

kubectl delete secret/regcred --namespace $NAMESPACE
kubectl delete secret/$APPLICATION-credentials --namespace argocd
kubectl delete application/$APPLICATION --namespace argocd

# bash scripts/uninstall_application.sh --application hello-proj --namespace default
