#!/bin/bash

# *****************************************************************************
# -------------------------------Referencce------------------------------------
# This script is the demo script of Hyperledger Fabric network and we do some
# modifications on the script so that it suits better in our project.

# Reference: https://hyperledger-fabric.readthedocs.io/en/release-2.5/
# *****************************************************************************

source scripts/utils.sh

CHANNEL_NAME=${1:-"mychannel"}
CC_NAME=${2}
CC_SRC_PATH=${3}
CC_SRC_LANGUAGE=${4}
CC_VERSION=${5:-"1.0"}
CC_SEQUENCE=${6:-"1"}
CC_INIT_FCN=${7:-"NA"}
CC_END_POLICY=${8:-"NA"}
CC_COLL_CONFIG=${9:-"NA"}
DELAY=${10:-"3"}
MAX_RETRY=${11:-"5"}
VERBOSE=${12:-"false"}
CONFIG_PATH=${13:-"../config.json"}

println "executing with the following"
println "- CHANNEL_NAME: ${C_GREEN}${CHANNEL_NAME}${C_RESET}"
println "- CC_NAME: ${C_GREEN}${CC_NAME}${C_RESET}"
println "- CC_SRC_PATH: ${C_GREEN}${CC_SRC_PATH}${C_RESET}"
println "- CC_SRC_LANGUAGE: ${C_GREEN}${CC_SRC_LANGUAGE}${C_RESET}"
println "- CC_VERSION: ${C_GREEN}${CC_VERSION}${C_RESET}"
println "- CC_SEQUENCE: ${C_GREEN}${CC_SEQUENCE}${C_RESET}"
println "- CC_END_POLICY: ${C_GREEN}${CC_END_POLICY}${C_RESET}"
println "- CC_COLL_CONFIG: ${C_GREEN}${CC_COLL_CONFIG}${C_RESET}"
println "- CC_INIT_FCN: ${C_GREEN}${CC_INIT_FCN}${C_RESET}"
println "- DELAY: ${C_GREEN}${DELAY}${C_RESET}"
println "- MAX_RETRY: ${C_GREEN}${MAX_RETRY}${C_RESET}"
println "- VERBOSE: ${C_GREEN}${VERBOSE}${C_RESET}"
println "- CONFIG_PATH: ${C_GREEN}${CONFIG_PATH}${C_RESET}"

FABRIC_CFG_PATH=$PWD/../config/

#User has not provided a name
if [ -z "$CC_NAME" ] || [ "$CC_NAME" = "NA" ]; then
  fatalln "No chaincode name was provided. Valid call example: ./network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-go -ccl go"

# User has not provided a path
elif [ -z "$CC_SRC_PATH" ] || [ "$CC_SRC_PATH" = "NA" ]; then
  fatalln "No chaincode path was provided. Valid call example: ./network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-go -ccl go"

# User has not provided a language
elif [ -z "$CC_SRC_LANGUAGE" ] || [ "$CC_SRC_LANGUAGE" = "NA" ]; then
  fatalln "No chaincode language was provided. Valid call example: ./network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-go -ccl go"

## Make sure that the path to the chaincode exists
elif [ ! -d "$CC_SRC_PATH" ] && [ ! -f "$CC_SRC_PATH" ]; then
  fatalln "Path to chaincode does not exist. Please provide different path."
fi

CC_SRC_LANGUAGE=$(echo "$CC_SRC_LANGUAGE" | tr [:upper:] [:lower:])

# do some language specific preparation to the chaincode before packaging
if [ "$CC_SRC_LANGUAGE" = "go" ]; then
  CC_RUNTIME_LANGUAGE=golang

  infoln "Vendoring Go dependencies at $CC_SRC_PATH"
  pushd $CC_SRC_PATH
  GO111MODULE=on go mod vendor
  popd
  successln "Finished vendoring Go dependencies"

elif [ "$CC_SRC_LANGUAGE" = "java" ]; then
  CC_RUNTIME_LANGUAGE=java

  rm -rf $CC_SRC_PATH/build/install/
  infoln "Compiling Java code..."
  pushd $CC_SRC_PATH
  ./gradlew installDist
  popd
  successln "Finished compiling Java code"
  CC_SRC_PATH=$CC_SRC_PATH/build/install/$CC_NAME

elif [ "$CC_SRC_LANGUAGE" = "javascript" ]; then
  CC_RUNTIME_LANGUAGE=node

elif [ "$CC_SRC_LANGUAGE" = "typescript" ]; then
  CC_RUNTIME_LANGUAGE=node

  infoln "Compiling TypeScript code into JavaScript..."
  pushd $CC_SRC_PATH
  npm install
  npm run build
  popd
  successln "Finished compiling TypeScript code into JavaScript"

else
  fatalln "The chaincode language ${CC_SRC_LANGUAGE} is not supported by this script. Supported chaincode languages are: go, java, javascript, and typescript"
  exit 1
fi

INIT_REQUIRED="--init-required"
# check if the init fcn should be called
if [ "$CC_INIT_FCN" = "NA" ]; then
  INIT_REQUIRED=""
fi

if [ "$CC_END_POLICY" = "NA" ]; then
  CC_END_POLICY=""
else
  CC_END_POLICY="--signature-policy $CC_END_POLICY"
fi

if [ "$CC_COLL_CONFIG" = "NA" ]; then
  CC_COLL_CONFIG=""
else
  CC_COLL_CONFIG="--collections-config $CC_COLL_CONFIG"
fi

# import utils
. scripts/envVar.sh
. scripts/ccutils.sh

packageChaincode() {
  set -x
  peer lifecycle chaincode package ${CC_NAME}.tar.gz --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} --label ${CC_NAME}_${CC_VERSION} >&log.txt
  res=$?
  PACKAGE_ID=$(peer lifecycle chaincode calculatepackageid ${CC_NAME}.tar.gz)
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Chaincode packaging has failed"
  successln "Chaincode is packaged"
}

function checkPrereqs() {
  jq --version > /dev/null 2>&1

  if [[ $? -ne 0 ]]; then
    errorln "jq command not found..."
    errorln
    errorln "Follow the instructions in the Fabric docs to install the prereqs"
    errorln "https://hyperledger-fabric.readthedocs.io/en/latest/prereqs.html"
    exit 1
  fi
}

#check for prerequisites
checkPrereqs

## package the chaincode
packageChaincode


# *****************************************************************************
# Starting fron below is my code
# *****************************************************************************

if [ ! -f  ${CONFIG_PATH} ]
then
  PEER_NUM=2
else
  # file exists
  PEER_NUM=$(cat ${CONFIG_PATH} | jq ".peers | length")
fi

for ((i=0;i<$PEER_NUM;i++));
do
  NAME=$(cat ${CONFIG_PATH} | jq ".peers[$i].NAME" | tr -d '"')
  PEER_PORT=$(cat ${CONFIG_PATH} | jq ".peers[$i].PEER_PORT")
  infoln "Installing chaincode on peer0.org${NAME}..."
  installChaincode ${NAME} ${PEER_PORT}
done



## query whether the chaincode is installed
NAME=$(cat ${CONFIG_PATH} | jq ".peers[0].NAME" | tr -d '"')
PEER_PORT=$(cat ${CONFIG_PATH} | jq ".peers[0].PEER_PORT")
queryInstalled ${NAME} ${PEER_PORT}

ORDERER_IP_ADDR=$(cat ${CONFIG_PATH} | jq ".orderer.IP_ADDR" | tr -d '"')
ORDERER_GENERAL_PORT=$(cat ${CONFIG_PATH} | jq ".orderer.ORDERER_GENERAL_PORT")
ORDERER_DOMAIN=$(cat ${CONFIG_PATH} | jq ".orderer.DOMAIN" | tr -d '"')

for ((i=0;i<$PEER_NUM;i++));
do
  NAME_I=$(cat ${CONFIG_PATH} | jq ".peers[$i].NAME" | tr -d '"')
  PEER_PORT=$(cat ${CONFIG_PATH} | jq ".peers[$i].PEER_PORT")
  approveForMyOrg ${NAME_I} ${PEER_PORT}
  for ((j=0;j<$PEER_NUM;j++));
  do
    NAME_J=$(cat ${CONFIG_PATH} | jq ".peers[$j].NAME" | tr -d '"')
    PEER_PORT_J=$(cat ${CONFIG_PATH} | jq ".peers[$j].PEER_PORT")
    checkCommitReadiness ${NAME_J} ${PEER_PORT_J} "\"Org${NAME_I}MSP\": true"
  done
done


## now that we know for sure both orgs have approved, commit the definition
isDeployOrderer=$(cat ${CONFIG_PATH} | jq ".isDeployOrderer")
if $isDeployOrderer;
then

  ARR=()
  for ((i=0;i<$PEER_NUM;i++));
  do
    NAME=$(cat ${CONFIG_PATH} | jq ".peers[$i].NAME" | tr -d '"')
    PEER_PORT=$(cat ${CONFIG_PATH} | jq ".peers[$i].PEER_PORT")
    ARR+=(${NAME})
    ARR+=(${PEER_PORT})
  done

  read -p "Press enter to continue"
  commitChaincodeDefinition ${ARR[@]}
  #commitChaincodeDefinition 1 2 3

  # query on both orgs to see that the definition committed successfully
  for ((i=0;i<$PEER_NUM;i++));
  do
    NAME=$(cat ${CONFIG_PATH} | jq ".peers[$i].NAME" | tr -d '"')
    PEER_PORT=$(cat ${CONFIG_PATH} | jq ".peers[$i].PEER_PORT")
    queryCommitted ${NAME} ${PEER_PORT}
  done

fi


exit 0
