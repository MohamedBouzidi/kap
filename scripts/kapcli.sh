#!/bin/env bash

function display_help() {
    echo "Usage: $0 [subcommand]" >&2
    echo
    echo "  create_project      Create new project"
    echo "  delete_project      Delete project"
    echo "  list_projects       List all projects"
    echo "  create_app          Create new app in project"
    echo "  delete_app          Delete app from project"
    echo "  list_apps           List all apps in project"
    echo "  add_gitlab_ca       Add GitLab CA certificate"
    echo "  remove_gitlab_ca    Remove GitLab CA certificate"
    exit 1
}

function build_app_directory() {
    local PROJECT_NAME=$1
    local APP_NAME=$2
    local APP_TYPE=$3
    local PROJECTS_DIR=$4
    local TEMPLATES_DIR=$5
    local MANIFESTS_DIR=$6
    local ARGO_PATH=$7

    export APP_DIRECTORY=$(mktemp -d)
    cp -r $(find $PROJECTS_DIR/$APP_TYPE -maxdepth 1 -mindepth 1) $APP_DIRECTORY
    mkdir $APP_DIRECTORY/$ARGO_PATH
    for f in $(find $MANIFESTS_DIR -type f -name "*.yml")
    do
        envsubst < $f > $APP_DIRECTORY/$ARGO_PATH/$(basename $f)
    done
    envsubst < $TEMPLATES_DIR/sonar-project.properties > $APP_DIRECTORY/sonar-project.properties
    echo -ne "# Hello ${APP_NAME}\n\nThis is your new application code." > $APP_DIRECTORY/README.md
}

function add_app_badges() {
    local GITLAB_HOST=$1
    local ARGOCD_HOST=$2
    local SONARQUBE_HOST=$3
    local PROJECT_NAME=$4
    local APP_NAME=$5

    SONARQUBE_BADGE=$(bash $HELPERS_DIR/sonarqube.sh get_project_badge --sonarqube-host $SONARQUBE_HOST --project-name "${PROJECT_NAME}-${APP_NAME}")
    ARGOCD_BADGE=$(bash $HELPERS_DIR/argocd.sh get_project_badge --argocd-host $ARGOCD_HOST --app-name $APP_NAME)

    bash $HELPERS_DIR/gitlab.sh add_repo_badge --gitlab-host $GITLAB_HOST --repo-name $APP_NAME --badge-name SonarQube --badge-url $SONARQUBE_BADGE
    bash $HELPERS_DIR/gitlab.sh add_repo_badge --gitlab-host $GITLAB_HOST --repo-name $APP_NAME --badge-name ArgoCD --badge-url $ARGOCD_BADGE
}

function delete_app_resources() {
    local GITLAB_HOST=$1
    local PROJECT_NAME=$2
    local APP_NAME=$3

    REPO_DIR=$(mktemp -d)
    GITLAB_ADMIN_USER=$(kubectl get secret/gitlab-admin-user -n gitlab -o jsonpath='{.data}')
    GITLAB_ADMIN_USERNAME=$(echo $GITLAB_ADMIN_USER | jq -r '.username | @base64d')
    GITLAB_ADMIN_PASSWORD=$(echo $GITLAB_ADMIN_USER | jq -r '.password | @base64d')
    pushd $REPO_DIR
    git init --initial-branch=main
    git config --local http.sslVerify false
    git config --local core.sparseCheckout true
    echo "$ARGO_PATH/" >> .git/info/sparse-checkout
    git remote add origin https://${GITLAB_ADMIN_USERNAME}:${GITLAB_ADMIN_PASSWORD}@${GITLAB_HOST}/${PROJECT_NAME}/${APP_NAME}.git
    git pull --depth=1 origin main
    kubectl --insecure-skip-tls-verify=true delete -k $ARGO_PATH
    popd
    rm -rf $REPO_DIR
}

############################################

[ "$#" -lt 1 ] && display_help

SUBCOMMAND=$1
shift

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
TEMPLATES_DIR=$SCRIPT_DIR/templates
HELPERS_DIR=$SCRIPT_DIR/helpers
PROJECTS_DIR=$TEMPLATES_DIR/projects
MANIFESTS_DIR=$TEMPLATES_DIR/manifests
GITLAB_HOST="gitlab.dev.local:9443"
SONARQUBE_HOST="sonarqube.dev.local:9443"
ARGOCD_HOST="argocd.dev.local:9443"
ARGO_PATH="cd"

case "$SUBCOMMAND" in

    "create_project" )
        if [ "$#" -lt 2 ]; then
            echo "Usage: bash ./kapcli.sh create_project [option...]" >&2
            echo
            echo "  -p, --project-name          Project name"
            echo "  -h, --help                  Show help message"
            exit 1
        fi
        VALID_ARGS=$(getopt -o p:h --long project-name:,help -- "$@")
        eval set -- "$VALID_ARGS"
        while [ : ]; do
            case "$1" in
                -h | --help         )   display_help ;;
                -p | --project-name )   export PROJECT_NAME="$2"; shift 2 ;;
                -- ) shift; break ;;
                * ) break ;;
            esac
        done
        bash $HELPERS_DIR/gitlab.sh create_group --gitlab-host $GITLAB_HOST --group-name $PROJECT_NAME
        bash $HELPERS_DIR/argocd.sh create_project --project-name $PROJECT_NAME
        bash $HELPERS_DIR/traefik.sh add_namespace --namespace $PROJECT_NAME
        ;;

    "delete_project" )
        if [ "$#" -lt 2 ]; then
            echo "Usage: bash ./kapcli.sh delete_project [option...]" >&2
            echo
            echo "  -p, --project-name          Project name"
            echo "  -h, --help                  Show help message"
            exit 1
        fi
        VALID_ARGS=$(getopt -o p:h --long project-name:,help -- "$@")
        eval set -- "$VALID_ARGS"
        while [ : ]; do
            case "$1" in
                -h | --help         )   display_help ;;
                -p | --project-name )   PROJECT_NAME="$2"; shift 2 ;;
                -- ) shift; break ;;
                * ) break ;;
            esac
        done
        bash $HELPERS_DIR/argocd.sh delete_project --project-name $PROJECT_NAME
        bash $HELPERS_DIR/gitlab.sh delete_group --gitlab-host $GITLAB_HOST --group-name $PROJECT_NAME
        bash $HELPERS_DIR/traefik.sh remove_namespace --namespace $PROJECT_NAME
        ;;

    "list_projects" )
        if [ "$#" -lt 2 ]; then
            echo "Usage: bash ./kapcli.sh list_projects [option...]" >&2
            echo
            echo "  -h, --help                  Show help message"
            exit 1
        fi
        VALID_ARGS=$(getopt -o h --long help -- "$@")
        eval set -- "$VALID_ARGS"
        while [ : ]; do
            case "$1" in
                -h | --help         )   display_help ;;
                -- ) shift; break ;;
                * ) break ;;
            esac
        done
        bash $HELPERS_DIR/gitlab.sh list_groups --gitlab-host $GITLAB_HOST
        ;;

    "create_app" )
        if [ "$#" -lt 6 ]; then
            echo "Usage: bash ./kapcli.sh create_app [option...]" >&2
            echo
            echo "  -p, --project-name          Project name"
            echo "  -n, --app-name              App name"
            echo "  -t, --type                  App language (options: $(ls $PROJECTS_DIR | tr '\n' ' '))"
            echo "  -h, --help                  Show help message"
            exit 1
        fi
        VALID_ARGS=$(getopt -o p:n:t:h --long project-name:,app-name:,type:,help -- "$@")
        eval set -- "$VALID_ARGS"
        while [ : ]; do
            case "$1" in
                -h | --help         )   display_help ;;
                -p | --project-name )   export PROJECT_NAME="$2"; shift 2 ;;
                -n | --app-name     )   export APP_NAME="$2"; shift 2 ;;
                -t | --type         )   export APP_TYPE="$2"; shift 2 ;;
                -- ) shift; break ;;
                * ) break ;;
            esac
        done
        build_app_directory $PROJECT_NAME $APP_NAME $APP_TYPE $PROJECTS_DIR $TEMPLATES_DIR $MANIFESTS_DIR $ARGO_PATH
        bash $HELPERS_DIR/gitlab.sh create_repo --gitlab-host $GITLAB_HOST --group-name $PROJECT_NAME --repo-name $APP_NAME
        bash $HELPERS_DIR/sonarqube.sh create_project --sonarqube-host $SONARQUBE_HOST --project-name "${PROJECT_NAME}-${APP_NAME}"
        bash $HELPERS_DIR/gitlab.sh commit_directory --gitlab-host $GITLAB_HOST --group-name $PROJECT_NAME --repo-name $APP_NAME --directory $APP_DIRECTORY
        bash $HELPERS_DIR/argocd.sh create_app --project-name $PROJECT_NAME --app-name $APP_NAME --argo-path $ARGO_PATH
        add_app_badges $GITLAB_HOST $ARGOCD_HOST $SONARQUBE_HOST $PROJECT_NAME $APP_NAME
        rm -rf $APP_DIRECTORY
        ;;

    "delete_app" )
        if [ "$#" -lt 4 ]; then
            echo "Usage: bash ./kapcli.sh delete_app [option...]" >&2
            echo
            echo "  -p, --project-name          Project name"
            echo "  -n, --app-name              App name"
            echo "  -h, --help                  Show help message"
            exit 1
        fi
        VALID_ARGS=$(getopt -o p:n:h --long project-name:,app-name:,help -- "$@")
        eval set -- "$VALID_ARGS"
        while [ : ]; do
            case "$1" in
                -h | --help         )   display_help ;;
                -p | --project-name )   PROJECT_NAME="$2"; shift 2 ;;
                -n | --app-name     )   APP_NAME="$2"; shift 2 ;;
                -- ) shift; break ;;
                * ) break ;;
            esac
        done
        delete_app_resources $GITLAB_HOST $PROJECT_NAME $APP_NAME
        bash $HELPERS_DIR/argocd.sh delete_app --project-name $PROJECT_NAME --app-name $APP_NAME
        bash $HELPERS_DIR/gitlab.sh delete_repo --gitlab-host $GITLAB_HOST --group-name $PROJECT_NAME --repo-name $APP_NAME
        bash $HELPERS_DIR/sonarqube.sh delete_project --sonarqube-host $SONARQUBE_HOST --project-name "${PROJECT_NAME}-${APP_NAME}"
        ;;

    "list_apps" )
        if [ "$#" -lt 4 ]; then
            echo "Usage: bash ./kapcli.sh list_apps [option...]" >&2
            echo
            echo "  -p, --project-name          Project name"
            echo "  -h, --help                  Show help message"
            exit 1
        fi
        VALID_ARGS=$(getopt -o p:h --long project-name:,help -- "$@")
        eval set -- "$VALID_ARGS"
        while [ : ]; do
            case "$1" in
                -h | --help         )   display_help ;;
                -p | --project-name )   PROJECT_NAME="$2"; shift 2 ;;
                -- ) shift; break ;;
                * ) break ;;
            esac
        done
        bash $HELPERS_DIR/gitlab.sh list_repos --gitlab-host $GITLAB_HOST --group-name $PROJECT_NAME
        ;;

    "add_gitlab_ca" )
        bash $HELPERS_DIR/argocd.sh add_gitlab_ca
        ;;

    "remove_gitlab_ca" )
        bash $HELPERS_DIR/argocd.sh remove_gitlab_ca
        ;;
esac