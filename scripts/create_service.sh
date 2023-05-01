#!/bin/env bash

export SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

function display_help() {
    echo "Usage: $0 [option...]" >&2
    echo
    echo "   -s, --service                 ArgoCD application name"
	echo "   -p, --project				   ArgoCD project name"
	echo "   -h, --help                    Show help message"
    echo 
    exit 1
}

function create_application() {
	echo Creating new $SERVICE application for $PROJECT...

	REPOSITORY="https://gitlab.dev.local/${PROJECT}/${SERVICE}" 
	ARGO_PATH="cd"
	NAMESPACE=$PROJECT
	# Default values defined in create_project.sh
	USERNAME="${PROJECT}-owner"
	PASSWORD="hellodeveloper"

	envsubst < $SCRIPT_DIR/templates/project.yml | kubectl apply -f -
	envsubst < $SCRIPT_DIR/templates/application.yml | kubectl apply -f -
}

VALID_ARGS=$(getopt -o s:r:a:n:u:p:h --long service:,repository:,argo-path:,namespace:,username:,password:,help -- "$@")

eval set -- "$VALID_ARGS"
while [ : ]; do
	case "$1" in
		-h | --help       ) 	display_help ;;
		-s | --service    ) 	SERVICE=$2; shift 2 ;;
		-p | --project 	  ) 	PROJECT=2; shift 2 ;;
		-a | --argo-path  ) 	ARGO_PATH=$2; shift 2 ;;
		-- ) shift; break ;;
		* ) break ;;
	esac
done

create_application

# bash scripts/create_service.sh --service hello-service --project hello-proj