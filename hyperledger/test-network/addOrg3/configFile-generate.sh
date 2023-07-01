#!/bin/bash

CONFIG_PATH="$1"

ORG=$(cat ${CONFIG_PATH} | jq '.NAME')
CA_SERVER_PORT=$(cat ${CONFIG_PATH} | jq '.CA_SERVER_PORT') 
CA_USERNAME=$(cat ${CONFIG_PATH} | jq '.CA_USERNAME' | tr -d '"') 
CA_PASSWORD=$(cat ${CONFIG_PATH} | jq '.CA_PASSWORD' | tr -d '"') 

COUCHDB_PORT1=$(cat ${CONFIG_PATH} | jq '.COUCHDB_PORT1') 
COUCHDB_PORT2=$(cat ${CONFIG_PATH} | jq '.COUCHDB_PORT2') 
COUCHDB_USERNAME=$(cat ${CONFIG_PATH} | jq '.COUCHDB_USERNAME' | tr -d '"') 
COUCHDB_PASSWORD=$(cat ${CONFIG_PATH} | jq '.COUCHDB_PASSWORD' | tr -d '"') 

PEER_PORT=$(cat ${CONFIG_PATH} | jq '.PEER_PORT') 
PEER_CHAINCODE_PORT=$(cat ${CONFIG_PATH} | jq '.PEER_CHAINCODE_PORT') 

# docker-compose-ca-org-template.yaml
cat compose/docker/docker-compose-ca-org-template.yaml > compose/docker/docker-compose-ca-org${ORG}.yaml
# docker-compose-couch-org-template.yaml
cat compose/docker/docker-compose-couch-org-template.yaml > compose/docker/docker-compose-couch-org${ORG}.yaml
# docker-compose-org-template.yaml
sed -e "s/\${NAME}/${ORG}/g" \
    compose/docker/docker-compose-org-template.yaml > compose/docker/docker-compose-org${ORG}.yaml 

# compose/compose-ca-org-template.yaml
sed -e "s/\${NAME}/${ORG}/g" \
    -e "s/\${CA_SERVER_PORT}/${CA_SERVER_PORT}/g" \
    -e "s/\${CA_USERNAME}/${CA_USERNAME}/g" \
    -e "s/\${CA_PASSWORD}/${CA_PASSWORD}/g" \
    compose/compose-ca-org-template.yaml > compose/compose-ca-org${ORG}.yaml


# compose/compose-couch-org-template.yaml
sed -e "s/\${NAME}/${ORG}/g" \
    -e "s/\${COUCHDB_PORT1}/${COUCHDB_PORT1}/g" \
    -e "s/\${COUCHDB_PORT2}/${COUCHDB_PORT2}/g" \
    -e "s/\${COUCHDB_USERNAME}/${COUCHDB_USERNAME}/g" \
    -e "s/\${COUCHDB_PASSWORD}/${COUCHDB_PASSWORD}/g" \
    compose/compose-couch-org-template.yaml > compose/compose-couch-org${ORG}.yaml

# compose/compose-org-template.yaml
sed -e "s/\${NAME}/${ORG}/g" \
    -e "s/\${PEER_PORT}/${PEER_PORT}/g" \
    -e "s/\${PEER_CHAINCODE_PORT}/${PEER_CHAINCODE_PORT}/g" \
    compose/compose-org-template.yaml > compose/compose-org${ORG}.yaml

# configtx-template.yaml
sed -e "s/\${NAME}/${ORG}/g" \
    configtx-template.yaml > configtx.yaml