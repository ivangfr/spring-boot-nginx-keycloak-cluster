#!/usr/bin/env bash

POSTGRES_VERSION="16.1"
KEYCLOAK_VERSION="24.0.2"
NGINX_VERSION="1.25.4"

source scripts/my-functions.sh

echo
echo "Starting environment"
echo "===================="

echo
echo "Creating network"
echo "----------------"
docker network create spring-boot-nginx-keycloak-cluster-net

echo
echo "Starting postgres"
echo "-----------------"

docker run -d \
    --name postgres \
    -p 5432:5432 \
    -e POSTGRES_DB=keycloak \
    -e POSTGRES_USER=keycloak \
    -e POSTGRES_PASSWORD=password \
    --network=spring-boot-nginx-keycloak-cluster-net \
    postgres:${POSTGRES_VERSION}

echo
echo "Starting keycloak 1"
echo "-------------------"

docker run -d \
    --name keycloak1 \
    -e KEYCLOAK_ADMIN=admin \
    -e KEYCLOAK_ADMIN_PASSWORD=admin \
    -e KC_DB=postgres \
    -e KC_DB_URL_HOST=postgres \
    -e KC_DB_URL_DATABASE=keycloak \
    -e KC_DB_USERNAME=keycloak \
    -e KC_DB_PASSWORD=password \
    -e KC_CACHE=ispn \
    -e KC_HOSTNAME=nginx.keycloak.cluster \
    -e KC_LOG_LEVEL=INFO,org.infinispan:DEBUG,org.keycloak.events:DEBUG \
    --network=spring-boot-nginx-keycloak-cluster-net \
    quay.io/keycloak/keycloak:${KEYCLOAK_VERSION} start-dev

echo
echo "Starting keycloak 2"
echo "-------------------"

docker run -d \
    --name keycloak2 \
    -e KEYCLOAK_ADMIN=admin \
    -e KEYCLOAK_ADMIN_PASSWORD=admin \
    -e KC_DB=postgres \
    -e KC_DB_URL_HOST=postgres \
    -e KC_DB_URL_DATABASE=keycloak \
    -e KC_DB_USERNAME=keycloak \
    -e KC_DB_PASSWORD=password \
    -e KC_CACHE=ispn \
    -e KC_HOSTNAME=nginx.keycloak.cluster \
    -e KC_LOG_LEVEL=INFO,org.infinispan:DEBUG,org.keycloak.events:DEBUG \
    --network=spring-boot-nginx-keycloak-cluster-net \
    quay.io/keycloak/keycloak:${KEYCLOAK_VERSION} start-dev

echo
wait_for_container_log "postgres" "database system is ready"

echo
wait_for_container_log "keycloak1" "started in"

echo
wait_for_container_log "keycloak2" "started in"

docker run -d \
  --name nginx.keycloak.cluster \
  -p 80:80 \
  -v $PWD/nginx/nginx.conf:/etc/nginx/nginx.conf:ro \
  --network spring-boot-nginx-keycloak-cluster-net \
  nginx:${NGINX_VERSION}

echo
wait_for_container_log "nginx.keycloak.cluster" "ready for start up"

echo
echo "Environment Up and Running"
echo "=========================="
echo