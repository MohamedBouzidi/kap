#!/bin/env bash

VALID_ARGS=$(getopt -o g:u:p:e:n: --long group:,username:,password:,email:,namespace: -- "$@")

eval set -- "$VALID_ARGS"
while [ : ]; do
	case "$1" in
		-g | --group ) GROUP=$2; shift 2 ;;
		-u | --username ) USERNAME=$2; shift 2 ;;
		-p | --password ) PASSWORD=$2; shift 2 ;;
		-e | --email ) EMAIL=$2; shift 2 ;;
		-n | --namespace ) NAMESPACE=$2; shift 2 ;;
		-- ) shift; break ;;
		* ) break ;;
	esac
done

echo GROUP: $GROUP
echo USERNAME: $USERNAME
echo PASSWORD: $PASSWORD
echo EMAIL: $EMAIL
echo NAMESPACE: $NAMESPACE

kubectl create secret docker-registry regcred \
	--docker-server=https://registry.dev.local/$GROUP/ \
	--docker-username=$USERNAME \
	--docker-password=$PASSWORD \
	--docker-email=$EMAIL \
	--namespace $NAMESPACE
