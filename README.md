# dutychain-backend


## Steps:
### 0. set /etc/hosts
add peer domain, ca domain and orderer domain to /etc/hosts

Example:
Machine 1(192.168.241.142): Org1, Org2, Orderer
Machine 2(192.168.241.145): Org3
```
192.168.241.142 peer0.org1.example.com
192.168.241.142 peer0.org2.example.com
192.168.241.145 peer0.org3.example.com
192.168.241.145 ca.org3.example.com
192.168.241.142 ca.org2.example.com
192.168.241.142 ca.org1.example.com
192.168.241.142 orderer.example.com
```

### 1. Setup config.json

### 2. Generate Docker config files
```
./configFile-generate.sh ./config.json
```

### 3. Setup configtx/configtx.yaml

### 4. Setup compose/compose-test-net.yaml
* modify the <B>volume</B> part
* modify the <B>depends_on</B> part

### 5. Start the network
```
./network.sh up createChannel -c mychannel -s couchdb -ca -p ./config.json
```

### 6. Copy certificates

#### 6.1 machine with orderer
copy the following non-local organizations certifiates from the following directory to the same directory in machine with orderer:
``` 
/dutychain-backend/hyperledger/test-network/organizations/peerOrganizations/<Domain Name>/msp
```

Documents needed to copy:
* File <B>config.yaml</B>
* Directory <B>cacerts/</B>
* Directory <B>tlscacerts/</B>

Example [In machine with orderer]:
```
scp config.yaml username@192.168.241.142:/home/makhead/dutychain-backend/hyperledger/test-network/organizations/peerOrganizations/org3.example.com/msp

scp -r cacerts/ username@192.168.241.142:/home/makhead/dutychain-backend/hyperledger/test-network/organizations/peerOrganizations/org3.example.com/msp

scp -r tlscacerts/ username@192.168.241.142:/home/makhead/dutychain-backend/hyperledger/test-network/organizations/peerOrganizations/org3.example.com/msp
```

#### 6.2 machine with orderer

copy the following orderer certifiates from the following directory to the same directory in machine without orderer:
``` 
/dutychain-backend/hyperledger/test-network/organizations/ordererOrganizations/<Orderer Domain Name>/
```

Documents needed to copy:
* Directory <B>tlsca/</B>

Example [In machine without orderer]:
```
scp -r tlsca/ username@192.168.241.145:/home/makhead/dutychain-backend/hyperledger/test-network/organizations/ordererOrganizations/example.com
```

### 7. Press Enter to continue the script

### 8. Deploy Chaincode
```
./network.sh deployCC -c mychannel -ccn ledger -ccp ../chaincode/ledger-doctype/ -ccl javascript -p ./config.json -ccep "OR('Org1MSP.peer','Org2MSP.peer','Org3MSP.peer')" 
```

## CleanUps
```
./network.sh down -p ./config.json
```