#!/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
GITLAB_HOST="gitlab.dev.local:9443"
GITLAB_REGISTRY="registry.dev.local"
GITLAB_CA_FILE=$(mktemp)

kubectl delete secret/gitlab-ca-cert --namespace argocd
kubectl get secret/gitlab-ca-secret --namespace gitlab -o jsonpath='{.data.ca\.crt}' | base64 -d > $GITLAB_CA_FILE
kubectl create secret generic gitlab-ca-cert --type=Opaque --from-file=gitlab-dev-local=$GITLAB_CA_FILE --namespace argocd

rm $GITLAB_CA_FILE

if ! curl -ks https://${GITLAB_HOST}/-/health > /dev/null 2>&1
then
    echo GitLab is not available
    exit 1
fi

ADMIN_USER=$(kubectl get secret/gitlab-admin-user -n gitlab -o jsonpath='{.data}')
USERNAME=$(echo $ADMIN_USER | jq -r '.username | @base64d')
PASSWORD=$(echo $ADMIN_USER | jq -r '.password | @base64d')
TOKEN=$(curl -ks -X POST -H "Content-Type: application/json" -d "{\"grant_type\":\"password\",\"username\":\"${USERNAME}\",\"password\":\"${PASSWORD}\"}" "https://${GITLAB_HOST}/oauth/token" | jq -r ".access_token")
AUTH_HEADER="Authorization: Bearer ${TOKEN}"

USER_ID=$(curl -ks -X GET -H "Content-Type: application/json" -H "$AUTH_HEADER" "https://${GITLAB_HOST}/api/v4/user"| jq -r ".id")
PERSONAL_ACCESS_TOKEN=$(curl -ks -X POST -H "Content-Type: application/json" -H "$AUTH_HEADER" \
                            -d "{\"name\":\"ArgoImageUpdater\",\"scopes\":[\"read_registry\",\"write_registry\"],\"expires_at\":\"2026-01-31\"}" \
                            "https://${GITLAB_HOST}/api/v4/users/${USER_ID}/personal_access_tokens" | jq -r ".token")

kubectl create -f $SCRIPT_DIR/../namespace.yml
kubectl delete secret/gitlab-registry-creds --namespace argocd
kubectl create secret docker-registry gitlab-registry-creds --docker-server=https://${GITLAB_REGISTRY} --docker-username ArgoImageUpdater --docker-password $PERSONAL_ACCESS_TOKEN --namespace argocd

kubectl create -k $SCRIPT_DIR/..
kubectl wait -n argocd --for=condition=ready pod --selector=app.kubernetes.io/part-of=argocd --timeout=300s
kubectl wait -n argocd --for=condition=ready pod --selector=app.kubernetes.io/part-of=argocd-image-updater --timeout=300s
