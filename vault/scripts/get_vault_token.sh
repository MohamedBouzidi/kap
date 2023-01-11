#!/bin/env bash


ROOT_TOKEN=$(kubectl get secret/vault-root-token -o jsonpath='{.data.token}' | base64 -d)
echo VAULT TOKEN: $ROOT_TOKEN