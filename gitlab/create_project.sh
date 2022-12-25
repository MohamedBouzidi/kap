#!/bin/env bash

PASSWORD=$(kubectl get secret/gitlab-gitlab-initial-root-password -n gitlab -o jsonpath='{.data.password}' | base64 -d)
TOKEN=$(curl -k -s -X POST -H "Content-Type: application/json" -d "{\"grant_type\":\"password\",\"username\":\"root\",\"password\":\"$PASSWORD\"}" "https://gitlab.dev.local/oauth/token" | jq -r ".access_token")
AUTH_HEADER="Authorization: Bearer $TOKEN"

sleep 2

GROUP_ID=$(curl -k -s -X POST -H "$AUTH_HEADER" -H "Content-Type: application/json" \
	-d '{"name":"Team-X","path":"team-x"}' \
	"https://gitlab.dev.local/api/v4/groups/" | jq -r ".id")

USER_ID=$(curl -k -s -X POST -H "$AUTH_HEADER" -H "Content-Type: application/json" \
	-d '{"email":"dev@project.one","name":"developer-x","username":"developerx","skip_confirmation":"true","password":"hellodeveloper"}' \
	"https://gitlab.dev.local/api/v4/users/" | jq -r ".id")

NAMESPACE_ID=$(curl -k -s -X GET -H "$AUTH_HEADER" -H "Content-Type: application/json" \
	"https://gitlab.dev.local/api/v4/namespaces/team-x" | jq -r ".id")

sleep 3

curl -k -s -X POST -H "$AUTH_HEADER" -H "Content-Type: application/json" \
	-d "{\"id\":\"$GROUP_ID\",\"user_id\":\"$USER_ID\",\"access_level\":\"50\"}" \
	"https://gitlab.dev.local/api/v4/groups/$GROUP_ID/members"

PROJECT_ID=$(curl -k -s -X POST -H "$AUTH_HEADER" -H "Content-Type: application/json" \
	-d "{\"name\":\"project-one\",\"description\":\"Project One\",\"path\":\"project-one\",\"namespace_id\":\"$NAMESPACE_ID\",\"initialize_with_readme\":\"true\"}" \
	"https://gitlab.dev.local/api/v4/projects" | jq -r ".id")

sleep 3

PROJECT_TOKEN=$(curl -k -s -X POST -H "$AUTH_HEADER" -H "Content-Type: application/json" \
	-d '{ "name":"test_token", "scopes":["api", "read_repository", "write_repository", "read_registry", "write_registry"], "expires_at":"2023-01-31", "access_level": 40 }' \
	"https://gitlab.dev.local/api/v4/projects/$PROJECT_ID/access_tokens" | jq -r ".token")

echo $PROJECT_TOKEN
