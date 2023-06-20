#!/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
GITLAB_HOST="gitlab.dev.local"
GITLAB_REGISTRY="registry.dev.local"

kubectl create -f $SCRIPT_DIR/../namespace.yml

GITLAB_CA_FILE=$(mktemp)
kubectl delete secret/gitlab-ca-cert --namespace argocd
kubectl get secret/gitlab-ca-secret --namespace gitlab -o jsonpath='{.data.ca\.crt}' | base64 -d > $GITLAB_CA_FILE
kubectl create secret generic gitlab-ca-cert --type=Opaque --from-file=gitlab-dev-local=$GITLAB_CA_FILE --namespace argocd
rm $GITLAB_CA_FILE

if kubectl get secret/vault-cert --namespace vault --no-headers > /dev/null 2>&1
then
    KEYCLOAK_CA_FILE=$(mktemp)
    kubectl delete secret/keycloak-ca-secret --namespace argocd
    kubectl get secret/vault-cert --namespace vault -o jsonpath='{.data.ca\.crt}' | base64 -d > $KEYCLOAK_CA_FILE
    kubectl create secret generic keycloak-ca-secret --type=Opaque --from-file=keycloak-ca.crt=$KEYCLOAK_CA_FILE --namespace argocd
    rm $KEYCLOAK_CA_FILE
else
    echo Could not find Vault secret
fi

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

kubectl delete secret/gitlab-registry-creds --namespace argocd
kubectl create secret docker-registry gitlab-registry-creds --docker-server=https://${GITLAB_REGISTRY} --docker-username ArgoImageUpdater --docker-password $PERSONAL_ACCESS_TOKEN --namespace argocd

kubectl create -f $SCRIPT_DIR/../configmap.yml
KEYCLOAK_OIDC_CLIENT_SECRET=$(kubectl exec -it deployment/keycloak --namespace keycloak -- bash /opt/scripts/get-argocd-client-secret.sh | tr -d '[:space:]')
kubectl patch secret/argocd-secret -n argocd --type json --patch "[{\"op\":\"add\",\"path\":\"/data\",\"value\":{\"oidc.keycloak.clientSecret\": \"$(echo -n $KEYCLOAK_OIDC_CLIENT_SECRET | base64)\"}}]"

kubectl create -k $SCRIPT_DIR/..
kubectl wait -n argocd --for=condition=ready pod --selector=app.kubernetes.io/part-of=argocd-image-updater --timeout=300s
