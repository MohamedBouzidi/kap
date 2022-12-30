#!/bin/env bash

USERNAME=$1
PASSWORD=$2
EMAIL=$3
NAMESPACE=$4

kubectl create secret docker-registry regcred \
	--docker-server=https://registry.dev.local/team-x/ \
	--docker-username=$USERNAME \
	--docker-password=$PASSWORD \
	--docker-email=$EMAIL \
	--namespace $NAMESPACE