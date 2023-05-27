#!/bin/env bash

SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
GITLAB_CA_FILE=$(mktemp)

kubectl create -k $SCRIPT_DIR/..

kubectl delete secret/gitlab-ca-cert --namespace sonarqube
kubectl get secret/gitlab-ca-secret --namespace gitlab -o jsonpath='{.data.ca\.crt}' | base64 -d > $GITLAB_CA_FILE
kubectl create secret generic gitlab-ca-cert --type=Opaque --from-file=gitlab-dev-local=$GITLAB_CA_FILE --namespace sonarqube

kubectl delete secret/gitlab-admin-user --namespace sonarqube
GITLAB_ADMIN_USER=$(kubectl get secret/gitlab-admin-user -n gitlab -o jsonpath='{.data}')
GITLAB_ADMIN_USERNAME=$(echo $GITLAB_ADMIN_USER | jq -r '.username | @base64d')
GITLAB_ADMIN_PASSWORD=$(echo $GITLAB_ADMIN_USER | jq -r '.password | @base64d')
kubectl create secret generic gitlab-admin-user --type=Opaque --from-literal=username=$GITLAB_ADMIN_USERNAME --from-literal=password=$GITLAB_ADMIN_PASSWORD --namespace sonarqube

rm $GITLAB_CA_FILE

kubectl wait -n sonarqube --for=condition=ready pod --selector=release=sonarqube --selector=app=postgresql --timeout=240s
kubectl wait -n sonarqube --for=condition=ready pod --selector=release=sonarqube --selector=app=sonarqube --selector=role=web --timeout=240s