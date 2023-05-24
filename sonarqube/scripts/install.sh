#!/bin/env bash

SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
GITLAB_CA_FILE=$(mktemp)

kubectl create -k $SCRIPT_DIR/..

kubectl delete secret/gitlab-ca-cert --namespace sonarqube
kubectl get secret/gitlab-ca-secret --namespace gitlab -o jsonpath='{.data.ca\.crt}' | base64 -d > $GITLAB_CA_FILE
kubectl create secret generic gitlab-ca-cert --type=Opaque --from-file=gitlab-dev-local=$GITLAB_CA_FILE --namespace sonarqube

kubectl delete secret/gitlab-admin-password --namespace sonarqube
GITLAB_ADMIN_PASSWORD=$(kubectl get secret/gitlab-gitlab-initial-root-password -n gitlab -o jsonpath='{.data.password}' | base64 -d)
kubectl create secret generic gitlab-admin-password --type=Opaque --from-literal=password=$GITLAB_ADMIN_PASSWORD --namespace sonarqube

rm $GITLAB_CA_FILE

kubectl wait -n sonarqube --for=condition=ready pod --selector=release=sonarqube --selector=app=postgresql --timeout=240s
kubectl wait -n sonarqube --for=condition=ready pod --selector=release=sonarqube --selector=app=sonarqube --selector=role=web --timeout=240s