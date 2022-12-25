#!/bin/env bash

PASSWORD="kubectl get secret/gitlab-gitlab-initial-root-password -n gitlab -o jsonpath='{.data.password}' | base64 -d"
GITLAB_URL="root:$PASSWORD@gitlab.dev.local""

PROJECT_ID=$(curl -X POST -H "PRIVATE-TOKEN: $TOKEN" -H "Content-Type: application/json" \
	-d '{"name":"project-one","description":"Project One","path":"project-one","initialize_with_readme":"true"}' \
	"https://$GITLAB_URL/api/v4/projects/" | jq -r "")

PROJECT_TOKEN=$(curl -X POST -H "PRIVATE-TOKEN: $TOKEN" -H "Content-Type: application/json" \
	-d '{"name":"kap","scopes":["api","read_repository","write_repository","read_registry","write_registry"], "expires_at":"2024-01-01","access_level":30}' \
	"https://$GITLAB_URL/api/v4/projects/$PROJECT_ID/access_tokens" | jq -r ".token")

echo $PROJECT_TOKEN
