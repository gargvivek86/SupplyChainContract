export PATH=${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}/../config/
export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export ORDERER_ADDRESS=localhost:7050
export CORE_PEER_TLS_ROOTCERT_FILE_ORG1=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_TLS_ROOTCERT_FILE_ORG2=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt

CHANNEL_NAME="mychannel"
CHAINCODE_NAME="SupplyChainContract"
CHAINCODE_VERSION="1"
CHAINCODE_PATH="../../eclipse-workspace/SupplyChainContract/lib/build/install/lib"
CHAINCODE_LANG="java"

CHAINCODE_LABEL="SupplyChainContract_1"

setEnvVarsForPeer0Org1() {
    export CORE_PEER_LOCALMSPID="Org1MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=${CORE_PEER_TLS_ROOTCERT_FILE_ORG1}
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
}

setEnvVarsForPeer0Org2() {
    export CORE_PEER_LOCALMSPID="Org2MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$CORE_PEER_TLS_ROOTCERT_FILE_ORG2
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
    export CORE_PEER_ADDRESS=localhost:9051

}

packageChaincode() {
    echo "===================== Started to package the Chaincode on peer0.org1 ===================== "
    rm -rf ${CHAINCODE_NAME}.tar.gz
    setEnvVarsForPeer0Org1
    peer lifecycle chaincode package ${CHAINCODE_NAME}.tar.gz --path ${CHAINCODE_PATH} --lang ${CHAINCODE_LANG} --label ${CHAINCODE_LABEL}
    echo "===================== Chaincode is packaged on peer0.org1 ===================== "
}

installChaincode() {
    echo "===================== Started to Install Chaincode on peer0.org1 ===================== "
    setEnvVarsForPeer0Org1
    peer lifecycle chaincode install ${CHAINCODE_NAME}.tar.gz --peerAddresses $CORE_PEER_ADDRESS --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG1
    echo "===================== Chaincode is installed on peer0.org1 ===================== "
    
    echo "===================== Started to Install Chaincode on peer0.org2 ===================== "
    setEnvVarsForPeer0Org2
    peer lifecycle chaincode install ${CHAINCODE_NAME}.tar.gz --peerAddresses $CORE_PEER_ADDRESS --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG2
    echo "===================== Chaincode is installed on peer0.org2 ===================== "
}

queryInstalled() {
    echo "===================== Started to Query Installed Chaincode on peer0.org1 ===================== "
    setEnvVarsForPeer0Org1
    peer lifecycle chaincode queryinstalled --peerAddresses $CORE_PEER_ADDRESS --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG1 >&log.txt
    cat log.txt
    PACKAGE_ID=$(sed -n "/${CHAINCODE_LABEL}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)
    echo PackageID is ${PACKAGE_ID}
    echo "===================== Query installed successful on peer0.org1 ===================== "
}

approveForMyOrg1() {
    echo "===================== Started to approve chaincode definition from org 1 ===================== "
    setEnvVarsForPeer0Org1
    peer lifecycle chaincode approveformyorg -o $ORDERER_ADDRESS --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA --channelID ${CHANNEL_NAME} --name ${CHAINCODE_NAME} --version ${CHAINCODE_VERSION} --init-required --package-id ${PACKAGE_ID} --sequence 1

    echo "===================== chaincode approved from org 1 ===================== "

}

checkCommitReadynessForOrg1() {
    echo "===================== Started to check commit readyness from org 1 ===================== "
    setEnvVarsForPeer0Org1
    peer lifecycle chaincode checkcommitreadiness --channelID ${CHANNEL_NAME} --name ${CHAINCODE_NAME} --version ${CHAINCODE_VERSION} --sequence 1 --output json --init-required
    echo "===================== checking commit readyness from org 1 ===================== "
}

approveForMyOrg2() {
    echo "===================== Started to approve chaincode definition from org 2 ===================== "
    setEnvVarsForPeer0Org2
    peer lifecycle chaincode approveformyorg -o $ORDERER_ADDRESS --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA --channelID ${CHANNEL_NAME} --name ${CHAINCODE_NAME} --version ${CHAINCODE_VERSION} --init-required --package-id ${PACKAGE_ID} --sequence 1
    echo "===================== chaincode approved from org 2 ===================== "
}

checkCommitReadynessForOrg2() {
    echo "===================== Started to check commit readyness from org 2 ===================== "
    setEnvVarsForPeer0Org2
    peer lifecycle chaincode checkcommitreadiness --channelID ${CHANNEL_NAME} --name ${CHAINCODE_NAME} --version ${CHAINCODE_VERSION} --sequence 1 --output json --init-required
    echo "===================== checking commit readyness from org 1 ===================== "
}

commitChaincodeDefination() {
    echo "===================== Started to commit Chaincode definition on channel ===================== "
    setEnvVarsForPeer0Org1
    peer lifecycle chaincode commit -o $ORDERER_ADDRESS --ordererTLSHostnameOverride orderer.example.com --tls $CORE_PEER_TLS_ENABLED\
    --cafile $ORDERER_CA --channelID ${CHANNEL_NAME} --name ${CHAINCODE_NAME}\
    --peerAddresses localhost:7051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG1\
    --peerAddresses localhost:9051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG2\
    --version ${CHAINCODE_VERSION} --sequence 1 --init-required
    echo "===================== Chaincode definition committed on channel ===================== "
}

queryCommitted() {
    echo "===================== Started to query commintted chaincode definition on channel ===================== "
    setEnvVarsForPeer0Org1
    peer lifecycle chaincode querycommitted --channelID ${CHANNEL_NAME} --name ${CHAINCODE_NAME}
    echo "===================== Queried the chaincode definition committed on channel ===================== "

}

chaincodeInvokeInit() {
    echo "===================== Started to Initilize chaincode===================== "
    setEnvVarsForPeer0Org1

    peer chaincode invoke -o $ORDERER_ADDRESS\
    --ordererTLSHostnameOverride orderer.example.com --tls $CORE_PEER_TLS_ENABLED\
    --cafile $ORDERER_CA -C ${CHANNEL_NAME} --name ${CHAINCODE_NAME}\
    --peerAddresses localhost:7051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG1\
    --peerAddresses localhost:9051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG2\
    --isInit -c '{"Args":[]}'
    echo "===================== Succesfully Initilized the chaincode===================== "
}

chaincodeAddProduct() {
    echo "===================== Started Add Asset Chaincode Function===================== "
    setEnvVarsForPeer0Org1
    peer chaincode invoke -o $ORDERER_ADDRESS\
    --ordererTLSHostnameOverride orderer.example.com --tls $CORE_PEER_TLS_ENABLED\
    --cafile $ORDERER_CA -C ${CHANNEL_NAME} --name ${CHAINCODE_NAME}\
    --peerAddresses localhost:7051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG1\
    --peerAddresses localhost:9051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG2\
	-c '{"Args":["addProduct", "1", "Apple","John"]}'
    echo "===================== Successfully Added Product Asset===================== "
}
chaincodeAddDistributor() {
    echo "===================== Started Add distributor Chaincode Function===================== "
    setEnvVarsForPeer0Org1
    peer chaincode invoke -o $ORDERER_ADDRESS\
    --ordererTLSHostnameOverride orderer.example.com --tls $CORE_PEER_TLS_ENABLED\
    --cafile $ORDERER_CA -C ${CHANNEL_NAME} --name ${CHAINCODE_NAME}\
    --peerAddresses localhost:7051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG1\
    --peerAddresses localhost:9051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG2\
	-c '{"Args":["recordProductMovement", "1", "distributor","Sandeep"]}'
    echo "===================== Successfully Added Product distributor===================== "
}
chaincodeAddRetailer() {
    echo "===================== Started Add retailer Chaincode Function===================== "
    setEnvVarsForPeer0Org1
    peer chaincode invoke -o $ORDERER_ADDRESS\
    --ordererTLSHostnameOverride orderer.example.com --tls $CORE_PEER_TLS_ENABLED\
    --cafile $ORDERER_CA -C ${CHANNEL_NAME} --name ${CHAINCODE_NAME}\
    --peerAddresses localhost:7051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG1\
    --peerAddresses localhost:9051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG2\
	-c '{"Args":["recordProductMovement", "1", "retailer","Mukesh"]}'
    echo "===================== Successfully Added Product retailer===================== "
}
chaincodeAddConsumer() {
    echo "===================== Started Add consumer Chaincode Function===================== "
    setEnvVarsForPeer0Org1
    peer chaincode invoke -o $ORDERER_ADDRESS\
    --ordererTLSHostnameOverride orderer.example.com --tls $CORE_PEER_TLS_ENABLED\
    --cafile $ORDERER_CA -C ${CHANNEL_NAME} --name ${CHAINCODE_NAME}\
    --peerAddresses localhost:7051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG1\
    --peerAddresses localhost:9051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG2\
	-c '{"Args":["recordProductMovement", "1", "consumer","Joe"]}'
    echo "===================== Successfully Added Product consumer===================== "
}
chaincodequeryProductById() {
    echo "===================== Started Query Product Details Chaincode Function===================== "
    setEnvVarsForPeer0Org1
    peer chaincode invoke -o $ORDERER_ADDRESS\
    --ordererTLSHostnameOverride orderer.example.com --tls $CORE_PEER_TLS_ENABLED\
    --cafile $ORDERER_CA -C ${CHANNEL_NAME} --name ${CHAINCODE_NAME}\
    --peerAddresses localhost:7051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG1\
    --peerAddresses localhost:9051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG2\
	-c '{"Args":["queryProductByID", "1"]}'
    echo "===================== Successfully Invoked Query Product Details Chaincode Function===================== "
}

packageChaincode
installChaincode
queryInstalled
approveForMyOrg1
checkCommitReadynessForOrg1
approveForMyOrg2
checkCommitReadynessForOrg2
commitChaincodeDefination
queryCommitted
sleep 5

chaincodeInvokeInit
sleep 5
chaincodeAddProduct
sleep 5
chaincodeAddDistributor
sleep 15
chaincodeAddRetailer
sleep 15
chaincodeAddConsumer
sleep 15
chaincodequeryProductById
export PATH=${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}/../config/
export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export ORDERER_ADDRESS=localhost:7050
export CORE_PEER_TLS_ROOTCERT_FILE_ORG1=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_TLS_ROOTCERT_FILE_ORG2=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt

CHANNEL_NAME="mychannel"
CHAINCODE_NAME="SupplyChainContract"
CHAINCODE_VERSION="1"
CHAINCODE_PATH="../../eclipse-workspace/SupplyChainContract/lib/build/install/lib"
CHAINCODE_LANG="java"

CHAINCODE_LABEL="SupplyChainContract_1"

setEnvVarsForPeer0Org1() {
    export CORE_PEER_LOCALMSPID="Org1MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=${CORE_PEER_TLS_ROOTCERT_FILE_ORG1}
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
}

setEnvVarsForPeer0Org2() {
    export CORE_PEER_LOCALMSPID="Org2MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$CORE_PEER_TLS_ROOTCERT_FILE_ORG2
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
    export CORE_PEER_ADDRESS=localhost:9051

}

packageChaincode() {
    echo "===================== Started to package the Chaincode on peer0.org1 ===================== "
    rm -rf ${CHAINCODE_NAME}.tar.gz
    setEnvVarsForPeer0Org1
    peer lifecycle chaincode package ${CHAINCODE_NAME}.tar.gz --path ${CHAINCODE_PATH} --lang ${CHAINCODE_LANG} --label ${CHAINCODE_LABEL}
    echo "===================== Chaincode is packaged on peer0.org1 ===================== "
}

installChaincode() {
    echo "===================== Started to Install Chaincode on peer0.org1 ===================== "
    setEnvVarsForPeer0Org1
    peer lifecycle chaincode install ${CHAINCODE_NAME}.tar.gz --peerAddresses $CORE_PEER_ADDRESS --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG1
    echo "===================== Chaincode is installed on peer0.org1 ===================== "
    
    echo "===================== Started to Install Chaincode on peer0.org2 ===================== "
    setEnvVarsForPeer0Org2
    peer lifecycle chaincode install ${CHAINCODE_NAME}.tar.gz --peerAddresses $CORE_PEER_ADDRESS --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG2
    echo "===================== Chaincode is installed on peer0.org2 ===================== "
}

queryInstalled() {
    echo "===================== Started to Query Installed Chaincode on peer0.org1 ===================== "
    setEnvVarsForPeer0Org1
    peer lifecycle chaincode queryinstalled --peerAddresses $CORE_PEER_ADDRESS --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG1 >&log.txt
    cat log.txt
    PACKAGE_ID=$(sed -n "/${CHAINCODE_LABEL}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)
    echo PackageID is ${PACKAGE_ID}
    echo "===================== Query installed successful on peer0.org1 ===================== "
}

approveForMyOrg1() {
    echo "===================== Started to approve chaincode definition from org 1 ===================== "
    setEnvVarsForPeer0Org1
    peer lifecycle chaincode approveformyorg -o $ORDERER_ADDRESS --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA --channelID ${CHANNEL_NAME} --name ${CHAINCODE_NAME} --version ${CHAINCODE_VERSION} --init-required --package-id ${PACKAGE_ID} --sequence 1

    echo "===================== chaincode approved from org 1 ===================== "

}

checkCommitReadynessForOrg1() {
    echo "===================== Started to check commit readyness from org 1 ===================== "
    setEnvVarsForPeer0Org1
    peer lifecycle chaincode checkcommitreadiness --channelID ${CHANNEL_NAME} --name ${CHAINCODE_NAME} --version ${CHAINCODE_VERSION} --sequence 1 --output json --init-required
    echo "===================== checking commit readyness from org 1 ===================== "
}

approveForMyOrg2() {
    echo "===================== Started to approve chaincode definition from org 2 ===================== "
    setEnvVarsForPeer0Org2
    peer lifecycle chaincode approveformyorg -o $ORDERER_ADDRESS --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA --channelID ${CHANNEL_NAME} --name ${CHAINCODE_NAME} --version ${CHAINCODE_VERSION} --init-required --package-id ${PACKAGE_ID} --sequence 1
    echo "===================== chaincode approved from org 2 ===================== "
}

checkCommitReadynessForOrg2() {
    echo "===================== Started to check commit readyness from org 2 ===================== "
    setEnvVarsForPeer0Org2
    peer lifecycle chaincode checkcommitreadiness --channelID ${CHANNEL_NAME} --name ${CHAINCODE_NAME} --version ${CHAINCODE_VERSION} --sequence 1 --output json --init-required
    echo "===================== checking commit readyness from org 1 ===================== "
}

commitChaincodeDefination() {
    echo "===================== Started to commit Chaincode definition on channel ===================== "
    setEnvVarsForPeer0Org1
    peer lifecycle chaincode commit -o $ORDERER_ADDRESS --ordererTLSHostnameOverride orderer.example.com --tls $CORE_PEER_TLS_ENABLED\
    --cafile $ORDERER_CA --channelID ${CHANNEL_NAME} --name ${CHAINCODE_NAME}\
    --peerAddresses localhost:7051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG1\
    --peerAddresses localhost:9051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG2\
    --version ${CHAINCODE_VERSION} --sequence 1 --init-required
    echo "===================== Chaincode definition committed on channel ===================== "
}

queryCommitted() {
    echo "===================== Started to query commintted chaincode definition on channel ===================== "
    setEnvVarsForPeer0Org1
    peer lifecycle chaincode querycommitted --channelID ${CHANNEL_NAME} --name ${CHAINCODE_NAME}
    echo "===================== Queried the chaincode definition committed on channel ===================== "

}

chaincodeInvokeInit() {
    echo "===================== Started to Initilize chaincode===================== "
    setEnvVarsForPeer0Org1

    peer chaincode invoke -o $ORDERER_ADDRESS\
    --ordererTLSHostnameOverride orderer.example.com --tls $CORE_PEER_TLS_ENABLED\
    --cafile $ORDERER_CA -C ${CHANNEL_NAME} --name ${CHAINCODE_NAME}\
    --peerAddresses localhost:7051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG1\
    --peerAddresses localhost:9051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG2\
    --isInit -c '{"Args":[]}'
    echo "===================== Succesfully Initilized the chaincode===================== "
}

chaincodeAddProduct() {
    echo "===================== Started Add Asset Chaincode Function===================== "
    setEnvVarsForPeer0Org1
    peer chaincode invoke -o $ORDERER_ADDRESS\
    --ordererTLSHostnameOverride orderer.example.com --tls $CORE_PEER_TLS_ENABLED\
    --cafile $ORDERER_CA -C ${CHANNEL_NAME} --name ${CHAINCODE_NAME}\
    --peerAddresses localhost:7051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG1\
    --peerAddresses localhost:9051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG2\
	-c '{"Args":["addProduct", "1", "Apple","John"]}'
    echo "===================== Successfully Added Product Asset===================== "
}
chaincodeAddDistributor() {
    echo "===================== Started Add distributor Chaincode Function===================== "
    setEnvVarsForPeer0Org1
    peer chaincode invoke -o $ORDERER_ADDRESS\
    --ordererTLSHostnameOverride orderer.example.com --tls $CORE_PEER_TLS_ENABLED\
    --cafile $ORDERER_CA -C ${CHANNEL_NAME} --name ${CHAINCODE_NAME}\
    --peerAddresses localhost:7051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG1\
    --peerAddresses localhost:9051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG2\
	-c '{"Args":["recordProductMovement", "1", "distributor","Sandeep"]}'
    echo "===================== Successfully Added Product distributor===================== "
}
chaincodeAddRetailer() {
    echo "===================== Started Add retailer Chaincode Function===================== "
    setEnvVarsForPeer0Org1
    peer chaincode invoke -o $ORDERER_ADDRESS\
    --ordererTLSHostnameOverride orderer.example.com --tls $CORE_PEER_TLS_ENABLED\
    --cafile $ORDERER_CA -C ${CHANNEL_NAME} --name ${CHAINCODE_NAME}\
    --peerAddresses localhost:7051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG1\
    --peerAddresses localhost:9051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG2\
	-c '{"Args":["recordProductMovement", "1", "retailer","Mukesh"]}'
    echo "===================== Successfully Added Product retailer===================== "
}
chaincodeAddConsumer() {
    echo "===================== Started Add consumer Chaincode Function===================== "
    setEnvVarsForPeer0Org1
    peer chaincode invoke -o $ORDERER_ADDRESS\
    --ordererTLSHostnameOverride orderer.example.com --tls $CORE_PEER_TLS_ENABLED\
    --cafile $ORDERER_CA -C ${CHANNEL_NAME} --name ${CHAINCODE_NAME}\
    --peerAddresses localhost:7051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG1\
    --peerAddresses localhost:9051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG2\
	-c '{"Args":["recordProductMovement", "1", "consumer","Joe"]}'
    echo "===================== Successfully Added Product consumer===================== "
}
chaincodequeryProductById() {
    echo "===================== Started Query Product Details Chaincode Function===================== "
    setEnvVarsForPeer0Org1
    peer chaincode invoke -o $ORDERER_ADDRESS\
    --ordererTLSHostnameOverride orderer.example.com --tls $CORE_PEER_TLS_ENABLED\
    --cafile $ORDERER_CA -C ${CHANNEL_NAME} --name ${CHAINCODE_NAME}\
    --peerAddresses localhost:7051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG1\
    --peerAddresses localhost:9051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG2\
	-c '{"Args":["queryProductByID", "1"]}'
    echo "===================== Successfully Invoked Query Product Details Chaincode Function===================== "
}

packageChaincode
installChaincode
queryInstalled
approveForMyOrg1
checkCommitReadynessForOrg1
approveForMyOrg2
checkCommitReadynessForOrg2
commitChaincodeDefination
queryCommitted
sleep 5

chaincodeInvokeInit
sleep 5
chaincodeAddProduct
sleep 5
chaincodeAddDistributor
sleep 15
chaincodeAddRetailer
sleep 15
chaincodeAddConsumer
sleep 15
chaincodequeryProductById
