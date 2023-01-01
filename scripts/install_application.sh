#!/bin/env bash

export SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

function display_help() {
    echo "Usage: $0 [option...]" >&2
    echo
    echo "   -s, --service                 ArgoCD application name"
    echo "   -r, --repository              Gitlab repository"
	echo "   -a, --argo-path               Manifests path in repository"
	echo "   -n, --namespace               Manifests path in repository"
	echo "   -u, --username                Gitlab repository username"
	echo "   -p, --password                Gitlab repository password"
	echo "   -h, --help                    Show help message"
    echo
    # echo some stuff here for the -a or --add-options 
    exit 1
}

function create_application() {
	echo SERVICE: $SERVICE
	echo REPOSITORY: $REPOSITORY
	echo ARGO_PATH: $ARGO_PATH
	echo NAMESPACE: $NAMESPACE
	echo USERNAME: $USERNAME
	echo PASSWORD: $PASSWORD

	envsubst < $SCRIPT_DIR/application.yml | kubectl apply -f -
}

VALID_ARGS=$(getopt -o s:r:a:n:u:p:h --long service:,repository:,argo-path:,namespace:,username:,password:,help -- "$@")

eval set -- "$VALID_ARGS"
while [ : ]; do
	case "$1" in
		-h | --help ) display_help ;;
		-s | --service ) export SERVICE=$2; shift 2 ;;
		-r | --repository ) export REPOSITORY=$2; shift 2 ;;
		-a | --argo-path ) export ARGO_PATH=$2; shift 2 ;;
		-n | --namespace ) export NAMESPACE=$2; shift 2 ;;
		-u | --username ) export USERNAME=$2; shift 2 ;;
		-p | --password ) export PASSWORD=$2; shift 2 ;;
		-- ) shift; break ;;
		* ) break ;;
	esac
done

create_application