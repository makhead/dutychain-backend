#!/bin/bash

# path of file config.json
if [ $# -eq 0 ]
then
    CONFIG_PATH="./config.json"
else
    CONFIG_PATH="$1"
fi


PEER_NUM=$(cat ${CONFIG_PATH} | jq ".peers | length")

# docker-compose-ca-org-template.yaml
echo 'generating compose/docker/docker-compose-ca.yaml'
cat compose/docker/docker-compose-ca-template.yaml > compose/docker/docker-compose-ca.yaml
# docker-compose-couch-org-template.yaml
echo 'generating compose/docker/docker-compose-couch.yaml'
cat compose/docker/docker-compose-couch-template.yaml > compose/docker/docker-compose-couch.yaml

# docker-compose-org-template.yaml
echo 'generating compose/docker/docker-compose-test-net.yaml'
cat compose/docker/docker-compose-test-net-template.yaml > compose/docker/docker-compose-test-net.yaml
for ((i=0;i<$PEER_NUM;i++));
do
    ORG=$(cat ${CONFIG_PATH} | jq ".peers[$i].NAME")
    sed -e "s/\${NAME}/${ORG}/g" \
        compose/docker/docker-compose-test-net-org-template.yaml >> compose/docker/docker-compose-test-net.yaml 
done


# compose/compose-ca-org-template.yaml
echo 'generating compose/compose-ca.yaml'
cat compose/compose-ca-template.yaml > compose/compose-ca.yaml
for ((i=0;i<$PEER_NUM;i++));
do


    ORG=$(cat ${CONFIG_PATH} | jq ".peers[$i].NAME")
    CA_SERVER_PORT=$(cat ${CONFIG_PATH} | jq ".peers[$i].CA_SERVER_PORT") 
    CA_USERNAME=$(cat ${CONFIG_PATH} | jq ".peers[$i].CA_USERNAME" | tr -d '"') 
    CA_PASSWORD=$(cat ${CONFIG_PATH} | jq ".peers[$i].CA_PASSWORD" | tr -d '"') 
    CA_OPERATIONS_PORT=$(($CA_SERVER_PORT + 10000))

    sed -e "s/\${NAME}/${ORG}/g" \
        -e "s/\${CA_SERVER_PORT}/${CA_SERVER_PORT}/g" \
        -e "s/\${CA_USERNAME}/${CA_USERNAME}/g" \
        -e "s/\${CA_PASSWORD}/${CA_PASSWORD}/g" \
        -e "s/\${CA_OPERATIONS_PORT}/${CA_OPERATIONS_PORT}/g" \
        compose/compose-ca-org-template.yaml >> compose/compose-ca.yaml

done

isDeployOrderer=$(cat ${CONFIG_PATH} | jq ".isDeployOrderer")
if $isDeployOrderer;
then
    ORG=$(cat ${CONFIG_PATH} | jq ".orderer.NAME" | tr -d '"')
    CA_SERVER_PORT=$(cat ${CONFIG_PATH} | jq ".orderer.CA_SERVER_PORT") 
    CA_USERNAME=$(cat ${CONFIG_PATH} | jq ".orderer.CA_USERNAME" | tr -d '"') 
    CA_PASSWORD=$(cat ${CONFIG_PATH} | jq ".orderer.CA_PASSWORD" | tr -d '"') 
    CA_OPERATIONS_PORT=$(($CA_SERVER_PORT + 10000))

    sed -e "s/\${NAME}/${ORG}/g" \
        -e "s/\${CA_SERVER_PORT}/${CA_SERVER_PORT}/g" \
        -e "s/\${CA_USERNAME}/${CA_USERNAME}/g" \
        -e "s/\${CA_PASSWORD}/${CA_PASSWORD}/g" \
        -e "s/\${CA_OPERATIONS_PORT}/${CA_OPERATIONS_PORT}/g" \
        compose/compose-ca-orderer-template.yaml >> compose/compose-ca.yaml
fi


# compose/compose-couch-org-template.yaml
echo 'generating compose/compose-couch.yaml'
cat compose/compose-couch-template.yaml > compose/compose-couch.yaml
for ((i=0;i<$PEER_NUM;i++));
do

    ORG=$(cat ${CONFIG_PATH} | jq ".peers[$i].NAME")
    COUCHDB_PORT1=$(cat ${CONFIG_PATH} | jq ".peers[$i].COUCHDB_PORT1") 
    COUCHDB_PORT2=$(cat ${CONFIG_PATH} | jq ".peers[$i].COUCHDB_PORT2") 
    COUCHDB_USERNAME=$(cat ${CONFIG_PATH} | jq ".peers[$i].COUCHDB_USERNAME" | tr -d '"') 
    COUCHDB_PASSWORD=$(cat ${CONFIG_PATH} | jq ".peers[$i].COUCHDB_PASSWORD" | tr -d '"') 

    sed -e "s/\${NAME}/${ORG}/g" \
        -e "s/\${COUCHDB_PORT1}/${COUCHDB_PORT1}/g" \
        -e "s/\${COUCHDB_PORT2}/${COUCHDB_PORT2}/g" \
        -e "s/\${COUCHDB_USERNAME}/${COUCHDB_USERNAME}/g" \
        -e "s/\${COUCHDB_PASSWORD}/${COUCHDB_PASSWORD}/g" \
        compose/compose-couch-org-template.yaml >> compose/compose-couch.yaml

done



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

# compose/compose-test-net-template.yaml
echo 'generating compose/compose-test-net.yaml'
cat compose/compose-test-net-template.yaml > compose/compose-test-net.yaml

isDeployOrderer=$(cat ${CONFIG_PATH} | jq ".isDeployOrderer")
if $isDeployOrderer;
then
    ORG=$(cat ${CONFIG_PATH} | jq ".orderer.NAME" | tr -d '"')
    ORDERER_GENERAL_PORT=$(cat ${CONFIG_PATH} | jq ".orderer.ORDERER_GENERAL_PORT")
    ORDERER_ADMIN_PORT=$(cat ${CONFIG_PATH} | jq ".orderer.ORDERER_ADMIN_PORT")
    ORDERER_OPERATION_PORT=$(cat ${CONFIG_PATH} | jq ".orderer.ORDERER_OPERATION_PORT")
    sed -e "s/\${NAME}/${ORG}/g" \
        -e "s/\${ORDERER_GENERAL_PORT}/${ORDERER_GENERAL_PORT}/g" \
        -e "s/\${ORDERER_ADMIN_PORT}/${ORDERER_ADMIN_PORT}/g" \
        -e "s/\${ORDERER_OPERATION_PORT}/${ORDERER_OPERATION_PORT}/g" \
        compose/compose-test-net-orderer-template.yaml >> compose/compose-test-net.yaml
fi

for ((i=0;i<$PEER_NUM;i++));
do

    ORG=$(cat ${CONFIG_PATH} | jq ".peers[$i].NAME")
    PEER_PORT=$(cat ${CONFIG_PATH} | jq ".peers[$i].PEER_PORT")
    PEER_CHAINCODE_PORT=$(cat ${CONFIG_PATH} | jq ".peers[$i].PEER_CHAINCODE_PORT")
    PEER_OPERATION_PORT=$(cat ${CONFIG_PATH} | jq ".peers[$i].PEER_OPERATION_PORT")

    sed -e "s/\${NAME}/${ORG}/g" \
        -e "s/\${PEER_PORT}/${PEER_PORT}/g" \
        -e "s/\${PEER_CHAINCODE_PORT}/${PEER_CHAINCODE_PORT}/g" \
        -e "s/\${PEER_OPERATION_PORT}/${PEER_OPERATION_PORT}/g" \
        compose/compose-test-net-org-template.yaml >> compose/compose-test-net.yaml


done

cat compose/compose-test-net-cli-template.yaml >> compose/compose-test-net.yaml


