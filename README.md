# dutychain-backend


## Steps:

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

### 6. Deploy Chaincode
```
./network.sh deployCC -c mychannel -ccn ledger -ccp ../chaincode/ledger-doctype/ -ccl javascript -p ./config.json -ccep "OR('Org1MSP.peer','Org2MSP.peer','Org3MSP.peer')" 
```

## CleanUps
```
./network.sh down -p ./config.json
```