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

function create_group() {
	export GROUP_ID=$(curl -k -s -X POST -H "$AUTH_HEADER" -H "Content-Type: application/json" \
			-d "{\"name\":\"$PROJECT_NAME\",\"path\":\"$PROJECT_NAME\"}" \
			"https://$GITLAB_HOST/api/v4/groups/" | jq -r ".id")
}

function create_namespace() {
	kubectl get namespace/${NAMESPACE} > /dev/null 2>&1 || kubectl create namespace ${NAMESPACE}
}

function create_user() {
	ADMIN_USERNAME="${PROJECT_NAME}-owner"
	ADMIN_PASSWORD="hellodeveloper"
	ADMIN_EMAIL="admin@${PROJECT_NAME}.dev"

	export USER_ID=$(curl -k -s -X POST -H "$AUTH_HEADER" -H "Content-Type: application/json" \
			-d "{\"email\":\"${ADMIN_EMAIL}\",\"name\":\"${ADMIN_USERNAME}\",\"username\":\"${ADMIN_USERNAME}\",\"skip_confirmation\":\"true\",\"password\":\"${ADMIN_PASSWORD}\"}" \
			"https://$GITLAB_HOST/api/v4/users/" | jq -r ".id")

	curl -k -s -X POST -H "$AUTH_HEADER" -H "Content-Type: application/json" \
		-d "{\"id\":\"$GROUP_ID\",\"user_id\":\"$USER_ID\",\"access_level\":\"50\"}" \
		"https://$GITLAB_HOST/api/v4/groups/$GROUP_ID/members" > /dev/null 2>&1

	kubectl create configmap gitlab-admin --from-literal=username=${ADMIN_USERNAME} --from-literal=password=${ADMIN_PASSWORD} --from-literal=email=${ADMIN_EMAIL} --namespace ${NAMESPACE}
}

function create_project() {
	NAMESPACE_ID=$(curl -k -s -X GET -H "$AUTH_HEADER" -H "Content-Type: application/json" \
		"https://$GITLAB_HOST/api/v4/namespaces/$GROUP_ID" | jq -r ".id")
	export PROJECT_ID=$(curl -k -s -X POST -H "$AUTH_HEADER" -H "Content-Type: application/json" \
			-d "{\"name\":\"$PROJECT_NAME\",\"description\":\"Description for $PROJECT_NAME\",\"path\":\"$PROJECT_NAME\",\"namespace_id\":\"$NAMESPACE_ID\",\"initialize_with_readme\":\"true\"}" \
			"https://$GITLAB_HOST/api/v4/projects" | jq -r ".id")
}

function create_token() {
	PROJECT_TOKEN=$(curl -k -s -X POST -H "$AUTH_HEADER" -H "Content-Type: application/json" \
		-d '{ "name":"test_token", "scopes":["api", "read_repository", "write_repository", "read_registry", "write_registry"], "expires_at":"2023-01-31", "access_level": 40 }' \
		"https://$GITLAB_HOST/api/v4/projects/$PROJECT_ID/access_tokens" | jq -r ".token")
	kubectl create secret generic gitlab-token --from-literal=token=$PROJECT_TOKEN -n ${NAMESPACE}
}

GITLAB_DEFAULT_HOST="gitlab.dev.local:9443"
DEFAULT_NAMESPACE="default"
VALID_ARGS=$(getopt -o g:p:n:h --long gitlab-host:,project-name:,namespace:,help -- "$@")

eval set -- "$VALID_ARGS"
while [ : ]; do
	case "$1" in
		-h | --help ) display_help ;;
		-g | --gitlab-host ) export GITLAB_HOST="$2"; shift 2 ;;
		-p | --project-name ) export PROJECT_NAME="$2"; shift 2 ;;
		-n | --namespace ) export NAMESPACE="$2"; shift 2 ;;
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
create_group
create_namespace
create_user
create_project
create_token