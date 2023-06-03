#!/bin/env bash


function display_help() {
    echo "Usage: $0 [subcommand]" >&2
    echo
    echo "  create_project      Create new SonarQube project"
    echo "  delete_project      Delete SonarQube project"
    echo "  get_project_badge   Get SonarQube Quality Gate status badge"
    exit 1
}

function create_project() {
    local SONARQUBE_HOST=$1
    local PROJECT_NAME=$2
    local SONAR_ADMIN_PASSWORD=$3

    if curl -k -s -X POST -u admin:${SONAR_ADMIN_PASSWORD} "https://${SONARQUBE_HOST}/api/projects/create?mainBranch=main&name=${PROJECT_NAME}&project=${PROJECT_NAME}&visibility=public" > /dev/null 2>&1
    then
        echo Project "${PROJECT_NAME}" created.
    else
        echo Could not create project "${PROJECT_NAME}".
    fi
}

function delete_project() {
    local SONARQUBE_HOST=$1
    local PROJECT_NAME=$2
    local SONAR_ADMIN_PASSWORD=$3

    if curl -k -s -X POST -u admin:${SONAR_ADMIN_PASSWORD} "https://${SONARQUBE_HOST}/api/projects/delete?project=${PROJECT_NAME}" > /dev/null 2>&1
    then
        echo Project "${PROJECT_NAME}" has been deleted.
    else
        echo Could not delete project "${PROJECT_NAME}".
    fi
}

function get_project_badge() {
    local SONARQUBE_HOST=$1
    local PROJECT_NAME=$2
    local SONAR_ADMIN_PASSWORD=$3

    PROJECT_TOKEN=$(curl -ks -X GET -u admin:${SONAR_ADMIN_PASSWORD} "https://${SONARQUBE_HOST}/api/project_badges/token?project=${PROJECT_NAME}" | jq -r ".token")
    echo "https://${SONARQUBE_HOST}/api/project_badges/measure?project=${PROJECT_NAME}&metric=alert_status&token=${PROJECT_TOKEN}"
}

############################################

[ "$#" -lt 1 ] && display_help

SUBCOMMAND=$1
shift

case "$SUBCOMMAND" in

    "create_project" )
        if [ "$#" -lt 4 ]; then
            echo "Usage: bash ./sonarqube.sh create_project [option...]" >&2
            echo
            echo "  -s, --sonarqube-host        SonarQube host"
            echo "  -p, --project-name          SonarQube project name"
            echo "  -h, --help                  Show help message"
            exit 1
        fi
        VALID_ARGS=$(getopt -o s:p:h --long sonarqube-host:,project-name:,help -- "$@")
        eval set -- "$VALID_ARGS"
        while [ : ]; do
            case "$1" in
                -h | --help           )     display_help ;;
                -s | --sonarqube-host )     SONARQUBE_HOST="$2"; shift 2 ;;
                -p | --project-name   )     PROJECT_NAME="$2"; shift 2 ;;
                -- ) shift; break ;;
                * ) break ;;
            esac
        done
        SONAR_ADMIN_PASSWORD=$(kubectl get secret/sonarqube-admin-password -n sonarqube -o jsonpath='{.data.password}' | base64 -d)
        create_project $SONARQUBE_HOST $PROJECT_NAME $SONAR_ADMIN_PASSWORD
        ;;

    "delete_project" )
        if [ "$#" -lt 4 ]; then
            echo "Usage: bash ./sonarqube.sh delete_project [option...]" >&2
            echo
            echo "  -s, --sonarqube-host        SonarQube host"
            echo "  -p, --project-name          SonarQube project name"
            echo "  -h, --help                  Show help message"
            exit 1
        fi
        VALID_ARGS=$(getopt -o s:p:h --long sonarqube-host:,project-name:,help -- "$@")
        eval set -- "$VALID_ARGS"
        while [ : ]; do
            case "$1" in
                -h | --help           )     display_help ;;
                -s | --sonarqube-host )     SONARQUBE_HOST="$2"; shift 2 ;;
                -p | --project-name   )     PROJECT_NAME="$2"; shift 2 ;;
                -- ) shift; break ;;
                * ) break ;;
            esac
        done
        SONAR_ADMIN_PASSWORD=$(kubectl get secret/sonarqube-admin-password -n sonarqube -o jsonpath='{.data.password}' | base64 -d)
        delete_project $SONARQUBE_HOST $PROJECT_NAME $SONAR_ADMIN_PASSWORD
        ;;

    "get_project_badge" )
        if [ "$#" -lt 4 ]; then
            echo "Usage: bash ./sonarqube.sh get_project_badge [option...]" >&2
            echo
            echo "  -s, --sonarqube-host        SonarQube host"
            echo "  -p, --project-name          SonarQube project name"
            echo "  -h, --help                  Show help message"
            exit 1
        fi
        VALID_ARGS=$(getopt -o s:p:h --long sonarqube-host:,project-name:,help -- "$@")
        eval set -- "$VALID_ARGS"
        while [ : ]; do
            case "$1" in
                -h | --help           )     display_help ;;
                -s | --sonarqube-host )     SONARQUBE_HOST="$2"; shift 2 ;;
                -p | --project-name   )     PROJECT_NAME="$2"; shift 2 ;;
                -- ) shift; break ;;
                * ) break ;;
            esac
        done
        SONAR_ADMIN_PASSWORD=$(kubectl get secret/sonarqube-admin-password -n sonarqube -o jsonpath='{.data.password}' | base64 -d)
        get_project_badge $SONARQUBE_HOST $PROJECT_NAME $SONAR_ADMIN_PASSWORD
        ;;
esac