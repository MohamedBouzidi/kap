#!/bin/env bash

function display_help() {
    echo "Usage: $0 [subcommand]" >&2
    echo
    echo "  create_project      Create new ArgoCD project"
    echo "  delete_project      Delete ArgoCD project"
    echo "  create_app          Create new ArgoCD app in project"
    echo "  delete_app          Delete ArgoCD app from project"
    echo "  add_gitlab_ca       Add GitLab CA certificate"
    echo "  remove_gitlab_ca    Remove GitLab CA certificate"
    exit 1
}

function add_repository_certificate() {
    local GITLAB_HOST=$1
    local CERTIFICATE_INSTALLED=$(kubectl get configmap/argocd-tls-certs-cm -n argocd -o json | jq -r --arg GITLAB_HOST "$GITLAB_HOST" '.data | has("$GITLAB_HOST")')
    
    if [ "$CERTIFICATE_INSTALLED" == "false" ]; then
        echo "Adding GitLab CA to ArgoCD..."
        GITLAB_CA=$(kubectl get secret/gitlab-ca-secret -n gitlab -o jsonpath='{.data.ca\.crt}' | base64 -d | sed 's/$/\\n/' | tr -d '\n')
        if [ -z "$(kubectl get configmap/argocd-tls-certs-cm -n argocd -o jsonpath='{.data}')" ]; then
            kubectl patch configmap/argocd-tls-certs-cm -n argocd --type json --patch "[{\"op\":\"add\", \"path\":\"/data\", \"value\":{\"$GITLAB_HOST\":\"$GITLAB_CA\"} }]"
        else
            kubectl patch configmap/argocd-tls-certs-cm -n argocd --type json --patch "[{\"op\":\"add\", \"path\":\"/data/$GITLAB_HOST\", \"value\":\"$GITLAB_CA\"}]"
        fi
    fi
}

function remove_repository_certificate() {
    local GITLAB_HOST=$1
    local CERTIFICATE_INSTALLED=$(kubectl get configmap/argocd-tls-certs-cm -n argocd -o json | jq -r --arg GITLAB_HOST "$GITLAB_HOST" '.data | has("$GITLAB_HOST")')

    if [ "$CERTIFICATE_INSTALLED" == "false" ]; then
        echo "Removing GitLab CA from ArgoCD..."
        kubectl patch configmap/argocd-tls-certs-cm -n argocd --type json --patch "[{\"op\":\"remove\", \"path\":\"/data/$GITLAB_HOST\"}]"
    fi
}

############################################

[ "$#" -lt 1 ] && display_help

SUBCOMMAND=$1
shift

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
TEMPLATES_DIR=$SCRIPT_DIR/../templates
GITLAB_HOST="gitlab.dev.local"

case "$SUBCOMMAND" in

    "create_project" )
        if [ "$#" -lt 2 ]; then
            echo "Usage: bash ./argocd.sh create_project [option...]" >&2
            echo
            echo "  -p, --project-name          ArgoCD project name"
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
        add_repository_certificate $GITLAB_HOST
        envsubst < $TEMPLATES_DIR/project.yml | kubectl apply -f -
        ;;
    
    "delete_project" )
        if [ "$#" -lt 2 ]; then
            echo "Usage: bash ./argocd.sh delete_project [option...]" >&2
            echo
            echo "  -p, --project-name          ArgoCD project name"
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
        kubectl delete AppProject/${PROJECT_NAME} --namespace argocd
        ;;

    "create_app" )
        if [ "$#" -lt 4 ]; then
            echo "Usage: bash ./argocd.sh create_app [option...]" >&2
            echo
            echo "  -p, --project-name          ArgoCD project name"
            echo "  -n, --app-name              ArgoCD app name"
            echo "  -h, --help                  Show help message"
            exit 1
        fi
        VALID_ARGS=$(getopt -o p:n:h --long project-name:,app-name:,help -- "$@")
        eval set -- "$VALID_ARGS"
        while [ : ]; do
            case "$1" in
                -h | --help         )   display_help ;;
                -p | --project-name )   export PROJECT_NAME="$2"; shift 2 ;;
                -n | --app-name     )   export APP_NAME="$2"; shift 2 ;;
                -- ) shift; break ;;
                * ) break ;;
            esac
        done
        export REPOSITORY="${GITLAB_HOST}/${PROJECT_NAME}/${APP_NAME}.git"
        export ARGO_PATH="cd"
        export USERNAME="${APP_NAME}_argocd_token"
        export PASSWORD="$(kubectl get secret/${APP_NAME}-gitlab-argocd-token -o jsonpath='{.data.token}' --namespace ${PROJECT_NAME} | base64 -d)"
        envsubst < $TEMPLATES_DIR/application.yml | kubectl apply -f -
        ;;

    "delete_app" )
        if [ "$#" -lt 4 ]; then
            echo "Usage: bash ./argocd.sh create_project [option...]" >&2
            echo
            echo "  -p, --project-name          ArgoCD project name"
            echo "  -n, --app-name              ArgoCD app name"
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
        kubectl delete secret/${APP_NAME}-credentials --namespace argocd
        kubectl delete Application/${APP_NAME} --namespace argocd
        ;;

    "add_gitlab_ca" )
        add_repository_certificate $GITLAB_HOST
        ;;

    "remove_gitlab_ca" )
        remove_repository_certificate $GITLAB_HOST
        ;;
esac