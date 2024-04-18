# spring-boot-nginx-keycloak-cluster

## Start Environment
```
./init-environment.sh
```

## Initialize Keycloak
```
./init-keycloak.sh
```

## Start simple-service
```
./mvnw clean spring-boot:run --projects simple-service
```

## Build Docker Image
```
./mvnw clean compile jib:dockerBuild --projects simple-service
```

## Run Docker Image
```
docker run --rm --name simple-service \
  -p 9080:9080 \
  --network=spring-boot-nginx-keycloak-cluster-net \
  ivanfranchin/simple-service:1.0.0
```

## Create Environment Variable
```
SIMPLE_SERVICE_CLIENT_SECRET=...
```

## Get Access Token
```
USER_TEST_ACCESS_TOKEN="$(curl -s -X POST \
  "http://nginx:8080/realms/company-services/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=user-test" \
  -d "password=123" \
  -d "grant_type=password" \
  -d "client_secret=$SIMPLE_SERVICE_CLIENT_SECRET" \
  -d "client_id=simple-service" | jq -r .access_token)"
echo $USER_TEST_ACCESS_TOKEN
```

## API Requests
```
curl -i localhost:9080/public
curl -i localhost:9080/secured
curl -i http://localhost:9080/secured -H "Authorization: Bearer $USER_TEST_ACCESS_TOKEN"
```