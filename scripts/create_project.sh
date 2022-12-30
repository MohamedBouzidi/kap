#!/bin/env bash

GITLAB_HOST=$1
NAMESPACE=$2

function auth() { 
	export PASSWORD=$(kubectl get secret/gitlab-gitlab-initial-root-password -n gitlab -o jsonpath='{.data.password}' | base64 -d)
	export TOKEN=$(curl -k -s -X POST -H "Content-Type: application/json" -d "{\"grant_type\":\"password\",\"username\":\"root\",\"password\":\"$PASSWORD\"}" "https://$GITLAB_HOST/oauth/token" | jq -r ".access_token")
	export AUTH_HEADER="Authorization: Bearer $TOKEN"
}

function create_group() {
	GROUP_NAME=$1
	GROUP_PATH=$2
	export GROUP_ID=$(curl -k -s -X POST -H "$AUTH_HEADER" -H "Content-Type: application/json" \
			-d "{\"name\":\"$GROUP_NAME\",\"path\":\"$GROUP_PATH\"}" \
			"https://$GITLAB_HOST/api/v4/groups/" | jq -r ".id")
}

function create_user() {
	GROUP_ID=$1
	USER_NAME=
	export USER_ID=$(curl -k -s -X POST -H "$AUTH_HEADER" -H "Content-Type: application/json" \
			-d '{"email":"dev@project.one","name":"developer-x","username":"developerx","skip_confirmation":"true","password":"hellodeveloper"}' \
			"https://$GITLAB_HOST/api/v4/users/" | jq -r ".id")

	curl -k -s -X POST -H "$AUTH_HEADER" -H "Content-Type: application/json" \
		-d "{\"id\":\"$GROUP_ID\",\"user_id\":\"$USER_ID\",\"access_level\":\"50\"}" \
		"https://$GITLAB_HOST/api/v4/groups/$GROUP_ID/members"
}

function create_project() {
	GROUP_ID=$1
	NAMESPACE_ID=$(curl -k -s -X GET -H "$AUTH_HEADER" -H "Content-Type: application/json" \
		"https://$GITLAB_HOST/api/v4/namespaces/$GROUP_ID" | jq -r ".id")
	export PROJECT_ID=$(curl -k -s -X POST -H "$AUTH_HEADER" -H "Content-Type: application/json" \
			-d "{\"name\":\"project-one\",\"description\":\"Project One\",\"path\":\"project-one\",\"namespace_id\":\"$NAMESPACE_ID\",\"initialize_with_readme\":\"true\"}" \
			"https://$GITLAB_HOST/api/v4/projects" | jq -r ".id")
}

function create_token() {
	PROJECT_TOKEN=$(curl -k -s -X POST -H "$AUTH_HEADER" -H "Content-Type: application/json" \
		-d '{ "name":"test_token", "scopes":["api", "read_repository", "write_repository", "read_registry", "write_registry"], "expires_at":"2023-01-31", "access_level": 40 }' \
		"https://$GITLAB_HOST/api/v4/projects/$PROJECT_ID/access_tokens" | jq -r ".token")
	kubectl create secret generic gitlab-token --from-literal=token=$PROJECT_TOKEN -n ${NAMESPACE:-default}
}

while getopts ":g:p:u:" options; do
	case "${options}" in
		g)
			GROUP_NAME=${OPTARG}
			;;
		p)
			PROJECT_NAME=${OPTARG}
			;;
		u)
			USER_NAME=${OPTARG}
			;;
	esac
done

echo $PROJECT_NAME $USER_NAME