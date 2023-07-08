#!/bin/bash

# imports  
. scripts/envVar.sh
. scripts/utils.sh

CHANNEL_NAME="$1"
DELAY="$2"
MAX_RETRY="$3"
VERBOSE="$4"
CONFIG_PATH="$5"
: ${CHANNEL_NAME:="mychannel"}
: ${DELAY:="3"}
: ${MAX_RETRY:="5"}
: ${VERBOSE:="false"}
: ${CONFIG_PATH:="../config.json"}

: ${CONTAINER_CLI:="docker"}
: ${CONTAINER_CLI_COMPOSE:="${CONTAINER_CLI}-compose"}
infoln "Using ${CONTAINER_CLI} and ${CONTAINER_CLI_COMPOSE}"

if [ ! -d "channel-artifacts" ]; then
	mkdir channel-artifacts
fi

createChannelGenesisBlock() {
	which configtxgen
	if [ "$?" -ne 0 ]; then
		fatalln "configtxgen tool not found."
	fi
	set -x
	PROFILE=$(cat ${CONFIG_PATH} | jq ".PROFILE" | tr -d '"')
	configtxgen -profile ${PROFILE} -outputBlock ./channel-artifacts/${CHANNEL_NAME}.block -channelID $CHANNEL_NAME
	res=$?
	{ set +x; } 2>/dev/null
  verifyResult $res "Failed to generate channel configuration transaction..."
}

createChannel() {
	PEER_ORG=$(cat ${CONFIG_PATH} | jq ".peers[0].NAME" | tr -d '"')
	ORDERER_ORG=$(cat ${CONFIG_PATH} | jq ".orderer.NAME" | tr -d '"')
	ORDERER_ADMIN_PORT=$(cat ${CONFIG_PATH} | jq ".orderer.ORDERER_ADMIN_PORT")
	ORDERER_CA=${PWD}/organizations/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem
	ORDERER_ADMIN_TLS_SIGN_CERT=${PWD}/organizations/ordererOrganizations/example.com/orderers/${ORDERER_ORG}.example.com/tls/server.crt
	ORDERER_ADMIN_TLS_PRIVATE_KEY=${PWD}/organizations/ordererOrganizations/example.com/orderers/${ORDERER_ORG}.example.com/tls/server.key

	#ORDERER_IP_ADDR=$(cat ${CONFIG_PATH} | jq ".orderer.IP_ADDR" | tr -d '"')

	setGlobals $PEER_ORG
	# Poll in case the raft leader is not set yet
	local rc=1
	local COUNTER=1
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
		sleep $DELAY
		set -x
		osnadmin channel join --channelID $CHANNEL_NAME --config-block ./channel-artifacts/${CHANNEL_NAME}.block -o localhost:${ORDERER_ADMIN_PORT} --ca-file "$ORDERER_CA" --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY" >&log.txt
		res=$?
		{ set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	verifyResult $res "Channel creation failed"
}

# joinChannel ORG
joinChannel() {
  FABRIC_CFG_PATH=$PWD/../config/
  ORG=$1
  setGlobals $ORG
	local rc=1
	local COUNTER=1
	## Sometimes Join takes time, hence retry
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    set -x
    peer channel join -b $BLOCKFILE >&log.txt
    res=$?
    { set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	verifyResult $res "After $MAX_RETRY attempts, peer0.org${ORG} has failed to join channel '$CHANNEL_NAME' "
}

setAnchorPeer() {
  ORG=$1
  DOMAIN=$2 
  PEER_PORT=$3 
  ORDERER_DOMAIN=$4 
  ORDERER_PORT=$5

  ${CONTAINER_CLI} exec cli ./scripts/setAnchorPeer.sh $ORG $CHANNEL_NAME $DOMAIN $PEER_PORT $ORDERER_DOMAIN $ORDERER_PORT
}

FABRIC_CFG_PATH=${PWD}/configtx

## Create channel genesis block
isDeployOrderer=$(cat ${CONFIG_PATH} | jq ".isDeployOrderer")
if $isDeployOrderer;
then
infoln "Generating channel genesis block '${CHANNEL_NAME}.block'"
createChannelGenesisBlock

else


FABRIC_CFG_PATH=$PWD/../config/
echo $FABRIC_CFG_PATH
ORG=$(cat ${CONFIG_PATH} | jq ".peers[0].NAME" | tr -d '"')
DOMAIN=$(cat ${CONFIG_PATH} | jq ".peers[0].DOMAIN" | tr -d '"')
IP_ADDR=$(cat ${CONFIG_PATH} | jq ".peers[0].IP_ADDR" | tr -d '"')
PEER_PORT=$(cat ${CONFIG_PATH} | jq ".peers[0].PEER_PORT" | tr -d '"')
ORDERER_GENERAL_PORT=$(cat ${CONFIG_PATH} | jq ".orderer.ORDERER_GENERAL_PORT" | tr -d '"')
#ORG=3
#DOMAIN="org3.example.com"
export CORE_PEER_LOCALMSPID="Org${ORG}MSP"
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/${DOMAIN}/users/Admin@${DOMAIN}/msp
export CORE_PEER_ADDRESS=${IP_ADDR}:${PEER_PORT}
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/${DOMAIN}/tlsca/tlsca.${DOMAIN}-cert.pem

# setGlobals $ORG
  

infoln "fetch channel genesis block '${CHANNEL_NAME}.block'"
#export CORE_PEER_LOCALMSPID="Org3MSP"
#export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/${DOMAIN}/users/Admin@${DOMAIN}/msp
#export CORE_PEER_ADDRESS=localhost:11051
#export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org3.example.com/tlsca/tlsca.org3.example.com-cert.pem
echo $CORE_PEER_MSPCONFIGPATH
peer channel fetch 0 ./channel-artifacts/${CHANNEL_NAME}.block -c ${CHANNEL_NAME} -o orderer.example.com:${ORDERER_GENERAL_PORT} --tls --cafile $ORDERER_CA

fi

FABRIC_CFG_PATH=$PWD/../config/
BLOCKFILE="./channel-artifacts/${CHANNEL_NAME}.block"

isDeployOrderer=$(cat ${CONFIG_PATH} | jq ".isDeployOrderer")
if $isDeployOrderer;
then
	

	## Create channel
	infoln "Creating channel ${CHANNEL_NAME}"
	createChannel
	successln "Channel '$CHANNEL_NAME' created"
fi

## Join all the peers to the channel
PEER_NUM=$(cat ${CONFIG_PATH} | jq ".peers | length")
for ((i=0;i<$PEER_NUM;i++));
do
	ORG=$(cat ${CONFIG_PATH} | jq ".peers[$i].NAME")

	infoln "Joining ${ORG} peer to the channel..."
	joinChannel $ORG
	
done
# infoln "Joining org1 peer to the channel..."
# joinChannel 1
# infoln "Joining org2 peer to the channel..."
# joinChannel 2

## Set the anchor peers for each org in the channel

for ((i=0;i<$PEER_NUM;i++));
do
	ORG=$(cat ${CONFIG_PATH} | jq ".peers[$i].NAME" | tr -d '"')
	DOMAIN=$(cat ${CONFIG_PATH} | jq ".peers[$i].DOMAIN" | tr -d '"')
	PEER_PORT=$(cat ${CONFIG_PATH} | jq ".peers[$i].PEER_PORT")
	ORDERER_DOMAIN=$(cat ${CONFIG_PATH} | jq ".orderer.DOMAIN" | tr -d '"')
	ORDERER_PORT=$(cat ${CONFIG_PATH} | jq ".orderer.ORDERER_GENERAL_PORT")

	infoln "Setting anchor peer for ${ORG}..."
	setAnchorPeer $ORG $DOMAIN $PEER_PORT $ORDERER_DOMAIN $ORDERER_PORT
done

# infoln "Setting anchor peer for org1..."
# setAnchorPeer 1
# infoln "Setting anchor peer for org2..."
# setAnchorPeer 2

successln "Channel '$CHANNEL_NAME' joined"
