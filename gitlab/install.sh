#!/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

kubectl create -k $SCRIPT_DIR
kubectl wait -n gitlab --for=condition=ready pod --selector=app.kubernetes.io/name=gitlab --selector=gitlab-role=infrastructure --timeout=300s
kubectl wait -n gitlab --for=condition=complete job/gitlab-minio-create-buckets-1 --timeout=120s
kubectl wait -n gitlab --for=condition=complete job/gitlab-shared-secrets-1-ncx --timeout=120s
kubectl wait -n gitlab --for=condition=complete job/gitlab-gitlab-upgrade-check --timeout=120s

kubectl create -k $SCRIPT_DIR/gitlab
kubectl wait -n gitlab --for=condition=ready pod --selector=app.kubernetes.io/name=gitlab --selector=gitlab-role=app --timeout=600s
kubectl wait -n gitlab --for=condition=ready job/gitlab-migrations-1 --timeout=120s
kubectl wait -n gitlab --for=condition=ready job/gitlab-create-admin-user --timeout=120s

kubectl create -k $SCRIPT_DIR/registry
kubectl wait -n gitlab --for=condition=ready pod --selector=app.kubernetes.io/name=registry --selector=gitlab-role=registry --timeout=600s