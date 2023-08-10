#!/bin/bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source ${DIR}/../../scripts/utils.sh

verify_docker_and_memory

check_docker_compose_version
check_bash_version
check_playground_version

nb_connect_services=0

profile_connect_command=""
if [ -z "$ENABLE_CONNECT" ]
then
  log "🛑 connect is disabled"
else
  log "🐺 connect is enabled"
  profile_connect_command="--profile connect"
fi

profile_lenses_command=""
if [ -z "$ENABLE_LENSES" ]
then
  log "🛑 lenses is disabled"
else
  log "💠 lenses is enabled"
  profile_lenses_command="--profile lenses"
fi

ENABLE_DOCKER_COMPOSE_FILE_OVERRIDE=""
DOCKER_COMPOSE_FILE_OVERRIDE=$1
if [ -f "${DOCKER_COMPOSE_FILE_OVERRIDE}" ]
then
  ENABLE_DOCKER_COMPOSE_FILE_OVERRIDE="-f ${DOCKER_COMPOSE_FILE_OVERRIDE}"
  set +e
  nb_connect_services=$(egrep -c "connect[0-9]+:" ${DOCKER_COMPOSE_FILE_OVERRIDE})
  set -e
  check_arm64_support "${DIR}" "${DOCKER_COMPOSE_FILE_OVERRIDE}"
fi
set_profiles

if [ "$1" == "build" ]
then
docker compose -f ../../environment/plaintext/docker-compose.yml -f ../../environment/sasl-scram/docker-compose.yml ${ENABLE_DOCKER_COMPOSE_FILE_OVERRIDE} build
docker compose -f ../../environment/plaintext/docker-compose.yml -f ../../environment/sasl-scram/docker-compose.yml ${ENABLE_DOCKER_COMPOSE_FILE_OVERRIDE} down -v --remove-orphans
docker compose -f ../../environment/plaintext/docker-compose.yml ${ENABLE_DOCKER_COMPOSE_FILE_OVERRIDE} ${profile_control_center_command} ${profile_ksqldb_command} ${profile_grafana_command} ${profile_kcat_command} ${profile_conduktor_command} ${profile_connect_nodes_command} up -d --quiet-pull --build zookeeper broker

# Creating the users
if version_gt ${TAG} "6.0.99"
then
  docker exec broker kafka-configs --bootstrap-server broker:9092 --alter --add-config 'SCRAM-SHA-256=[password=broker],SCRAM-SHA-512=[password=broker]' --entity-type users --entity-name broker
  docker exec broker kafka-configs --bootstrap-server broker:9092 --alter --add-config 'SCRAM-SHA-256=[password=admin-secret],SCRAM-SHA-512=[password=admin-secret]' --entity-type users --entity-name admin
  docker exec broker kafka-configs --bootstrap-server broker:9092 --alter --add-config 'SCRAM-SHA-256=[password=connect-secret],SCRAM-SHA-512=[password=connect-secret]' --entity-type users --entity-name connect
  docker exec broker kafka-configs --bootstrap-server broker:9092 --alter --add-config 'SCRAM-SHA-256=[password=schema1-secret],SCRAM-SHA-512=[password=schema1-secret]' --entity-type users --entity-name schema-client1
  docker exec broker kafka-configs --bootstrap-server broker:9092 --alter --add-config 'SCRAM-SHA-256=[password=ksqldb-secret],SCRAM-SHA-512=[password=ksqldb-secret]' --entity-type users --entity-name ksqldb
  docker exec broker kafka-configs --bootstrap-server broker:9092 --alter --add-config 'SCRAM-SHA-256=[password=client-secret],SCRAM-SHA-512=[password=client-secret]' --entity-type users --entity-name client
  docker exec broker kafka-configs --bootstrap-server broker:9092 --alter --add-config 'SCRAM-SHA-256=[password=client1-secret],SCRAM-SHA-512=[password=client1-secret]' --entity-type users --entity-name client1
  docker exec broker kafka-configs --bootstrap-server broker:9092 --alter --add-config 'SCRAM-SHA-256=[password=afs-secret],SCRAM-SHA-512=[password=afs-secret]' --entity-type users --entity-name afs
  docker exec broker kafka-configs --bootstrap-server broker:9092 --alter --add-config 'SCRAM-SHA-256=[password=lab-secret],SCRAM-SHA-512=[password=lab-secret]' --entity-type users --entity-name lab
  docker exec broker kafka-configs --bootstrap-server broker:9092 --alter --add-config 'SCRAM-SHA-256=[password=tenant1-secret],SCRAM-SHA-512=[password=tenant1-secret]' --entity-type users --entity-name tenant1
  docker exec broker kafka-configs --bootstrap-server broker:9092 --alter --add-config 'SCRAM-SHA-256=[password=tenant2-secret],SCRAM-SHA-512=[password=tenant2-secret]' --entity-type users --entity-name tenant2
else
  docker exec broker kafka-configs --zookeeper zookeeper:2181 --alter --add-config 'SCRAM-SHA-256=[password=broker],SCRAM-SHA-512=[password=broker]' --entity-type users --entity-name broker
  docker exec broker kafka-configs --zookeeper zookeeper:2181 --alter --add-config 'SCRAM-SHA-256=[password=admin-secret],SCRAM-SHA-512=[password=admin-secret]' --entity-type users --entity-name admin
  docker exec broker kafka-configs --zookeeper zookeeper:2181 --alter --add-config 'SCRAM-SHA-256=[password=connect-secret],SCRAM-SHA-512=[password=connect-secret]' --entity-type users --entity-name connect
  docker exec broker kafka-configs --zookeeper zookeeper:2181 --alter --add-config 'SCRAM-SHA-256=[password=schema1-secret],SCRAM-SHA-512=[password=schema1-secret]' --entity-type users --entity-name schema-client1
  docker exec broker kafka-configs --zookeeper zookeeper:2181 --alter --add-config 'SCRAM-SHA-256=[password=ksqldb-secret],SCRAM-SHA-512=[password=ksqldb-secret]' --entity-type users --entity-name ksqldb
  docker exec broker kafka-configs --zookeeper zookeeper:2181 --alter --add-config 'SCRAM-SHA-256=[password=client-secret],SCRAM-SHA-512=[password=client-secret]' --entity-type users --entity-name client
  docker exec broker kafka-configs --zookeeper zookeeper:2181 --alter --add-config 'SCRAM-SHA-256=[password=client1-secret],SCRAM-SHA-512=[password=client1-secret]' --entity-type users --entity-name client1
  docker exec broker kafka-configs --zookeeper zookeeper:2181 --alter --add-config 'SCRAM-SHA-256=[password=afs-secret],SCRAM-SHA-512=[password=afs-secret]' --entity-type users --entity-name afs
  docker exec broker kafka-configs --zookeeper zookeeper:2181 --alter --add-config 'SCRAM-SHA-256=[password=lab-secret],SCRAM-SHA-512=[password=lab-secret]' --entity-type users --entity-name lab
  docker exec broker kafka-configs --zookeeper zookeeper:2181 --alter --add-config 'SCRAM-SHA-256=[password=tenant1-secret],SCRAM-SHA-512=[password=tenant1-secret]' --entity-type users --entity-name tenant1
  docker exec broker kafka-configs --zookeeper zookeeper:2181 --alter --add-config 'SCRAM-SHA-256=[password=tenant2-secret],SCRAM-SHA-512=[password=tenant2-secret]' --entity-type users --entity-name tenant2
fi
fi

docker compose -f ../../environment/plaintext/docker-compose.yml -f ../../environment/sasl-scram/docker-compose.yml ${ENABLE_DOCKER_COMPOSE_FILE_OVERRIDE} ${profile_control_center_command} ${profile_ksqldb_command} ${profile_grafana_command} ${profile_kcat_command} ${profile_conduktor_command} ${profile_kafka_nodes_command} ${profile_connect_nodes_command} ${profile_connect_command} ${profile_lenses_command} up -d
log "📝 To see the actual properties file, use cli command playground container get-properties -c <container>"
command="source ${DIR}/../../scripts/utils.sh && docker compose -f ${DIR}/../../environment/plaintext/docker-compose.yml -f ${DIR}/../../environment/sasl-scram/docker-compose.yml ${ENABLE_DOCKER_COMPOSE_FILE_OVERRIDE} ${profile_control_center_command} ${profile_ksqldb_command} ${profile_grafana_command} ${profile_kcat_command} ${profile_conduktor_command} ${profile_kafka_nodes_command} ${profile_connect_nodes_command} ${profile_connect_command} ${profile_lenses_command} up -d"
playground state set run.docker_command "$command"
playground state set run.environment "sasl-scram"
log "✨ If you modify a docker-compose file and want to re-create the container(s), run cli command playground container recreate"




wait_container_ready

display_jmx_info