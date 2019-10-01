#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

${DIR}/../scripts/reset-cluster.sh

echo "Sending messages to topic http-messages"
seq 10 | docker container exec -i broker kafka-console-producer --broker-list broker:9092 --topic http-messages

echo "-------------------------------------"
echo "Running SSL Authentication Example"
echo "-------------------------------------"

echo "Creating HttpSinkSSL connector"
docker-compose exec connect \
     curl -X POST \
     -H "Content-Type: application/json" \
     --data '{
          "name": "HttpSinkSSL",
          "config": {
               "topics": "http-messages",
               "tasks.max": "1",
               "connector.class": "io.confluent.connect.http.HttpSinkConnector",
               "key.converter": "org.apache.kafka.connect.storage.StringConverter",
               "value.converter": "org.apache.kafka.connect.storage.StringConverter",
               "confluent.topic.bootstrap.servers": "broker:9092",
               "confluent.topic.replication.factor": "1",
               "http.api.url": "https://http-service-ssl-auth:8443/api/messages",
               "auth.type": "BASIC",
               "connection.user": "admin",
               "connection.password": "password",
               "ssl.enabled": "true",
               "https.ssl.truststore.location": "/etc/kafka/secrets/localhost-keystore.jks",
               "https.ssl.truststore.type": "JKS",
               "https.ssl.truststore.password": "confluent",
               "https.ssl.keystore.location": "/etc/kafka/secrets/localhost-keystore.jks",
               "https.ssl.keystore.type": "JKS",
               "https.ssl.keystore.password": "confluent",
               "https.ssl.key.password": "confluent",
               "https.ssl.protocol": "TLSv1.2"
          }}' \
     http://localhost:8083/connectors | jq .


sleep 10

echo "Confirm that the data was sent to the HTTP endpoint."
curl -k --cacert ./security/myCertificate.crt -X GET https://admin:password@localhost:8443/api/messages | jq .


 