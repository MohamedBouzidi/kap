#!/bin/env bash

ES_USERNAME="elastic"
ES_PASSWORD=$(kubectl get secret/kap-elastic-es-elastic-user -n elastic-system -o jsonpath='{.data.elastic}' | base64 -d)

kubectl delete secret/jaeger-es-secret -n jaeger
kubectl create secret generic jaeger-es-secret --from-literal=ES_PASSWORD=$ES_PASSWORD --from-literal=ES_USERNAME=$ES_USERNAME -n jaeger

ES_CA_FILE=$(mktemp)
ES_TLS_FILE=$(mktemp)

kubectl get secret/kap-elastic-es-http-certs-public -o jsonpath='{.data.ca\.crt}' -n elastic-system | base64 -d > $ES_CA_FILE
kubectl get secret/kap-elastic-es-http-certs-public -o jsonpath='{.data.tls\.crt}' -n elastic-system | base64 -d > $ES_TLS_FILE

kubectl delete secret/jaeger-es-http-certs-public -n jaeger
kubectl create secret generic jaeger-es-http-certs-public --type=Opaque --from-file=ca.crt=$ES_CA_FILE --from-file=tls.crt=$ES_TLS_FILE -n jaeger

rm $ES_CA_FILE
rm $ES_TLS_FILE