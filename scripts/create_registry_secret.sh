#!/bin/env bash

VALID_ARGS=$(getopt -o g:n: --long group:,namespace: -- "$@")

eval set -- "$VALID_ARGS"
while [ : ]; do
	case "$1" in
		-g | --group ) GROUP=$2; shift 2 ;;
		-n | --namespace ) NAMESPACE=$2; shift 2 ;;
		-- ) shift; break ;;
		* ) break ;;
	esac
done

echo GROUP: $GROUP
echo NAMESPACE: $NAMESPACE

USERNAME="${GROUP}-owner"
PASSWORD=$(kubectl get secret/gitlab-token --namespace ${NAMESPACE} -o jsonpath='{.data.token}' | base64 -d)
EMAIL="admin@${GROUP}.dev"

kubectl create secret docker-registry regcred \
	--docker-server=https://registry.dev.local/$GROUP/ \
	--docker-username=$USERNAME \
	--docker-password=$PASSWORD \
	--docker-email=$EMAIL \
	--namespace $NAMESPACE

# bash scripts/create_registry_secret.sh --namespace default --group hello-proj 