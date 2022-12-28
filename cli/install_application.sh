#!/bin/env bash

export GITLAB_URL="gitlab.dev.local"
export GITLAB_CA=$(kubectl get secret/gitlab-ca-secret -n gitlab -o jsonpath='{.data.ca\.crt}' | base64 -d | tr '\n' '\t' | sed 's/\t/\n     /g')
export SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

envsubst < $SCRIPT_DIR/argocd-tls-certs-cm.template.yml > $SCRIPT_DIR/argocd-tls-certs-cm.yml

if [ -z "$(kubectl get configmap/argocd-tls-certs-cm -n argocd -o jsonpath='{.data}')" ]
then
	kubectl patch configmap/argocd-tls-certs-cm -n argocd --type json --patch "[{\"op\": \"add\", \"path\": \"/data\", \"value\": {\"$GITLAB_URL\": \"$GITLAB_CA\"}}]"
else
	kubectl patch configmap/argocd-tls-certs-cm -n argocd --type json --patch "[{\"op\": \"add\", \"path\": \"/data/$GITLAB_URL\", \"value\": \"$GITLAB_CA\"}]"
fi

#export NAME=service-1
#export REPO_URL=gitlab.dev.local/team-x/project-one.git
#export APP_PATH="cd"
#export NAMESPACE=service-1
#
#export EMAIL="developer@project.one"
#export USERNAME="developerx"
#export PASSWORD="hellodeveloper"
#export REGISTRY_URL="registry.dev.local/team-x/project-one"
#export DOCKER_CONFIG=$(echo "{\"auths\":{\"$REGISTRY_URL\":{\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\",\"email\":\"$EMAIL\"}}}" | base64 -w 0) 
#
#envsubst < $SCRIPT_DIR/application.yml | kubectl apply -f -
