#!/bin/env bash


function display_help() {
    echo "Usage: $0 [subcommand]" >&2
    echo
    echo "  add_namespace       Add Namespace for Treafik to watch"
    echo "  remove_namespace    Remove Namespace from Traefik watchlist"
    exit 1
}

function add_namespace() {
    local NAMESPACE=$1

    kubectl get configmap/traefik-config -n traefik -o yaml | sed -r "s/(\s*)namespaces:/\1namespaces:\n\1  - $NAMESPACE/" | kubectl apply -f-
    kubectl rollout restart deployment/traefik-ingress-controller -n traefik
}

function remove_namespace() {
    local NAMESPACE=$1

    kubectl get configmap/traefik-config -n traefik -o yaml | sed -r "/(\s*)- $NAMESPACE/d" | kubectl apply -f-
    kubectl rollout restart deployment/traefik-ingress-controller -n traefik
}

############################################

[ "$#" -lt 1 ] && display_help

SUBCOMMAND=$1
shift

case "$SUBCOMMAND" in

    "add_namespace" )
        if [ "$#" -lt 2 ]; then
            echo "Usage: bash ./traefik.sh add_namespace [option...]" >&2
            echo
            echo "   -n, --namespace        Namespace to be watched"
            echo "   -h, --help             Show help message"
            exit 1
        fi
        VALID_ARGS=$(getopt -o n:h --long namespace:,help -- "$@")
        eval set -- "$VALID_ARGS"
        while [ : ]; do
            case "$1" in
                -h | --help      )      display_help ;;
                -n | --namespace )      NAMESPACE="$2"; shift 2 ;;
                -- ) shift; break ;;
                * ) break ;;
            esac
        done
        add_namespace $NAMESPACE
        ;;

    "remove_namespace" )
        if [ "$#" -lt 2 ]; then
            echo "Usage: bash ./traefik.sh remove_namespace [option...]" >&2
            echo
            echo "   -n, --namespace        Namespace to be watched"
            echo "   -h, --help             Show help message"
            exit 1
        fi
        VALID_ARGS=$(getopt -o n:h --long namespace:,help -- "$@")
        eval set -- "$VALID_ARGS"
        while [ : ]; do
            case "$1" in
                -h | --help      )      display_help ;;
                -n | --namespace )      NAMESPACE="$2"; shift 2 ;;
                -- ) shift; break ;;
                * ) break ;;
            esac
        done
        remove_namespace $NAMESPACE
        ;;
esac