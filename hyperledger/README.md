# hyperledger network

## Run the application

### create channel
```
./network.sh up createChannel -c mychannel -s couchdb -ca
```

### deploy smart contract
```
./network.sh deployCC -ccn ledger -ccp ../chaincode/ledger-doctype/ -ccl javascript -ccep "OR('Org1MSP.peer','Org2MSP.peer')"
```

### view peer log
```
docker logs peer0.org1.example.com  2>&1 | grep "CouchDB index"
```

### view components in test network
```
docker ps -a
```

## cleanup
shutdown hyperledger node
```
cd test-network
./network down
```

remove local wallet
```
cd app/blockchain/
rm -rf wallet
```


# APIs

## init
initialize the ledger, must call this first before calling any other API

<B>No parameters are required</B>

Example:
```bash
$ curl --header "Content-Type: application/json" --request POST localhost:7001/debug/init
```
<img src="../img/debug.png">

## readall
Get all assets in the network

<B>No paramters are required</B>

Example:
```bash
curl --header "Content-Type: application/json" --request POST localhost:7001/debug/readall
```
<img src="../img/readall.png">

## create
add an asset to the hyperledger network

<B>required to have the following fields in the input JSON:</B>
* id: string
* type: string
* data: JSON

Example:
<img src="../img/create.png">

## read
Get the asset with the given ID in the network

<B>required to have the following fields in the input JSON:</B>
* id: string

Example:
```bash
curl --header "Content-Type: application/json" --request POST --data '{"id":"1"}'  localhost:7001/debug/read
```
<img src="../img/read.png">