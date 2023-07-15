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
# This is a collection of bash functions used by different scripts

# imports
. scripts/utils.sh

export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/${ORDERER_DOMAIN}/tlsca/tlsca.${ORDERER_DOMAIN}-cert.pem
export ORDERER_ADMIN_TLS_SIGN_CERT=${PWD}/organizations/ordererOrganizations/${ORDERER_DOMAIN}/orderers/${ORDERER_ORG}.${ORDERER_DOMAIN}/tls/server.crt
export ORDERER_ADMIN_TLS_PRIVATE_KEY=${PWD}/organizations/ordererOrganizations/${ORDERER_DOMAIN}/orderers/${ORDERER_ORG}.${ORDERER_DOMAIN}/tls/server.key

# Set environment variables for the peer org
setGlobals() {
  ORG=$1
	PEER_PORT=$2
  DOMAIN=$3

  export PEER0_ORG_CA=${PWD}/organizations/peerOrganizations/${DOMAIN}/tlsca/tlsca.${DOMAIN}-cert.pem

  export CORE_PEER_LOCALMSPID="Org${ORG}MSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/${DOMAIN}/tlsca/tlsca.${DOMAIN}-cert.pem
  export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/${DOMAIN}/users/Admin@${DOMAIN}/msp
  export CORE_PEER_ADDRESS=localhost:${PEER_PORT}


  if [ "$VERBOSE" == "true" ]; then
    env | grep CORE
  fi
}



# parsePeerConnectionParameters $@
# Helper function that sets the peer connection parameters for a chaincode
# operation
parsePeerConnectionParameters() {
  PEER_CONN_PARMS=()
  PEERS=""
  while [ "$#" -gt 0 ]; do
  
    setGlobals $1 $2 $3
    PEER="peer0.org$1"
    ## Set peer addresses
    if [ -z "$PEERS" ]
    then
	PEERS="$PEER"
    else
	PEERS="$PEERS $PEER"
    fi
    PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" --peerAddresses $CORE_PEER_ADDRESS)
    ## Set path to TLS certificate
    CA=PEER0_ORG_CA
    TLSINFO=(--tlsRootCertFiles "${!CA}")
    PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" "${TLSINFO[@]}")
    # shift by one to get to the next organization
    shift 3
  done
}

verifyResult() {
  if [ $1 -ne 0 ]; then
    fatalln "$2"
  fi
}
