# dutychain-backend


## Steps:
### 0. set /etc/hosts
add peer domain, ca domain and orderer domain to /etc/hosts

Example:
Machine 1(192.168.241.142): OrgA, OrgB, Orderer
Machine 2(192.168.241.145): OrgC

Domain Example:
OrgA: orgA.example.com
OrgB: orgB.example.com
OrgC: orgC.example.com
Orderer: example.com
```
192.168.241.142 peer0.orgA.example.com
192.168.241.142 peer0.orgB.example.com
192.168.241.145 peer0.orgC.example.com
192.168.241.142 ca.orgA.example.com
192.168.241.142 ca.orgB.example.com
192.168.241.145 ca.orgC.example.com
192.168.241.142 orderer.example.com
```

### 1. Setup config.json
The following fields can be set arbitrarily:

* isDeployOrderer
* PROFILE
* orderer.DOMAIN
* orderer.IP_ADDR
* peers.NAME
* peers.DOMAIN
* peers.IP_ADDR

### 2. Generate Docker config files
```
./configFile-generate.sh ./config.json
```

### 3. Setup configtx/configtx.yaml

### 4. Start the network
```
./network.sh up createChannel -c mychannel -p ./config.json
```

### 5. Copy certificates

#### 5.1 Copy certificates to machine with orderer
copy the following non-local organizations certifiates from the following directory to the same directory in machine with orderer:
``` 
mkdir -p /dutychain-backend/hyperledger/test-network/organizations/peerOrganizations/orgC.example.com/msp
```

Documents needed to copy:
* File <B>config.yaml</B>
* Directory <B>cacerts/</B>
* Directory <B>tlscacerts/</B>

Example [In machine without orderer]:
```
scp config.yaml username@192.168.241.142:/home/makhead/dutychain-backend/hyperledger/test-network/organizations/peerOrganizations/orgC.example.com/msp

scp -r cacerts/ username@192.168.241.142:/home/makhead/dutychain-backend/hyperledger/test-network/organizations/peerOrganizations/orgC.example.com/msp

scp -r tlscacerts/ username@192.168.241.142:/home/makhead/dutychain-backend/hyperledger/test-network/organizations/peerOrganizations/orgC.example.com/msp
```

#### 5.2 Copy certificates to machine without orderer

copy the following orderer certifiates from the following directory to the same directory in machine without orderer:
``` 
mkdir -p /dutychain-backend/hyperledger/test-network/organizations/ordererOrganizations/example.com/
```

Documents needed to copy:
* Directory <B>tlsca/</B>

Example [In machine with orderer]:
```
scp -r tlsca/ username@192.168.241.145:/home/makhead/dutychain-backend/hyperledger/test-network/organizations/ordererOrganizations/example.com
```

### 6. Press Enter to continue the script

### 7. Deploy Chaincode
```
./network.sh deployCC -c mychannel -ccn ledger -ccp ../chaincode/ledger-doctype/ -ccl javascript -p ./config.json -ccep "OR('OrgAMSP.peer','OrgBMSP.peer','OrgCMSP.peer')" 
```

## CleanUps
```
./network.sh down -p ./config.json
```