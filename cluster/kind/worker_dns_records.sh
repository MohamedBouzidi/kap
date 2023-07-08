#!/bin/env bash

CONTROL_PLANE_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' kind-control-plane)
WORKER_CONTAINERS=$(docker ps --filter "label=io.x-k8s.kind.role=worker" --filter "label=io.x-k8s.kind.cluster=kind" --format "{{.Names}}" | tr '\n' ' ')

for worker in $WORKER_CONTAINERS
do
    docker exec $worker bash -c "echo \"$CONTROL_PLANE_IP  gitlab.dev.local\" >> /etc/hosts"
    docker exec $worker bash -c "echo \"$CONTROL_PLANE_IP  registry.dev.local\" >> /etc/hosts"
done