#!/usr/bin/env bash

if [[ -z $(docker ps --filter "name=keycloak1" -q) ]]; then
  echo "[WARNING] You must initialize the environment (./init-environment.sh) before initializing keycloak"
  exit 1
fi

KEYCLOAK_HOST_PORT="nginx:8080"
echo
echo "KEYCLOAK_HOST_PORT: $KEYCLOAK_HOST_PORT"

echo
echo "Getting admin access token"
echo "--------------------------"

ADMIN_TOKEN=$(curl -s -X POST "http://$KEYCLOAK_HOST_PORT/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin" \
  -d 'password=admin' \
  -d 'grant_type=password' \
  -d 'client_id=admin-cli' | jq -r '.access_token')

echo "ADMIN_TOKEN=$ADMIN_TOKEN"
echo

echo "Creating company-services realm"
echo "-------------------------------"

curl -i -X POST "http://$KEYCLOAK_HOST_PORT/admin/realms" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"realm": "company-services", "enabled": true}'

echo "Getting required action Verify Profile"
echo "--------------------------------------"

VERIFY_PROFILE_REQUIRED_ACTION=$(curl -s "http://$KEYCLOAK_HOST_PORT/admin/realms/company-services/authentication/required-actions/VERIFY_PROFILE" \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq)

echo $VERIFY_PROFILE_REQUIRED_ACTION
echo

echo "Disabling required action Verify Profile"
echo "----------------------------------------"

NEW_VERIFY_PROFILE_REQUIRED_ACTION=$(echo "$VERIFY_PROFILE_REQUIRED_ACTION" | jq '.enabled = false')

echo $NEW_VERIFY_PROFILE_REQUIRED_ACTION
echo

curl -i -X PUT "http://$KEYCLOAK_HOST_PORT/admin/realms/company-services/authentication/required-actions/VERIFY_PROFILE" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$NEW_VERIFY_PROFILE_REQUIRED_ACTION"

echo "Creating simple-service client"
echo "------------------------------"

CLIENT_ID=$(curl -si -X POST "http://$KEYCLOAK_HOST_PORT/admin/realms/company-services/clients" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"clientId": "simple-service", "directAccessGrantsEnabled": true, "redirectUris": ["http://localhost:9080/*"]}' \
  | grep -oE '[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}')

echo "CLIENT_ID=$CLIENT_ID"
echo

echo "Getting client secret"
echo "====================="

SIMPLE_SERVICE_CLIENT_SECRET=$(curl -s -X POST "http://$KEYCLOAK_HOST_PORT/admin/realms/company-services/clients/$CLIENT_ID/client-secret" \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r '.value')

echo "SIMPLE_SERVICE_CLIENT_SECRET=$SIMPLE_SERVICE_CLIENT_SECRET"
echo

echo "Creating the client role APP_USER for the simple-service client"
echo "---------------------------------------------------------------"

curl -i -X POST "http://$KEYCLOAK_HOST_PORT/admin/realms/company-services/clients/$CLIENT_ID/roles" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "APP_USER"}'

APP_USER_CLIENT_ROLE_ID=$(curl -s http://localhost:8080/admin/realms/company-services/clients/$CLIENT_ID/roles/APP_USER \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r '.id')

echo "APP_USER_CLIENT_ROLE_ID=$APP_USER_CLIENT_ROLE_ID"
echo

echo "Creating USERS group"
echo "--------------------"
USERS_GROUP_ID=$(curl -si -X POST "http://$KEYCLOAK_HOST_PORT/admin/realms/company-services/groups" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "USERS"}' \
  | grep -oE '[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}')

echo "USERS_GROUP_ID=$USERS_GROUP_ID"
echo

echo "Assigning APP_USER client role to USERS group"
echo "---------------------------------------------"

curl -i -X POST "http://$KEYCLOAK_HOST_PORT/admin/realms/company-services/groups/$USERS_GROUP_ID/role-mappings/clients/$CLIENT_ID" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "[{\"id\": \"$APP_USER_CLIENT_ROLE_ID\", \"name\": \"APP_USER\"}]"

echo "Creating 'user-test' user"
echo "-------------------------"

USER_ID=$(curl -si -X POST "http://$KEYCLOAK_HOST_PORT/admin/realms/company-services/users" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"username": "user-test", "enabled": true, "credentials": [{"type": "password", "value": "123", "temporary": false}]}' \
  | grep -oE '[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}')

echo "USER_ID=$USER_ID"
echo

echo "Assigning USERS group to user"
echo "-----------------------------"

curl -i -X PUT "http://$KEYCLOAK_HOST_PORT/admin/realms/company-services/users/$USER_ID/groups/$USERS_GROUP_ID" \
  -H "Authorization: Bearer $ADMIN_TOKEN"

echo "Getting user-test access token"
echo "------------------------------"

curl -s -X POST "http://$KEYCLOAK_HOST_PORT/realms/company-services/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=user-test" \
  -d "password=123" \
  -d "grant_type=password" \
  -d "client_secret=$SIMPLE_SERVICE_CLIENT_SECRET" \
  -d "client_id=simple-service" | jq -r .access_token

echo
echo "============================"
echo "SIMPLE_SERVICE_CLIENT_SECRET=$SIMPLE_SERVICE_CLIENT_SECRET"
echo "============================"