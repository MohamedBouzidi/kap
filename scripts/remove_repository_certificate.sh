#!/bin/env bash

export GITLAB_URL="gitlab.dev.local"

kubectl patch configmap/argocd-tls-certs-cm -n argocd --type json --patch "[{\"op\": \"remove\", \"path\": \"/data/$GITLAB_URL\"}]"