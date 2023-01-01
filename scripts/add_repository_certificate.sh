#!/bin/env bash

export GITLAB_URL="gitlab.dev.local"
export GITLAB_CA=$(kubectl get secret/gitlab-ca-secret -n gitlab -o jsonpath='{.data.ca\.crt}' | base64 -d | sed 's/$/\\n/' | tr -d '\n')

if [ -z "$(kubectl get configmap/argocd-tls-certs-cm -n argocd -o jsonpath='{.data}')" ]
then
    kubectl patch configmap/argocd-tls-certs-cm -n argocd --type json --patch "[{\"op\": \"add\", \"path\": \"/data\", \"value\": {\"$GITLAB_URL\": \"$GITLAB_CA\"}}]"
else
    kubectl patch configmap/argocd-tls-certs-cm -n argocd --type json --patch "[{\"op\": \"add\", \"path\": \"/data/$GITLAB_URL\", \"value\": \"$GITLAB_CA\"}]"
fi
