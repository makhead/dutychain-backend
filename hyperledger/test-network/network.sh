#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

# *****************************************************************************
# -------------------------------Referencce------------------------------------
# This script is the demo script of Hyperledger Fabric network and we do some
# modifications on the script so that it suits better in our project.

# Reference: https://hyperledger-fabric.readthedocs.io/en/release-2.5/
# *****************************************************************************

# This script brings up a Hyperledger Fabric network for testing smart contracts
# and applications. The test network consists of two organizations with one
# peer each, and a single node Raft ordering service. Users can also use this
# script to create a channel deploy a chaincode on the channel



ROOTDIR=$(cd "$(dirname "$0")" && pwd)
export PATH=${ROOTDIR}/../bin:${PWD}/../bin:$PATH
export FABRIC_CFG_PATH=${PWD}/configtx
export VERBOSE=false

# push to the required directory & set a trap to go back if needed
pushd ${ROOTDIR} > /dev/null
trap "popd > /dev/null" EXIT

. scripts/utils.sh

: ${CONTAINER_CLI:="docker"}
: ${CONTAINER_CLI_COMPOSE:="${CONTAINER_CLI}-compose"}
infoln "Using ${CONTAINER_CLI} and ${CONTAINER_CLI_COMPOSE}"

# Obtain CONTAINER_IDS and remove them
# This function is called when you bring a network down
# *****************************************************************************
# -------------------------------Referencce------------------------------------
# This function is from the sample of Fabric network

# Reference: https://hyperledger-fabric.readthedocs.io/en/release-2.5/
# *****************************************************************************
function clearContainers() {
  infoln "Removing remaining containers"
  ${CONTAINER_CLI} rm -f $(${CONTAINER_CLI} ps -aq --filter label=service=hyperledger-fabric) 2>/dev/null || true
  ${CONTAINER_CLI} rm -f $(${CONTAINER_CLI} ps -aq --filter name='dev-peer*') 2>/dev/null || true
}

# Delete any images that were generated as a part of this setup
# specifically the following images are often left behind:
# This function is called when you bring the network down
# *****************************************************************************
# -------------------------------Referencce------------------------------------
# This function is from the sample of Fabric network

# Reference: https://hyperledger-fabric.readthedocs.io/en/release-2.5/
# *****************************************************************************
function removeUnwantedImages() {
  infoln "Removing generated chaincode docker images"
  ${CONTAINER_CLI} image rm -f $(${CONTAINER_CLI} images -aq --filter reference='dev-peer*') 2>/dev/null || true
}

# Versions of fabric known not to work with the test network
NONWORKING_VERSIONS="^1\.0\. ^1\.1\. ^1\.2\. ^1\.3\. ^1\.4\."

# Do some basic sanity checking to make sure that the appropriate versions of fabric
# binaries/images are available. In the future, additional checking for the presence
# of go or other items could be added.
# *****************************************************************************
# -------------------------------Referencce------------------------------------
# This function is from the sample of Fabric network

# Reference: https://hyperledger-fabric.readthedocs.io/en/release-2.5/
# *****************************************************************************
function checkPrereqs() {
  ## Check if your have cloned the peer binaries and configuration files.
  peer version > /dev/null 2>&1

  if [[ $? -ne 0 || ! -d "../config" ]]; then
    errorln "Peer binary and configuration files not found.."
    errorln
    errorln "Follow the instructions in the Fabric docs to install the Fabric Binaries:"
    errorln "https://hyperledger-fabric.readthedocs.io/en/latest/install.html"
    exit 1
  fi
  # use the fabric tools container to see if the samples and binaries match your
  # docker images
  LOCAL_VERSION=$(peer version | sed -ne 's/^ Version: //p')
  DOCKER_IMAGE_VERSION=$(${CONTAINER_CLI} run --rm hyperledger/fabric-tools:latest peer version | sed -ne 's/^ Version: //p')

  infoln "LOCAL_VERSION=$LOCAL_VERSION"
  infoln "DOCKER_IMAGE_VERSION=$DOCKER_IMAGE_VERSION"

  if [ "$LOCAL_VERSION" != "$DOCKER_IMAGE_VERSION" ]; then
    warnln "Local fabric binaries and docker images are out of  sync. This may cause problems."
  fi

  for UNSUPPORTED_VERSION in $NONWORKING_VERSIONS; do
    infoln "$LOCAL_VERSION" | grep -q $UNSUPPORTED_VERSION
    if [ $? -eq 0 ]; then
      fatalln "Local Fabric binary version of $LOCAL_VERSION does not match the versions supported by the test network."
    fi

    infoln "$DOCKER_IMAGE_VERSION" | grep -q $UNSUPPORTED_VERSION
    if [ $? -eq 0 ]; then
      fatalln "Fabric Docker image version of $DOCKER_IMAGE_VERSION does not match the versions supported by the test network."
    fi
  done

  ## Check for fabric-ca
  fabric-ca-client version > /dev/null 2>&1
  if [[ $? -ne 0 ]]; then
    errorln "fabric-ca-client binary not found.."
    errorln
    errorln "Follow the instructions in the Fabric docs to install the Fabric Binaries:"
    errorln "https://hyperledger-fabric.readthedocs.io/en/latest/install.html"
    exit 1
  fi
  CA_LOCAL_VERSION=$(fabric-ca-client version | sed -ne 's/ Version: //p')
  CA_DOCKER_IMAGE_VERSION=$(${CONTAINER_CLI} run --rm hyperledger/fabric-ca:latest fabric-ca-client version | sed -ne 's/ Version: //p' | head -1)
  infoln "CA_LOCAL_VERSION=$CA_LOCAL_VERSION"
  infoln "CA_DOCKER_IMAGE_VERSION=$CA_DOCKER_IMAGE_VERSION"
  if [ "$CA_LOCAL_VERSION" != "$CA_DOCKER_IMAGE_VERSION" ]; then
    warnln "Local fabric-ca binaries and docker images are out of sync. This may cause problems."
  fi
  
}


# Create Organization using CAs
function createOrgs() {
  if [ -d "organizations/peerOrganizations" ]; then
    rm -Rf organizations/peerOrganizations && rm -Rf organizations/ordererOrganizations
  fi

  infoln "Generating certificates using Fabric CA"
  ${CONTAINER_CLI_COMPOSE} -f compose/$COMPOSE_FILE_CA -f compose/$CONTAINER_CLI/${CONTAINER_CLI}-$COMPOSE_FILE_CA up -d 2>&1

  . organizations/fabric-ca/registerEnroll.sh

  # while :
  # do
  #   if [ ! -f "organizations/fabric-ca/org1/tls-cert.pem" ]; then
  #     sleep 1
  #   else
  #     break
  #   fi
  # done
  sleep 10
     
    
  for ((i=0;i<$PEER_NUM;i++));
  do
    ORG=$(cat ${CONFIG_PATH} | jq ".peers[$i].NAME" | tr -d '"')
    DOMAIN=$(cat ${CONFIG_PATH} | jq ".peers[$i].DOMAIN" | tr -d '"')
    IP_ADDR=$(cat ${CONFIG_PATH} | jq ".peers[$i].IP_ADDR" | tr -d '"')
    CA_SERVER_PORT=$(cat ${CONFIG_PATH} | jq ".peers[$i].CA_SERVER_PORT") 
    CA_USERNAME=$(cat ${CONFIG_PATH} | jq ".peers[$i].CA_USERNAME" | tr -d '"') 
    CA_PASSWORD=$(cat ${CONFIG_PATH} | jq ".peers[$i].CA_PASSWORD" | tr -d '"') 
    CA_PEER_USERNAME=$(cat ${CONFIG_PATH} | jq ".peers[$i].CA_PEER_USERNAME" | tr -d '"') 
    CA_PEER_PASSWORD=$(cat ${CONFIG_PATH} | jq ".peers[$i].CA_PEER_PASSWORD" | tr -d '"') 
    CA_USER_USERNAME=$(cat ${CONFIG_PATH} | jq ".peers[$i].CA_USER_USERNAME" | tr -d '"') 
    CA_USER_PASSWORD=$(cat ${CONFIG_PATH} | jq ".peers[$i].CA_USER_PASSWORD" | tr -d '"') 
    CA_ADMIN_USERNAME=$(cat ${CONFIG_PATH} | jq ".peers[$i].CA_ADMIN_USERNAME" | tr -d '"') 
    CA_ADMIN_PASSWORD=$(cat ${CONFIG_PATH} | jq ".peers[$i].CA_ADMIN_PASSWORD" | tr -d '"') 
    
    infoln "Creating Org${ORG} Identities"
    createOrg
  done
    


  isDeployOrderer=$(cat ${CONFIG_PATH} | jq ".isDeployOrderer")
  if $isDeployOrderer;
  then
    ORG=$(cat ${CONFIG_PATH} | jq ".orderer.NAME" | tr -d '"')
    CA_SERVER_PORT=$(cat ${CONFIG_PATH} | jq ".orderer.CA_SERVER_PORT") 
    CA_USERNAME=$(cat ${CONFIG_PATH} | jq ".orderer.CA_USERNAME" | tr -d '"') 
    CA_PASSWORD=$(cat ${CONFIG_PATH} | jq ".orderer.CA_PASSWORD" | tr -d '"') 
    CA_ORDERER_USERNAME=$(cat ${CONFIG_PATH} | jq ".orderer.CA_ORDERER_USERNAME" | tr -d '"') 
    CA_ORDERER_PASSWORD=$(cat ${CONFIG_PATH} | jq ".orderer.CA_ORDERER_PASSWORD" | tr -d '"') 
    CA_ADMIN_USERNAME=$(cat ${CONFIG_PATH} | jq ".orderer.CA_ADMIN_USERNAME" | tr -d '"') 
    CA_ADMIN_PASSWORD=$(cat ${CONFIG_PATH} | jq ".orderer.CA_ADMIN_PASSWORD" | tr -d '"') 
    infoln "Creating Orderer ${ORG} Identities"
    createOrderer
  fi
  



  for ((i=0;i<$PEER_NUM;i++));
  do
    ORG=$(cat ${CONFIG_PATH} | jq ".peers[$i].NAME" | tr -d '"')
    DOMAIN=$(cat ${CONFIG_PATH} | jq ".peers[$i].DOMAIN" | tr -d '"')
    IP_ADDR=$(cat ${CONFIG_PATH} | jq ".peers[$i].IP_ADDR" | tr -d '"')
    PEER_PORT=$(cat ${CONFIG_PATH} | jq ".peers[$i].PEER_PORT")
    CA_SERVER_PORT=$(cat ${CONFIG_PATH} | jq ".peers[$i].CA_SERVER_PORT") 
    
    infoln "Generating CCP files for ${ORG}"
    ./organizations/ccp-generate.sh $ORG $DOMAIN $PEER_PORT $CA_SERVER_PORT $IP_ADDR
  done
  
}


# Bring up the peer and orderer nodes using docker compose.
# *****************************************************************************
# -------------------------------Referencce------------------------------------
# This function is from the sample of Fabric network. And I have done some 
# modification

# Reference: https://hyperledger-fabric.readthedocs.io/en/release-2.5/
# *****************************************************************************
function networkUp() {
  checkPrereqs

  # generate artifacts if they don't exist
  if [ ! -d "organizations/peerOrganizations" ]; then
    createOrgs
  fi


  COMPOSE_FILES="-f compose/${COMPOSE_FILE_BASE} -f compose/${CONTAINER_CLI}/${CONTAINER_CLI}-${COMPOSE_FILE_BASE}"

  COMPOSE_FILES="${COMPOSE_FILES} -f compose/${COMPOSE_FILE_COUCH} -f compose/${CONTAINER_CLI}/${CONTAINER_CLI}-${COMPOSE_FILE_COUCH}"

  DOCKER_SOCK="${DOCKER_SOCK}" ${CONTAINER_CLI_COMPOSE} ${COMPOSE_FILES} up -d 2>&1

  $CONTAINER_CLI ps -a
  if [ $? -ne 0 ]; then
    fatalln "Unable to start network"
  fi
}

# call the script to create the channel, join the peers of org1 and org2,
# and then update the anchor peers for each organization
# Bring up the peer and orderer nodes using docker compose.
# *****************************************************************************
# -------------------------------Referencce------------------------------------
# This function is from the sample of Fabric network. And I have done some 
# modification

# Reference: https://hyperledger-fabric.readthedocs.io/en/release-2.5/
# *****************************************************************************
function createChannel() {


  if ! $CONTAINER_CLI info > /dev/null 2>&1 ; then
    fatalln "$CONTAINER_CLI network is required to be running to create a channel"
  fi

  # check if all containers are present
  CONTAINERS=($($CONTAINER_CLI ps | grep hyperledger/ | awk '{print $2}'))
  len=$(echo ${#CONTAINERS[@]})



  infoln "Bringing up network"
  networkUp
  

  # now run the script that creates a channel. This script uses configtxgen once
  # to create the channel creation transaction and the anchor peer updates.
  infoln "Successfully bring up the network, start create channel"
  read -p "Press enter to continue"
  scripts/createChannel.sh $CHANNEL_NAME $CLI_DELAY $MAX_RETRY $VERBOSE $CONFIG_PATH
}


## Call the script to deploy a chaincode to the channel
# *****************************************************************************
# -------------------------------Referencce------------------------------------
# This function is from the sample of Fabric network

# Reference: https://hyperledger-fabric.readthedocs.io/en/release-2.5/
# *****************************************************************************
function deployCC() {
  scripts/deployCC.sh $CHANNEL_NAME $CC_NAME $CC_SRC_PATH $CC_SRC_LANGUAGE $CC_VERSION $CC_SEQUENCE $CC_INIT_FCN $CC_END_POLICY $CC_COLL_CONFIG $CLI_DELAY $MAX_RETRY $VERBOSE $CONFIG_PATH

  if [ $? -ne 0 ]; then
    fatalln "Deploying chaincode failed"
  fi
}



# Tear down running network
# *****************************************************************************
# -------------------------------Referencce------------------------------------
# This function is from the sample of Fabric network

# Reference: https://hyperledger-fabric.readthedocs.io/en/release-2.5/
# *****************************************************************************
function networkDown() {

  COMPOSE_BASE_FILES="-f compose/${COMPOSE_FILE_BASE} -f compose/${CONTAINER_CLI}/${CONTAINER_CLI}-${COMPOSE_FILE_BASE}"
  COMPOSE_COUCH_FILES="-f compose/${COMPOSE_FILE_COUCH} -f compose/${CONTAINER_CLI}/${CONTAINER_CLI}-${COMPOSE_FILE_COUCH}"
  COMPOSE_CA_FILES="-f compose/${COMPOSE_FILE_CA} -f compose/${CONTAINER_CLI}/${CONTAINER_CLI}-${COMPOSE_FILE_CA}"
  COMPOSE_FILES="${COMPOSE_BASE_FILES} ${COMPOSE_COUCH_FILES} ${COMPOSE_CA_FILES}"

  # stop org3 containers also in addition to org1 and org2, in case we were running sample to add org3
  # COMPOSE_ORG3_BASE_FILES="-f addOrg3/compose/${COMPOSE_FILE_ORG3_BASE} -f addOrg3/compose/${CONTAINER_CLI}/${CONTAINER_CLI}-${COMPOSE_FILE_ORG3_BASE}"
  # COMPOSE_ORG3_COUCH_FILES="-f addOrg3/compose/${COMPOSE_FILE_ORG3_COUCH} -f addOrg3/compose/${CONTAINER_CLI}/${CONTAINER_CLI}-${COMPOSE_FILE_ORG3_COUCH}"
  # COMPOSE_ORG3_CA_FILES="-f addOrg3/compose/${COMPOSE_FILE_ORG3_CA} -f addOrg3/compose/${CONTAINER_CLI}/${CONTAINER_CLI}-${COMPOSE_FILE_ORG3_CA}"
  # COMPOSE_ORG3_FILES="${COMPOSE_ORG3_BASE_FILES} ${COMPOSE_ORG3_COUCH_FILES} ${COMPOSE_ORG3_CA_FILES}"
  

  if [ "${CONTAINER_CLI}" == "docker" ]; then
    DOCKER_SOCK=$DOCKER_SOCK ${CONTAINER_CLI_COMPOSE} ${COMPOSE_FILES} ${COMPOSE_ORG3_FILES} down --volumes --remove-orphans
  elif [ "${CONTAINER_CLI}" == "podman" ]; then
    ${CONTAINER_CLI_COMPOSE} ${COMPOSE_FILES} ${COMPOSE_ORG3_FILES} down --volumes
  else
    fatalln "Container CLI  ${CONTAINER_CLI} not supported"
  fi


  # Don't remove the generated artifacts -- note, the ledgers are always removed
  if [ "$MODE" != "restart" ]; then
    # Bring down the network, deleting the volumes
    ${CONTAINER_CLI} volume rm docker_orderer.example.com docker_peer0.org1.example.com docker_peer0.org2.example.com
    #Cleanup the chaincode containers
    clearContainers
    #Cleanup images
    removeUnwantedImages
    #
    ${CONTAINER_CLI} kill $(${CONTAINER_CLI} ps -q --filter name=ccaas) || true
    # remove orderer block and other channel configuration transactions and certs
    ${CONTAINER_CLI} run --rm -v "$(pwd):/data" busybox sh -c 'cd /data && rm -rf system-genesis-block/*.block organizations/peerOrganizations organizations/ordererOrganizations'
    ## remove fabric ca artifacts

    for ((i=0;i<$PEER_NUM;i++));
    do
      ORG=$(cat ${CONFIG_PATH} | jq ".peers[$i].NAME" | tr -d '"')
      ${CONTAINER_CLI} run --rm -v "$(pwd):/data" busybox sh -c "cd /data && rm -rf organizations/fabric-ca/org${ORG}/msp organizations/fabric-ca/org${ORG}/tls-cert.pem organizations/fabric-ca/org${ORG}/ca-cert.pem organizations/fabric-ca/org${ORG}/IssuerPublicKey organizations/fabric-ca/org${ORG}/IssuerRevocationPublicKey organizations/fabric-ca/org${ORG}/fabric-ca-server.db"
    done

    #${CONTAINER_CLI} run --rm -v "$(pwd):/data" busybox sh -c 'cd /data && rm -rf organizations/fabric-ca/org1/msp organizations/fabric-ca/org1/tls-cert.pem organizations/fabric-ca/org1/ca-cert.pem organizations/fabric-ca/org1/IssuerPublicKey organizations/fabric-ca/org1/IssuerRevocationPublicKey organizations/fabric-ca/org1/fabric-ca-server.db'
    #${CONTAINER_CLI} run --rm -v "$(pwd):/data" busybox sh -c 'cd /data && rm -rf organizations/fabric-ca/org2/msp organizations/fabric-ca/org2/tls-cert.pem organizations/fabric-ca/org2/ca-cert.pem organizations/fabric-ca/org2/IssuerPublicKey organizations/fabric-ca/org2/IssuerRevocationPublicKey organizations/fabric-ca/org2/fabric-ca-server.db'
    

    ${CONTAINER_CLI} run --rm -v "$(pwd):/data" busybox sh -c 'cd /data && rm -rf organizations/fabric-ca/ordererOrg/msp organizations/fabric-ca/ordererOrg/tls-cert.pem organizations/fabric-ca/ordererOrg/ca-cert.pem organizations/fabric-ca/ordererOrg/IssuerPublicKey organizations/fabric-ca/ordererOrg/IssuerRevocationPublicKey organizations/fabric-ca/ordererOrg/fabric-ca-server.db'
    #${CONTAINER_CLI} run --rm -v "$(pwd):/data" busybox sh -c 'cd /data && rm -rf addOrg3/fabric-ca/org3/msp addOrg3/fabric-ca/org3/tls-cert.pem addOrg3/fabric-ca/org3/ca-cert.pem addOrg3/fabric-ca/org3/IssuerPublicKey addOrg3/fabric-ca/org3/IssuerRevocationPublicKey addOrg3/fabric-ca/org3/fabric-ca-server.db'
    #${CONTAINER_CLI} run --rm -v "$(pwd):/data" busybox sh -c "cd /data && rm -rf addOrg3/fabric-ca/org${ORG}/msp addOrg3/fabric-ca/org${ORG}/tls-cert.pem addOrg3/fabric-ca/org${ORG}/ca-cert.pem addOrg3/fabric-ca/org${ORG}/IssuerPublicKey addOrg3/fabric-ca/org${ORG}/IssuerRevocationPublicKey addOrg3/fabric-ca/org${ORG}/fabric-ca-server.db"
    # remove channel and script artifacts
    ${CONTAINER_CLI} run --rm -v "$(pwd):/data" busybox sh -c 'cd /data && rm -rf channel-artifacts log.txt *.tar.gz'
  fi
}

# *****************************************************************************
# -------------------------------Referencce------------------------------------
# The parsing code is from the sample of Fabric network. And I have done some
# modifications.

# Reference: https://hyperledger-fabric.readthedocs.io/en/release-2.5/
# *****************************************************************************

# Using crpto vs CA. default is cryptogen
CRYPTO="cryptogen"
# timeout duration - the duration the CLI should wait for a response from
# another container before giving up
MAX_RETRY=5
# default for delay between commands
CLI_DELAY=3
# channel name defaults to "mychannel"
CHANNEL_NAME="mychannel"
# chaincode name defaults to "NA"
CC_NAME="NA"
# chaincode path defaults to "NA"
CC_SRC_PATH="NA"
# endorsement policy defaults to "NA". This would allow chaincodes to use the majority default policy.
CC_END_POLICY="NA"
# collection configuration defaults to "NA"
CC_COLL_CONFIG="NA"
# chaincode init function defaults to "NA"
CC_INIT_FCN="NA"
# use this as the default docker-compose yaml definition
COMPOSE_FILE_BASE=compose-test-net.yaml
# docker-compose.yaml file if you are using couchdb
COMPOSE_FILE_COUCH=compose-couch.yaml
# certificate authorities compose file
COMPOSE_FILE_CA=compose-ca.yaml
# use this as the default docker-compose yaml definition for org3
COMPOSE_FILE_ORG3_BASE=compose-org3.yaml
# use this as the docker compose couch file for org3
COMPOSE_FILE_ORG3_COUCH=compose-couch-org3.yaml
# certificate authorities compose file
COMPOSE_FILE_ORG3_CA=compose-ca-org3.yaml
#
# chaincode language defaults to "NA"
CC_SRC_LANGUAGE="NA"
# default to running the docker commands for the CCAAS
CCAAS_DOCKER_RUN=true
# Chaincode version
CC_VERSION="1.0"
# Chaincode definition sequence
CC_SEQUENCE=1
# default database
DATABASE="couchdb"
# default ORG name
ORG=3
PEER_NUM=2
CONFIG_PATH="./config.json"
# Get docker sock path from environment variable
SOCK="${DOCKER_HOST:-/var/run/docker.sock}"
DOCKER_SOCK="${SOCK##unix://}"

# Parse commandline args

## Parse mode
if [[ $# -lt 1 ]] ; then
  printHelp
  exit 0
else
  MODE=$1
  shift
fi

# parse a createChannel subcommand if used
if [[ $# -ge 1 ]] ; then
  key="$1"
  if [[ "$key" == "createChannel" ]]; then
      export MODE="createChannel"
      shift
  fi
fi

# parse flags

while [[ $# -ge 1 ]] ; do
  key="$1"
  case $key in
  -h )
    printHelp $MODE
    exit 0
    ;;
  -c )
    CHANNEL_NAME="$2"
    shift
    ;;
  -r )
    MAX_RETRY="$2"
    shift
    ;;
  -d )
    CLI_DELAY="$2"
    shift
    ;;
  -ccl )
    CC_SRC_LANGUAGE="$2"
    shift
    ;;
  -ccn )
    CC_NAME="$2"
    shift
    ;;
  -ccv )
    CC_VERSION="$2"
    shift
    ;;
  -ccs )
    CC_SEQUENCE="$2"
    shift
    ;;
  -ccp )
    CC_SRC_PATH="$2"
    shift
    ;;
  -ccep )
    CC_END_POLICY="$2"
    shift
    ;;
  -cccg )
    CC_COLL_CONFIG="$2"
    shift
    ;;
  -cci )
    CC_INIT_FCN="$2"
    shift
    ;;
  -verbose )
    VERBOSE=true
    ;;
  -n )
    ORG="$2"
    # use this as the default docker-compose yaml definition for org3
    COMPOSE_FILE_ORG3_BASE=compose-org${ORG}.yaml
    # use this as the docker compose couch file for org3
    COMPOSE_FILE_ORG3_COUCH=compose-couch-org${ORG}.yaml
    # certificate authorities compose file
    COMPOSE_FILE_ORG3_CA=compose-ca-org${ORG}.yaml
    shift
    ;;
  -p )
    CONFIG_PATH="$2"
    PEER_NUM=$(cat ${CONFIG_PATH} | jq ".peers | length")
    shift
    ;;
  * )
    errorln "Unknown flag: $key"
    printHelp
    exit 1
    ;;
  esac
  shift
done

# Are we generating crypto material with this command?
if [ ! -d "organizations/peerOrganizations" ]; then
  CRYPTO_MODE="with crypto from '${CRYPTO}'"
else
  CRYPTO_MODE=""
fi

# Determine mode of operation and printing out what we asked for
if [ "$MODE" == "up" ]; then
  infoln "Starting nodes with CLI timeout of '${MAX_RETRY}' tries and CLI delay of '${CLI_DELAY}' seconds and using database '${DATABASE}' ${CRYPTO_MODE}"
  networkUp
elif [ "$MODE" == "createChannel" ]; then
  infoln "Creating channel '${CHANNEL_NAME}'."
  infoln "If network is not up, starting nodes with CLI timeout of '${MAX_RETRY}' tries and CLI delay of '${CLI_DELAY}' seconds and using database '${DATABASE} ${CRYPTO_MODE}"
  createChannel
elif [ "$MODE" == "down" ]; then
  infoln "Stopping network"
  networkDown
elif [ "$MODE" == "restart" ]; then
  infoln "Restarting network"
  networkDown
  networkUp
elif [ "$MODE" == "deployCC" ]; then
  infoln "deploying chaincode on channel '${CHANNEL_NAME}'"
  deployCC
else
  printHelp
  exit 1
fi
