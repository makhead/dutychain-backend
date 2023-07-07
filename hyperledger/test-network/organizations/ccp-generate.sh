#!/bin/bash

function one_line_pem {
    echo "`awk 'NF {sub(/\\n/, ""); printf "%s\\\\\\\n",$0;}' $1`"
}

function json_ccp {
    local PP=$(one_line_pem $4)
    local CP=$(one_line_pem $5)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${P0PORT}/$2/" \
        -e "s/\${CAPORT}/$3/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        -e "s#\${DOMAIN}#$$6#" \
        -e "s#\${IP_ADDR}#$$7#" \
        organizations/ccp-template.json
}

function yaml_ccp {
    local PP=$(one_line_pem $4)
    local CP=$(one_line_pem $5)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${P0PORT}/$2/" \
        -e "s/\${CAPORT}/$3/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        -e "s#\${DOMAIN}#$6#" \
        -e "s#\${IP_ADDR}#$7#" \
        organizations/ccp-template.yaml | sed -e $'s/\\\\n/\\\n          /g'
}

# ORG=1
# P0PORT=7051
# CAPORT=7054
ORG=$1
DOMAIN=$2
P0PORT=$3
CAPORT=$4
IP_ADDR=$5
PEERPEM=organizations/peerOrganizations/${DOMAIN}/tlsca/tlsca.${DOMAIN}-cert.pem
CAPEM=organizations/peerOrganizations/${DOMAIN}/ca/ca.${DOMAIN}-cert.pem

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM $DOMAIN $IP_ADDR)" > organizations/peerOrganizations/${DOMAIN}/connection-org${ORG}.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM $DOMAIN $IP_ADDR)" > organizations/peerOrganizations/${DOMAIN}/connection-org${ORG}.yaml
