#!/usr/bin/env bash

echo
echo "Starting the environment shutdown"
echo "================================="

echo
echo "Removing containers"
echo "-------------------"
docker rm -fv nginx keycloak1 keycloak2 postgres

echo
echo "Removing network"
echo "----------------"
docker network rm spring-boot-nginx-keycloak-cluster-net

echo
echo "Environment shutdown successfully"
echo "================================="
echo