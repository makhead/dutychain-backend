#!/bin/bash

# *****************************************************************************
# -------------------------------Referencce------------------------------------
# This script is the demo script of Hyperledger Fabric network and we do some
# modifications on the script so that it suits better in our project.

# Reference: https://hyperledger-fabric.readthedocs.io/en/release-2.5/
# *****************************************************************************

function createOrg() {
  infoln "Enrolling the CA admin"
  mkdir -p organizations/peerOrganizations/${DOMAIN}/

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/${DOMAIN}/

  set -x
  fabric-ca-client enroll -u https://${CA_USERNAME}:${CA_PASSWORD}@localhost:${CA_SERVER_PORT} --caname ca-org${ORG} --tls.certfiles "${PWD}/organizations/fabric-ca/org${ORG}/ca-cert.pem"
  { set +x; } 2>/dev/null

  echo "NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-${CA_SERVER_PORT}-ca-org${ORG}.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-${CA_SERVER_PORT}-ca-org${ORG}.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-${CA_SERVER_PORT}-ca-org${ORG}.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-${CA_SERVER_PORT}-ca-org${ORG}.pem
    OrganizationalUnitIdentifier: orderer" > "${PWD}/organizations/peerOrganizations/${DOMAIN}/msp/config.yaml"

  # Since the CA serves as both the organization CA and TLS CA, copy the org's root cert that was generated by CA startup into the org level ca and tlsca directories

  # Copy org1's CA cert to org1's /msp/tlscacerts directory (for use in the channel MSP definition)
  mkdir -p "${PWD}/organizations/peerOrganizations/${DOMAIN}/msp/tlscacerts"
  cp "${PWD}/organizations/fabric-ca/org${ORG}/ca-cert.pem" "${PWD}/organizations/peerOrganizations/${DOMAIN}/msp/tlscacerts/ca.crt"

  # Copy org1's CA cert to org1's /tlsca directory (for use by clients)
  mkdir -p "${PWD}/organizations/peerOrganizations/${DOMAIN}/tlsca"
  cp "${PWD}/organizations/fabric-ca/org${ORG}/ca-cert.pem" "${PWD}/organizations/peerOrganizations/${DOMAIN}/tlsca/tlsca.${DOMAIN}-cert.pem"

  # Copy org1's CA cert to org1's /ca directory (for use by clients)
  mkdir -p "${PWD}/organizations/peerOrganizations/${DOMAIN}/ca"
  cp "${PWD}/organizations/fabric-ca/org${ORG}/ca-cert.pem" "${PWD}/organizations/peerOrganizations/${DOMAIN}/ca/ca.${DOMAIN}-cert.pem"

  infoln "Registering peer0"
  set -x
  fabric-ca-client register --caname ca-org${ORG} --id.name ${CA_PEER_USERNAME} --id.secret ${CA_PEER_PASSWORD} --id.type peer --tls.certfiles "${PWD}/organizations/fabric-ca/org${ORG}/ca-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering user"
  set -x
  fabric-ca-client register --caname ca-org${ORG} --id.name ${CA_USER_USERNAME} --id.secret ${CA_USER_PASSWORD} --id.type client --tls.certfiles "${PWD}/organizations/fabric-ca/org${ORG}/ca-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering the org admin"
  set -x
  fabric-ca-client register --caname ca-org${ORG} --id.name ${CA_ADMIN_USERNAME} --id.secret ${CA_ADMIN_PASSWORD} --id.type admin --tls.certfiles "${PWD}/organizations/fabric-ca/org${ORG}/ca-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Generating the peer0 msp"
  set -x
  fabric-ca-client enroll -u https://${CA_PEER_USERNAME}:${CA_PEER_PASSWORD}@localhost:${CA_SERVER_PORT} --caname ca-org${ORG} -M "${PWD}/organizations/peerOrganizations/${DOMAIN}/peers/peer0.${DOMAIN}/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/org${ORG}/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/${DOMAIN}/msp/config.yaml" "${PWD}/organizations/peerOrganizations/${DOMAIN}/peers/peer0.${DOMAIN}/msp/config.yaml"

  infoln "Generating the peer0-tls certificates, use --csr.hosts to specify Subject Alternative Names"
  set -x
  fabric-ca-client enroll -u https://${CA_PEER_USERNAME}:${CA_PEER_PASSWORD}@localhost:${CA_SERVER_PORT} --caname ca-org${ORG} -M "${PWD}/organizations/peerOrganizations/${DOMAIN}/peers/peer0.${DOMAIN}/tls" --enrollment.profile tls --csr.hosts peer0.${DOMAIN} --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/org${ORG}/ca-cert.pem"
  { set +x; } 2>/dev/null

  # Copy the tls CA cert, server cert, server keystore to well known file names in the peer's tls directory that are referenced by peer startup config
  cp "${PWD}/organizations/peerOrganizations/${DOMAIN}/peers/peer0.${DOMAIN}/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/${DOMAIN}/peers/peer0.${DOMAIN}/tls/ca.crt"
  cp "${PWD}/organizations/peerOrganizations/${DOMAIN}/peers/peer0.${DOMAIN}/tls/signcerts/"* "${PWD}/organizations/peerOrganizations/${DOMAIN}/peers/peer0.${DOMAIN}/tls/server.crt"
  cp "${PWD}/organizations/peerOrganizations/${DOMAIN}/peers/peer0.${DOMAIN}/tls/keystore/"* "${PWD}/organizations/peerOrganizations/${DOMAIN}/peers/peer0.${DOMAIN}/tls/server.key"

  infoln "Generating the user msp"
  set -x
  fabric-ca-client enroll -u https://${CA_USER_USERNAME}:${CA_USER_PASSWORD}@localhost:${CA_SERVER_PORT} --caname ca-org${ORG} -M "${PWD}/organizations/peerOrganizations/${DOMAIN}/users/User1@${DOMAIN}/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/org${ORG}/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/${DOMAIN}/msp/config.yaml" "${PWD}/organizations/peerOrganizations/${DOMAIN}/users/User1@${DOMAIN}/msp/config.yaml"

  infoln "Generating the org admin msp"
  set -x
  fabric-ca-client enroll -u https://${CA_ADMIN_USERNAME}:${CA_ADMIN_PASSWORD}@localhost:${CA_SERVER_PORT} --caname ca-org${ORG} -M "${PWD}/organizations/peerOrganizations/${DOMAIN}/users/Admin@${DOMAIN}/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/org${ORG}/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/${DOMAIN}/msp/config.yaml" "${PWD}/organizations/peerOrganizations/${DOMAIN}/users/Admin@${DOMAIN}/msp/config.yaml"
}


function createOrderer() {
  infoln "Enrolling the CA admin"
  mkdir -p organizations/ordererOrganizations/${ORDERER_DOMAIN}

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/ordererOrganizations/${ORDERER_DOMAIN}

  set -x
  fabric-ca-client enroll -u https://${CA_USERNAME}:${CA_PASSWORD}@localhost:${CA_SERVER_PORT} --caname ca-${ORG} --tls.certfiles "${PWD}/organizations/fabric-ca/${ORG}Org/ca-cert.pem"
  { set +x; } 2>/dev/null

  echo "NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-${CA_SERVER_PORT}-ca-${ORG}.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-${CA_SERVER_PORT}-ca-${ORG}.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-${CA_SERVER_PORT}-ca-${ORG}.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-${CA_SERVER_PORT}-ca-${ORG}.pem
    OrganizationalUnitIdentifier: orderer" > "${PWD}/organizations/ordererOrganizations/${ORDERER_DOMAIN}/msp/config.yaml"

  # Since the CA serves as both the organization CA and TLS CA, copy the org's root cert that was generated by CA startup into the org level ca and tlsca directories

  # Copy orderer org's CA cert to orderer org's /msp/tlscacerts directory (for use in the channel MSP definition)
  mkdir -p "${PWD}/organizations/ordererOrganizations/${ORDERER_DOMAIN}/msp/tlscacerts"
  cp "${PWD}/organizations/fabric-ca/${ORG}Org/ca-cert.pem" "${PWD}/organizations/ordererOrganizations/${ORDERER_DOMAIN}/msp/tlscacerts/tlsca.${ORDERER_DOMAIN}-cert.pem"

  # Copy orderer org's CA cert to orderer org's /tlsca directory (for use by clients)
  mkdir -p "${PWD}/organizations/ordererOrganizations/${ORDERER_DOMAIN}/tlsca"
  cp "${PWD}/organizations/fabric-ca/${ORG}Org/ca-cert.pem" "${PWD}/organizations/ordererOrganizations/${ORDERER_DOMAIN}/tlsca/tlsca.${ORDERER_DOMAIN}-cert.pem"

  infoln "Registering ${ORG}"
  set -x
  fabric-ca-client register --caname ca-${ORG} --id.name ${CA_ORDERER_USERNAME} --id.secret ${CA_ORDERER_PASSWORD} --id.type orderer --tls.certfiles "${PWD}/organizations/fabric-ca/${ORG}Org/ca-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering the ${ORG} admin"
  set -x
  fabric-ca-client register --caname ca-${ORG} --id.name ${CA_ADMIN_USERNAME} --id.secret ${CA_ADMIN_PASSWORD} --id.type admin --tls.certfiles "${PWD}/organizations/fabric-ca/${ORG}Org/ca-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Generating the ${ORG} msp"
  set -x
  fabric-ca-client enroll -u https://${CA_ORDERER_USERNAME}:${CA_ORDERER_PASSWORD}@localhost:${CA_SERVER_PORT} --caname ca-${ORG} -M "${PWD}/organizations/ordererOrganizations/${ORDERER_DOMAIN}/orderers/${ORG}.${ORDERER_DOMAIN}/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/${ORG}Org/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/ordererOrganizations/${ORDERER_DOMAIN}/msp/config.yaml" "${PWD}/organizations/ordererOrganizations/${ORDERER_DOMAIN}/orderers/${ORG}.${ORDERER_DOMAIN}/msp/config.yaml"

  infoln "Generating the orderer-tls certificates, use --csr.hosts to specify Subject Alternative Names"
  set -x
  fabric-ca-client enroll -u https://${CA_ORDERER_USERNAME}:${CA_ORDERER_PASSWORD}@localhost:${CA_SERVER_PORT} --caname ca-${ORG} -M "${PWD}/organizations/ordererOrganizations/${ORDERER_DOMAIN}/orderers/${ORG}.${ORDERER_DOMAIN}/tls" --enrollment.profile tls --csr.hosts ${ORG}.${ORDERER_DOMAIN} --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/${ORG}Org/ca-cert.pem"
  { set +x; } 2>/dev/null

  # Copy the tls CA cert, server cert, server keystore to well known file names in the orderer's tls directory that are referenced by orderer startup config
  cp "${PWD}/organizations/ordererOrganizations/${ORDERER_DOMAIN}/orderers/${ORG}.${ORDERER_DOMAIN}/tls/tlscacerts/"* "${PWD}/organizations/ordererOrganizations/${ORDERER_DOMAIN}/orderers/${ORG}.${ORDERER_DOMAIN}/tls/ca.crt"
  cp "${PWD}/organizations/ordererOrganizations/${ORDERER_DOMAIN}/orderers/${ORG}.${ORDERER_DOMAIN}/tls/signcerts/"* "${PWD}/organizations/ordererOrganizations/${ORDERER_DOMAIN}/orderers/${ORG}.${ORDERER_DOMAIN}/tls/server.crt"
  cp "${PWD}/organizations/ordererOrganizations/${ORDERER_DOMAIN}/orderers/${ORG}.${ORDERER_DOMAIN}/tls/keystore/"* "${PWD}/organizations/ordererOrganizations/${ORDERER_DOMAIN}/orderers/${ORG}.${ORDERER_DOMAIN}/tls/server.key"

  # Copy orderer org's CA cert to orderer's /msp/tlscacerts directory (for use in the orderer MSP definition)
  mkdir -p "${PWD}/organizations/ordererOrganizations/${ORDERER_DOMAIN}/orderers/${ORG}.${ORDERER_DOMAIN}/msp/tlscacerts"
  cp "${PWD}/organizations/ordererOrganizations/${ORDERER_DOMAIN}/orderers/${ORG}.${ORDERER_DOMAIN}/tls/tlscacerts/"* "${PWD}/organizations/ordererOrganizations/${ORDERER_DOMAIN}/orderers/${ORG}.${ORDERER_DOMAIN}/msp/tlscacerts/tlsca.${ORDERER_DOMAIN}-cert.pem"

  infoln "Generating the admin msp"
  set -x
  fabric-ca-client enroll -u https://${CA_ADMIN_USERNAME}:${CA_ADMIN_PASSWORD}@localhost:${CA_SERVER_PORT} --caname ca-${ORG} -M "${PWD}/organizations/ordererOrganizations/${ORDERER_DOMAIN}/users/Admin@${ORDERER_DOMAIN}/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/${ORG}Org/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/ordererOrganizations/${ORDERER_DOMAIN}/msp/config.yaml" "${PWD}/organizations/ordererOrganizations/${ORDERER_DOMAIN}/users/Admin@${ORDERER_DOMAIN}/msp/config.yaml"
}
