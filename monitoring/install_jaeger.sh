#!/bin/env bash

kubectl create -k ./monitoring/elasticsearch
kubectl wait -n elastic-system --for=condition=ready pod --selector=app.kubernetes.io/name=elastic-operator --timeout=600s

kubectl create -k ./monitoring/jaeger-operator
kubectl wait -n jaeger --for=condition=ready pod --selector=app.kubernetes.io/name=jaeger-operator --timeout=600s

bash ./monitoring/jaeger/scripts/create_secrets.sh

kubectl create -f ./monitoring/jaeger/traefik.yml
kubectl wait -n traefik --for=condition=ready pod --selector=app=jaeger-traefik --timeout=240s
