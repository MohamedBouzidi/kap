#!/bin/env bash

SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
GITLAB_CA_FILE=$(mktemp)

kubectl create -k $SCRIPT_DIR/..
kubectl delete secret/gitlab-ca-cert --namespace sonarqube
kubectl get secret/gitlab-ca-secret --namespace gitlab -o jsonpath='{.data.ca\.crt}' | base64 -d > $GITLAB_CA_FILE
kubectl create secret generic gitlab-ca-cert --type=Opaque --from-file=gitlab-dev-local=$GITLAB_CA_FILE --namespace sonarqube

rm $GITLAB_CA_FILE