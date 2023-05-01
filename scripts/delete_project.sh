#!/bin/env bash


function display_help() {
	echo "Usage: $0 [option...]" >&2
	echo
	echo "   -g, --gitlab-host                 Gitlab host"
	echo "   -p, --project-name                Gitlab project name"
	echo "   -n, --namespace                   Kubernetes namespace to store Gitlab token"
	echo "   -h, --help                        Show help message"
	exit 1
}

function auth() { 
	export PASSWORD=$(kubectl get secret/gitlab-gitlab-initial-root-password -n gitlab -o jsonpath='{.data.password}' | base64 -d)
	export TOKEN=$(curl -k -s -X POST -H "Content-Type: application/json" -d "{\"grant_type\":\"password\",\"username\":\"root\",\"password\":\"$PASSWORD\"}" "https://$GITLAB_HOST/oauth/token" | jq -r ".access_token")
	export AUTH_HEADER="Authorization: Bearer $TOKEN"
}

function delete_group() {
	curl -k -s -X DELETE -H "$AUTH_HEADER" "https://$GITLAB_HOST/api/v4/groups/$PROJECT_NAME" > /dev/null 2>&1
}

function delete_user() {
	GROUP_MEMBERS=$(curl -k -s -X GET -H "$AUTH_HEADER" -H "Content-Type: application/json" "https://$GITLAB_HOST/api/v4/groups/$PROJECT_NAME/members")
    for member in $(echo $GROUP_MEMBERS | jq -r '.[] | @base64')
    do
        USER_ID=$(echo $member | base64 -d | jq -r '.id')
        if [ "$USER_ID" != "1" ]
        then
            echo Deleting USER ID: $USER_ID...
            curl -k -s -X DELETE -H "$AUTH_HEADER" "https://$GITLAB_HOST/api/v4/users/$USER_ID"
        fi
    done
}

function delete_project() {
	curl -k -s -X DELETE -H "$AUTH_HEADER" -H "Content-Type: application/json" "https://$GITLAB_HOST/api/v4/projects/$PROJECT_NAME" > /dev/null 2>&1
}

function delete_token() {
	kubectl delete secret/gitlab-token --namespace ${NAMESPACE}
}

GITLAB_DEFAULT_HOST="gitlab.dev.local:9443"
DEFAULT_NAMESPACE="default"
VALID_ARGS=$(getopt -o g:p:n:h --long gitlab-host:,project-name:,namespace:,help -- "$@")

eval set -- "$VALID_ARGS"
while [ : ]; do
	case "$1" in
		-h | --help ) display_help ;;
		-g | --gitlab ) export GITLAB_HOST=$2; shift 2 ;;
		-p | --project-name ) export PROJECT_NAME=$2; shift 2 ;;
		-n | --namespace ) export NAMESPACE=$2; shift 2 ;;
		-- ) shift; break ;;
		* ) break ;;
	esac
done

GITLAB_HOST=${GITLAB_HOST:-$GITLAB_DEFAULT_HOST}
NAMESPACE=${NAMESPACE:-$DEFAULT_NAMESPACE}

echo GITLAB HOST: $GITLAB_HOST
echo PROJECT NAME: $PROJECT_NAME
echo NAMESPACE: $NAMESPACE

auth
delete_token
delete_user
delete_project
delete_group

kubectl delete namespace/${NAMESPACE}