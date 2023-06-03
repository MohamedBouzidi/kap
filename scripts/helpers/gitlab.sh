#!/bin/env bash


function display_help() {
	echo "Usage: $0 [subcommand]" >&2
	echo
	echo "   create_group       Create new Gitlab group"
	echo "   delete_group       Delete Gitlab group"
    echo "   list_groups        List all groups"
    echo "   clear_group        Remove all repos in group"
	echo "   create_repo        Create new Gitlab repo in group"
	echo "   delete_repo        Delete Gitlab repo from group"
    echo "   list_repos         List all repos in group"
    echo "   commit_directory   Commit directory contents to repo"
    echo "   add_repo_badge     Add a badge to a Gitlab repo"
	exit 1
}

function auth() {
    local GITLAB_HOST=$1

	ADMIN_USER=$(kubectl get secret/gitlab-admin-user -n gitlab -o jsonpath='{.data}')
	export USERNAME=$(echo $ADMIN_USER | jq -r '.username | @base64d')
    export PASSWORD=$(echo $ADMIN_USER | jq -r '.password | @base64d')
    export TOKEN=$(curl -k -s -X POST -H "Content-Type: application/json" -d "{\"grant_type\":\"password\",\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\"}" "https://$GITLAB_HOST/oauth/token" | jq -r ".access_token")
	export AUTH_HEADER="Authorization: Bearer $TOKEN"
}

function create_group() {
    local GITLAB_HOST=$1
    local GROUP_NAME=$2

	export GROUP_ID=$(curl -k -s -X POST -H "$AUTH_HEADER" -H "Content-Type: application/json" \
			-d "{\"name\":\"$GROUP_NAME\",\"path\":\"$GROUP_NAME\"}" \
			"https://$GITLAB_HOST/api/v4/groups/" | jq -r ".id")
}

function create_namespace() {
    local NAMESPACE=$1

	if ! kubectl get namespace/${NAMESPACE} > /dev/null 2>&1
    then
        kubectl create namespace ${NAMESPACE}
        kubectl label namespace/${NAMESPACE} kap-app=client
    fi
}

function create_user() {
    local GITLAB_HOST=$1
    local GROUP_NAME=$2

	local ADMIN_USERNAME="${GROUP_NAME}-admin"
	local ADMIN_PASSWORD="${GROUP_NAME}"
	local ADMIN_EMAIL="admin@${GROUP_NAME}.dev"

	export USER_ID=$(curl -k -s -X POST -H "$AUTH_HEADER" -H "Content-Type: application/json" \
			-d "{\"email\":\"${ADMIN_EMAIL}\",\"name\":\"${ADMIN_USERNAME}\",\"username\":\"${ADMIN_USERNAME}\",\"skip_confirmation\":\"true\",\"password\":\"${ADMIN_PASSWORD}\"}" \
			"https://$GITLAB_HOST/api/v4/users/" | jq -r ".id")
	curl -k -s -X POST -H "$AUTH_HEADER" -H "Content-Type: application/json" \
		-d "{\"id\":\"$GROUP_ID\",\"user_id\":\"$USER_ID\",\"access_level\":\"50\"}" \
		"https://$GITLAB_HOST/api/v4/groups/$GROUP_ID/members" > /dev/null 2>&1
	kubectl create configmap gitlab-admin --from-literal=username=${ADMIN_USERNAME} --from-literal=password=${ADMIN_PASSWORD} --from-literal=email=${ADMIN_EMAIL} --namespace ${GROUP_NAME}
}

function create_project() {
    local GITLAB_HOST=$1
    local GROUP_NAME=$2
    local REPO_NAME=$3

    GROUP_ID=$(curl -k -s -X GET -H "$AUTH_HEADER" -H "Content-Type: application/json" \
        "https://$GITLAB_HOST/api/v4/groups?search=${GROUP_NAME}" | jq -r ".[0].id")
	NAMESPACE_ID=$(curl -k -s -X GET -H "$AUTH_HEADER" -H "Content-Type: application/json" \
		"https://$GITLAB_HOST/api/v4/namespaces/$GROUP_ID" | jq -r ".id")
	export PROJECT_ID=$(curl -k -s -X POST -H "$AUTH_HEADER" -H "Content-Type: application/json" \
			-d "{\"name\":\"$REPO_NAME\",\"description\":\"Description for $REPO_NAME\",\"path\":\"$REPO_NAME\",\"namespace_id\":\"$NAMESPACE_ID\",\"initialize_with_readme\":\"false\"}" \
			"https://$GITLAB_HOST/api/v4/projects" | jq -r ".id")
}

function add_project_badge() {
    local GITLAB_HOST=$1
    local REPO_NAME=$2
    local BADGE_NAME=$3
    local BADGE_URL=$4

    PROJECT_ID=$(curl -k -s -X GET -H "$AUTH_HEADER" -H "Content-Type: application/json" \
        "https://${GITLAB_HOST}/api/v4/projects?search=${REPO_NAME}" | jq -r ".[0].id")
    BADGE_OUTPUT=$(curl -k -s -X POST -H "$AUTH_HEADER" -H "Content-Type: application/json" \
        -d "{\"name\":\"$BADGE_NAME\",\"image_url\":\"$BADGE_URL\",\"link_url\":\"$BADGE_URL\"}" \
        "https://$GITLAB_HOST/api/v4/projects/$PROJECT_ID/badges")
}

function create_access_token() {
    local GITLAB_HOST=$1
    local GROUP_NAME=$2
    local REPO_NAME=$3
    local DOCKER_REGISTRY="registry.dev.local"

    USERNAME="${REPO_NAME}_regcrd_token"
	PROJECT_TOKEN=$(curl -k -s -X POST -H "$AUTH_HEADER" -H "Content-Type: application/json" \
		-d "{ \"name\":\"${USERNAME}\", \"scopes\":[\"api\", \"read_registry\", \"write_registry\"], \"expires_at\":\"2026-01-31\", \"access_level\": 50 }" \
		"https://$GITLAB_HOST/api/v4/projects/${PROJECT_ID}/access_tokens" | jq -r ".token")
	kubectl create secret generic ${REPO_NAME}-gitlab-registry-token --from-literal=token=$PROJECT_TOKEN -n $GROUP_NAME
    kubectl create secret docker-registry ${REPO_NAME}-regcred --docker-server=https://${DOCKER_REGISTRY}/${GROUP_NAME} --docker-username $USERNAME --docker-password $PROJECT_TOKEN -n $GROUP_NAME
}

function create_deploy_token() {
    local GITLAB_HOST=$1
    local GROUP_NAME=$2
    local REPO_NAME=$3

    PROJECT_TOKEN=$(curl -k -s -X POST -H "$AUTH_HEADER" -H "Content-Type: application/json" \
        -d "{ \"name\":\"${REPO_NAME}_argocd_token\", \"scopes\":[\"read_repository\", \"write_repository\"], \"expires_at\":\"2026-01-31\", \"access_level\": 50 }" \
        "https://$GITLAB_HOST/api/v4/projects/${PROJECT_ID}/access_tokens" | jq -r ".token")
    kubectl create secret generic ${REPO_NAME}-gitlab-argocd-token --from-literal=token=$PROJECT_TOKEN -n ${GROUP_NAME}
}

function delete_group() {
    local GITLAB_HOST=$1
    local GROUP_NAME=$2

    GROUP_ID=$(curl -k -s -X GET -H "$AUTH_HEADER" -H "Content-Type: application/json" \
        "https://$GITLAB_HOST/api/v4/groups?search=${GROUP_NAME}" | jq -r ".[0].id")
	curl -k -s -X DELETE -H "$AUTH_HEADER" "https://$GITLAB_HOST/api/v4/groups/$GROUP_ID" > /dev/null 2>&1
}

function delete_namespace() {
    local GROUP_NAME=$1

	kubectl get namespace/${GROUP_NAME} > /dev/null 2>&1 && kubectl delete namespace ${GROUP_NAME}
}

function delete_user() {
    local GITLAB_HOST=$1
    local GROUP_NAME=$2

    GROUP_ID=$(curl -k -s -X GET -H "$AUTH_HEADER" -H "Content-Type: application/json" \
        "https://${GITLAB_HOST}/api/v4/groups?search=${GROUP_NAME}" | jq -r ".[0].id")
	GROUP_MEMBERS=$(curl -k -s -X GET -H "$AUTH_HEADER" -H "Content-Type: application/json" "https://${GITLAB_HOST}/api/v4/groups/${GROUP_ID}/members")
    for member in $(echo $GROUP_MEMBERS | jq -r '.[] | @base64')
    do
        USER_ID=$(echo $member | base64 -d | jq -r '.id')
        if [ "$USER_ID" != "1" ]
        then
            echo Deleting USER ID: $USER_ID...
            curl -k -s -X DELETE -H "$AUTH_HEADER" "https://${GITLAB_HOST}/api/v4/users/${USER_ID}"
        fi
    done
}

function delete_project() {
    local GITLAB_HOST=$1
    local REPO_NAME=$2

    PROJECT_ID=$(curl -k -s -X GET -H "$AUTH_HEADER" -H "Content-Type: application/json" \
        "https://${GITLAB_HOST}/api/v4/projects?search=${REPO_NAME}" | jq -r ".[0].id")
    curl -k -s -X DELETE -H "$AUTH_HEADER" -H "Content-Type: application/json" "https://${GITLAB_HOST}/api/v4/projects/${PROJECT_ID}?permanently_remove=true" > /dev/null 2>&1
}

function delete_access_token() {
    local GROUP_NAME=$1
    local REPO_NAME=$2

	kubectl delete secret/${REPO_NAME}-gitlab-registry-token --namespace ${GROUP_NAME}
    kubectl delete secret/${REPO_NAME}-regcred --namespace ${GROUP_NAME}
}

function delete_deploy_token() {
    local GROUP_NAME=$1
    local REPO_NAME=$2

	kubectl delete secret/${REPO_NAME}-gitlab-argocd-token --namespace ${GROUP_NAME}
}

function list_groups() {
    local GITLAB_HOST=$1

    curl -k -s -X GET -H "$AUTH_HEADER" -H "Content-Type: application/json" "https://${GITLAB_HOST}/api/v4/groups" | jq -r 'map(.name) | join("\n")'
}

function list_repos() {
    local GITLAB_HOST=$1
    local GROUP_NAME=$2

    GROUP_ID=$(curl -k -s -X GET -H "$AUTH_HEADER" -H "Content-Type: application/json" \
        "https://${GITLAB_HOST}/api/v4/groups?search=${GROUP_NAME}" | jq -r ".[0].id")
    curl -k -s -X GET -H "$AUTH_HEADER" -H "Content-Type: application/json" "https://${GITLAB_HOST}/api/v4/groups/${GROUP_ID}/projects" | jq -r 'map(.name) | join("\n")'
}

function clear_group() {
    local GITLAB_HOST=$1
    local GROUP_NAME=$2

    repos=$(list_repos $GITLAB_HOST $GROUP_NAME | tr '\n' ' ')
    for repo in $repos
    do
        echo Deleting repo $repo
        delete_project $GITLAB_HOST $repo
        delete_access_token $GROUP_NAME $repo
        delete_deploy_token $GROUP_NAME $repo
        echo
    done
}

function commit_directory() {
    local GITLAB_HOST=$1
    local GROUP_NAME=$2
    local REPO_NAME=$3
    local DIRECTORY=$4
    local PAYLOAD='{"branch": "main", "commit_message": "Initial Commit", "actions": []}'

    for f in $(find $DIRECTORY -type f)
    do
        filename=$(echo $f | awk -F"$DIRECTORY/" '{print $2}')
        PAYLOAD=$(echo $PAYLOAD | jq -r --arg filename "$filename" --rawfile content $DIRECTORY/$filename '.actions[.actions | length] |= . + {"action":"create","file_path":$filename,"content":($content | @base64),"encoding":"base64"}')
    done

    GROUP_ID=$(curl -k -s -X GET -H "$AUTH_HEADER" -H "Content-Type: application/json" \
        "https://${GITLAB_HOST}/api/v4/groups?search=${GROUP_NAME}" | jq -r ".[0].id")
    PROJECT_ID=$(curl -k -s -X GET -H "$AUTH_HEADER" -H "Content-Type: application/json" \
        "https://${GITLAB_HOST}/api/v4/groups/${GROUP_ID}/projects?search=${REPO_NAME}" | jq -r ".[0].id")
    curl -k -s -X POST -H "$AUTH_HEADER" -H "Content-Type: application/json" -d "$PAYLOAD" "https://${GITLAB_HOST}/api/v4/projects/${PROJECT_ID}/repository/commits" > /dev/null 2>&1
}

############################################

[ "$#" -lt 1 ] && display_help

SUBCOMMAND=$1
shift

case "$SUBCOMMAND" in
    
    "create_group" )
        if [ "$#" -lt 4 ]; then
            echo "Usage: bash ./gitlab.sh create_group [option...]" >&2
            echo
            echo "   -g, --gitlab-host          Gitlab host"
            echo "   -p, --group-name           Gitlab group name"
            echo "   -h, --help                 Show help message"
            exit 1
        fi
        VALID_ARGS=$(getopt -o g:p:h --long gitlab-host:,group-name:,help -- "$@")
        eval set -- "$VALID_ARGS"
        while [ : ]; do
            case "$1" in
                -h | --help        )    display_help ;;
                -g | --gitlab-host )    GITLAB_HOST="$2"; shift 2 ;;
                -p | --group-name  )    GROUP_NAME="$2"; shift 2 ;;
                -- ) shift; break ;;
                * ) break ;;
            esac
        done
        auth $GITLAB_HOST
        create_group $GITLAB_HOST $GROUP_NAME
        create_namespace $GROUP_NAME
        create_user $GITLAB_HOST $GROUP_NAME
        ;;


    "create_repo" )
        if [ "$#" -lt 6 ]; then
            echo "Usage: bash ./gitlab.sh create_repo [option...]" >&2
            echo
            echo "   -g, --gitlab-host          Gitlab host"
            echo "   -p, --group-name           Gitlab group name"
            echo "   -r, --repo-name            Gitlab repo name"
            echo "   -h, --help                 Show help message"
            exit 1
        fi
        VALID_ARGS=$(getopt -o g:p:r:h --long gitlab-host:,group-name:,repo-name:,help -- "$@")
        eval set -- "$VALID_ARGS"
        while [ : ]; do
            case "$1" in
                -h | --help        )    display_help ;;
                -g | --gitlab-host )    GITLAB_HOST="$2"; shift 2 ;;
                -p | --group-name  )    GROUP_NAME="$2"; shift 2 ;;
                -r | --repo-name   )    REPO_NAME="$2"; shift 2 ;;
                -- ) shift; break ;;
                * ) break ;;
            esac
        done
        auth $GITLAB_HOST
        create_project $GITLAB_HOST $GROUP_NAME $REPO_NAME
        create_access_token $GITLAB_HOST $GROUP_NAME $REPO_NAME
        create_deploy_token $GITLAB_HOST $GROUP_NAME $REPO_NAME
        ;;


    "delete_group" )
        if [ "$#" -lt 4 ]; then
            echo "Usage: bash ./gitlab.sh delete_group [option...]" >&2
            echo
            echo "   -g, --gitlab-host          Gitlab host"
            echo "   -p, --group-name           Gitlab group name"
            echo "   -h, --help                 Show help message"
            exit 1
        fi
        VALID_ARGS=$(getopt -o g:p:h --long gitlab-host:,group-name:,help -- "$@")
        eval set -- "$VALID_ARGS"
        while [ : ]; do
            case "$1" in
                -h | --help        )    display_help ;;
                -g | --gitlab-host )    GITLAB_HOST="$2"; shift 2 ;;
                -p | --group-name  )    GROUP_NAME="$2"; shift 2 ;;
                -- ) shift; break ;;
                * ) break ;;
            esac
        done
        auth $GITLAB_HOST
        delete_namespace $GROUP_NAME
        # delete_user $GITLAB_HOST $GROUP_NAME
        delete_group $GITLAB_HOST $GROUP_NAME
        ;;


    "delete_repo" )
        if [ "$#" -lt 6 ]; then
            echo "Usage: bash ./gitlab.sh delete_repo [option...]" >&2
            echo
            echo "   -g, --gitlab-host          Gitlab host"
            echo "   -p, --group-name           Gitlab group name"
            echo "   -r, --repo-name            Gitlab repo name"
            echo "   -h, --help                 Show help message"
            exit 1
        fi
        VALID_ARGS=$(getopt -o g:p:r:h --long gitlab-host:,group-name:,repo-name:,help -- "$@")
        eval set -- "$VALID_ARGS"
        while [ : ]; do
            case "$1" in
                -h | --help        )    display_help ;;
                -g | --gitlab-host )    GITLAB_HOST="$2"; shift 2 ;;
                -p | --group-name  )    GROUP_NAME="$2"; shift 2 ;;
                -r | --repo-name   )    REPO_NAME="$2"; shift 2 ;;
                -- ) shift; break ;;
                * ) break ;;
            esac
        done
        auth $GITLAB_HOST
        delete_project $GITLAB_HOST $REPO_NAME
        delete_access_token $GROUP_NAME $REPO_NAME
        delete_deploy_token $GROUP_NAME $REPO_NAME
        ;;

    "list_groups" )
        if [ "$#" -lt 2 ]; then
            echo "Usage: bash ./gitlab.sh list_groups [option...]" >&2
            echo
            echo "   -g, --gitlab-host          Gitlab host"
            echo "   -h, --help                 Show help message"
            exit 1
        fi
        VALID_ARGS=$(getopt -o g:h --long gitlab-host:,help -- "$@")
        eval set -- "$VALID_ARGS"
        while [ : ]; do
            case "$1" in
                -h | --help        )    display_help ;;
                -g | --gitlab-host )    GITLAB_HOST="$2"; shift 2 ;;
                -- ) shift; break ;;
                * ) break ;;
            esac
        done
        auth $GITLAB_HOST
        list_groups $GITLAB_HOST
        ;;

    "list_repos" )
        if [ "$#" -lt 4 ]; then
            echo "Usage: bash ./gitlab.sh list_repos [option...]" >&2
            echo
            echo "   -g, --gitlab-host          Gitlab host"
            echo "   -p, --group-name           Gitlab group name"
            echo "   -h, --help                 Show help message"
            exit 1
        fi
        VALID_ARGS=$(getopt -o g:p:h --long gitlab-host:,group-name:,help -- "$@")
        eval set -- "$VALID_ARGS"
        while [ : ]; do
            case "$1" in
                -h | --help        )    display_help ;;
                -g | --gitlab-host )    GITLAB_HOST="$2"; shift 2 ;;
                -p | --group-name  )    GROUP_NAME="$2"; shift 2 ;;
                -- ) shift; break ;;
                * ) break ;;
            esac
        done
        auth $GITLAB_HOST
        list_repos $GITLAB_HOST $GROUP_NAME
        ;;

    "clear_group" )
        if [ "$#" -lt 4 ]; then
            echo "Usage: bash ./gitlab.sh clear_group [option...]" >&2
            echo
            echo "   -g, --gitlab-host          Gitlab host"
            echo "   -p, --group-name           Gitlab group name"
            echo "   -h, --help                 Show help message"
            exit 1
        fi
        VALID_ARGS=$(getopt -o g:p:h --long gitlab-host:,group-name:,help -- "$@")
        eval set -- "$VALID_ARGS"
        while [ : ]; do
            case "$1" in
                -h | --help        )    display_help ;;
                -g | --gitlab-host )    GITLAB_HOST="$2"; shift 2 ;;
                -p | --group-name  )    GROUP_NAME="$2"; shift 2 ;;
                -- ) shift; break ;;
                * ) break ;;
            esac
        done
        auth $GITLAB_HOST
        clear_group $GITLAB_HOST $GROUP_NAME
        ;;

    "commit_directory" )
        if [ "$#" -lt 8 ]; then
            echo "Usage: bash ./gitlab.sh delete_repo [option...]" >&2
            echo
            echo "   -g, --gitlab-host          Gitlab host"
            echo "   -p, --group-name           Gitlab group name"
            echo "   -r, --repo-name            Gitlab repo name"
            echo "   -d, --directory            Directory to commit"
            echo "   -h, --help                 Show help message"
            exit 1
        fi
        VALID_ARGS=$(getopt -o g:p:r:d:h --long gitlab-host:,group-name:,repo-name:,directory:,help -- "$@")
        eval set -- "$VALID_ARGS"
        while [ : ]; do
            case "$1" in
                -h | --help        )    display_help ;;
                -g | --gitlab-host )    GITLAB_HOST="$2"; shift 2 ;;
                -p | --group-name  )    GROUP_NAME="$2"; shift 2 ;;
                -r | --repo-name   )    REPO_NAME="$2"; shift 2 ;;
                -d | --directory   )    DIRECTORY="$2"; shift 2 ;;
                -- ) shift; break ;;
                * ) break ;;
            esac
        done
        auth $GITLAB_HOST
        commit_directory $GITLAB_HOST $GROUP_NAME $REPO_NAME $DIRECTORY
        ;;

    "add_repo_badge" )
        if [ "$#" -lt 8 ]; then
            echo "Usage: bash ./gitlab.sh add_repo_badge [option...]" >&2
            echo
            echo "   -g, --gitlab-host          Gitlab host"
            echo "   -r, --repo-name            Gitlab repo name"
            echo "   -b, --badge-name           Badge name"
            echo "   -u, --badge-url            Badge URL"
            echo "   -h, --help                 Show help message"
            exit 1
        fi
        VALID_ARGS=$(getopt -o g:r:b:u:h --long gitlab-host:,repo-name:,badge-name:,badge-url:,help -- "$@")
        eval set -- "$VALID_ARGS"
        while [ : ]; do
            case "$1" in
                -h | --help        )    display_help ;;
                -g | --gitlab-host )    GITLAB_HOST="$2"; shift 2 ;;
                -r | --repo-name   )    REPO_NAME="$2"; shift 2 ;;
                -b | --badge-name  )    BADGE_NAME="$2"; shift 2 ;;
                -u | --badge-url   )    BADGE_URL="$2"; shift 2 ;;
                -- ) shift; break ;;
                * ) break ;;
            esac
        done
        auth $GITLAB_HOST
        add_project_badge $GITLAB_HOST $REPO_NAME $BADGE_NAME $BADGE_URL
        ;;
esac