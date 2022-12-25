#!/bin/env bash

PASSWORD=$(kubectl get secret/gitlab-gitlab-initial-root-password -n gitlab -o jsonpath='{.data.password}' | base64 -d)
TOKEN=$(curl -k -s -X POST -H "Content-Type: application/json" -d "{\"grant_type\":\"password\",\"username\":\"root\",\"password\":\"$PASSWORD\"}" "https://gitlab.dev.local/oauth/token" | jq -r ".access_token")
AUTH_HEADER="Authorization: Bearer $TOKEN"

sleep 2

PROJECT_TOKEN=$(curl -k -s -X POST -H "$AUTH_HEADER" -H "Content-Type: application/json" \
	-d '{ "name":"argocd_token", "scopes":["read_repository", "write_repository", "read_registry", "write_registry"], "expires_at":"2023-01-31", "access_level": 40 }' \
	"https://gitlab.dev.local/api/v4/projects/$PROJECT_ID/access_tokens" | jq -r ".token")

echo $PROJECT_TOKEN
