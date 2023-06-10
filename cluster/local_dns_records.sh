#!/bin/env bash

DOCKER_IP=$(dig +short host.docker.internal)

cat <<EOF >> /etc/hosts
${DOCKER_IP} gitlab.dev.local
${DOCKER_IP} argocd.dev.local
${DOCKER_IP} sonarqube.dev.local
EOF