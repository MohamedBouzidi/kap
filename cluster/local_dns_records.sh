#!/bin/env bash

cat <<EOF >> /etc/hosts
${KIND_IP} gitlab.dev.local
${KIND_IP} argocd.dev.local
${KIND_IP} sonarqube.dev.local
${KIND_IP} keycloak.dev.local
EOF