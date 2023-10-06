# 注册 TLS CA 管理员，注册节点身份

##  注册 TLS CA 管理员

```bash
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/tls-ca/crypto/tls-ca-cert.pem
export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/tls-ca/admin

cp tls-ca/crypto/ca-cert.pem tls-ca/crypto/tls-ca-cert.pem
# 登陆管理员用户
fabric-ca-client enroll -d -u https://tls-ca-admin:tls-ca-adminpw@0.0.0.0:7052
```

## 注册 org1 的两个 peer 节点
```bash
fabric-ca-client register -d --id.name peer0.org1.example.com --id.secret peer1PW --id.type peer -u https://0.0.0.0:7052
fabric-ca-client register -d --id.name peer1.org1.example.com --id.secret peer2PW --id.type peer -u https://0.0.0.0:7052
```



## 注册 org2 的两个 peer 节点：
```bash
fabric-ca-client register -d --id.name peer0.org2.example.com --id.secret peer1PW --id.type peer -u https://0.0.0.0:7052
fabric-ca-client register -d --id.name peer1.org2.example.com --id.secret peer2PW --id.type peer -u https://0.0.0.0:7052
```



## 注册 3 个 orderer 节点：
```bash
fabric-ca-client register -d --id.name orderer0.example.com --id.secret ordererPW --id.type orderer -u https://0.0.0.0:7052
fabric-ca-client register -d --id.name orderer1.example.com --id.secret ordererPW --id.type orderer -u https://0.0.0.0:7052
fabric-ca-client register -d --id.name orderer2.example.com --id.secret ordererPW --id.type orderer -u https://0.0.0.0:7052
```

# 注册订购者组织的CA管理员

Enroll Orderer Org’s CA Admin

## register orderer1 节点 & org0管理员

```bash
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org0/ca/crypto/ca-cert.pem
export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org0/ca/admin

fabric-ca-client enroll -d -u https://rca-org0-admin:rca-org0-adminpw@0.0.0.0:7053
fabric-ca-client register -d --id.name orderer0.example.com --id.secret ordererpw --id.type orderer -u https://0.0.0.0:7053
fabric-ca-client register -d --id.name admin-org0 --id.secret org0adminpw --id.type admin --id.attrs "hf.Registrar.Roles=*,hf.Registrar.DelegateRoles=*,hf.AffiliationMgr=true,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert" -u https://0.0.0.0:7053
```

## register orderer2 节点
```bash
fabric-ca-client register -d --id.name orderer1.example.com --id.secret ordererpw --id.type orderer -u https://0.0.0.0:7053
```



## register orderer3 节点
```bash
fabric-ca-client register -d --id.name orderer2.example.com --id.secret ordererpw --id.type orderer -u https://0.0.0.0:7053
```



## Enroll Org1’s CA Admin
```bash
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org1/ca/crypto/ca-cert.pem
export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org1/ca/admin
fabric-ca-client enroll -d -u https://rca-org1-admin:rca-org1-adminpw@0.0.0.0:7054
fabric-ca-client register -d --id.name peer0.org1.example.com --id.secret peer1PW --id.type peer -u https://0.0.0.0:7054
fabric-ca-client register -d --id.name peer1.org1.example.com --id.secret peer2PW --id.type peer -u https://0.0.0.0:7054
fabric-ca-client register -d --id.name admin-org1 --id.secret org1AdminPW --id.type admin --id.attrs "hf.Registrar.Roles=*,hf.Registrar.DelegateRoles=*,hf.AffiliationMgr=true,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert" -u https://0.0.0.0:7054
fabric-ca-client register -d --id.name user-org1 --id.secret org1UserPW --id.type user -u https://0.0.0.0:7054
```



## Enroll Org2’s CA Admin
```bash
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org2/ca/crypto/ca-cert.pem
export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org2/ca/admin
fabric-ca-client enroll -d -u https://rca-org2-admin:rca-org2-adminpw@0.0.0.0:7055
fabric-ca-client register -d --id.name peer0.org2.example.com --id.secret peer1PW --id.type peer -u https://0.0.0.0:7055
fabric-ca-client register -d --id.name peer1.org2.example.com --id.secret peer2PW --id.type peer -u https://0.0.0.0:7055
fabric-ca-client register -d --id.name admin-org2 --id.secret org2AdminPW --id.type admin --id.attrs "hf.Registrar.Roles=*,hf.Registrar.DelegateRoles=*,hf.AffiliationMgr=true,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert" -u https://0.0.0.0:7055
fabric-ca-client register -d --id.name user-org2 --id.secret org2UserPW --id.type user -u https://0.0.0.0:7055
```

# Enroll Org1’s Peers
## Enroll Org1 Peer1
### Enroll Org1 Peer1 ECert 证书

```bash
mkdir -p org1/peer1/assets/ca/ && cp org1/ca/crypto/ca-cert.pem org1/peer1/assets/ca/org1-ca-cert.pem
export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org1/peer1
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org1/peer1/assets/ca/org1-ca-cert.pem
export FABRIC_CA_CLIENT_MSPDIR=msp

fabric-ca-client enroll -d -u https://peer0.org1.example.com:peer1PW@0.0.0.0:7054

# 更改私钥文件名称
mv org1/peer1/msp/keystore/a67faab6408161858fdd3b47e15c843b1a434c56e858a9e8297cc785baf3584a_sk org1/peer1/msp/keystore/priv_sk
mkdir -p org1/peer1/msp/admincerts/
```



### Enroll Org1 Peer1 TLS 证书

```bash
mkdir -p org1/peer1/assets/tls-ca/ && cp tls-ca/crypto/tls-ca-cert.pem org1/peer1/assets/tls-ca/tls-ca-cert.pem

export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org1/peer1
export FABRIC_CA_CLIENT_MSPDIR=tls-msp
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org1/peer1/assets/tls-ca/tls-ca-cert.pem

fabric-ca-client enroll -d -u https://peer0.org1.example.com:peer1PW@0.0.0.0:7052 --enrollment.profile tls --csr.hosts peer0.org1.example.com

# 将 keystore 路径下的文件改名为 key.pem

mv org1/peer1/tls-msp/keystore/aaf9b81475bec962d18885ed0149153e649a35f0ddad1b0ad79b1821f8543d7a_sk org1/peer1/tls-msp/keystore/key.pem
```

## Enroll  Org1 Peer2

### Enroll Org1 Peer2 ECert 证书

```bash
mkdir -p org1/peer2/assets/ca/ && cp org1/ca/crypto/ca-cert.pem org1/peer2/assets/ca/org1-ca-cert.pem

export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org1/peer2
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org1/peer2/assets/ca/org1-ca-cert.pem
export FABRIC_CA_CLIENT_MSPDIR=msp

fabric-ca-client enroll -d -u https://peer1.org1.example.com:peer2PW@0.0.0.0:7054

# 修改私钥文件名称
mv org1/peer2/msp/keystore/1806bca5eea212234f29da781f6252ac1bcd28406665c729fee83ffe151e4872_sk org1/peer2/msp/keystore/priv_sk

mkdir -p org1/peer2/msp/admincerts/
```



### Enroll Org1 Peer1 TLS 证书

```bash
mkdir -p org1/peer2/assets/tls-ca/ && cp tls-ca/crypto/tls-ca-cert.pem org1/peer2/assets/tls-ca/tls-ca-cert.pem

export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org1/peer2
export FABRIC_CA_CLIENT_MSPDIR=tls-msp
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org1/peer2/assets/tls-ca/tls-ca-cert.pem

fabric-ca-client enroll -d -u https://peer1.org1.example.com:peer2PW@0.0.0.0:7052 --enrollment.profile tls --csr.hosts peer1.org1.example.com

# 将 keystore 路径下的文件改名为 key.pem

mv org1/peer2/tls-msp/keystore/d0bd003e131ef5f54696fb01f7c1a503e6534e455fe49cc7ae96a9ec9d548720_sk org1/peer2/tls-msp/keystore/key.pem
```



## Enroll Org1’s Admin

```bash
export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org1/admin
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org1/peer1/assets/ca/org1-ca-cert.pem
export FABRIC_CA_CLIENT_MSPDIR=msp
fabric-ca-client enroll -d -u https://admin-org1:org1AdminPW@0.0.0.0:7054

mv /tmp/hyperledger/org1/admin/msp/keystore/128af441b4d0178fed513c0b32b6b3b31c4441f7e12a7c0023a32ead9660cbc0_sk /tmp/hyperledger/org1/admin/msp/keystore/priv_sk

cp /tmp/hyperledger/org1/admin/msp/signcerts/cert.pem /tmp/hyperledger/org1/peer1/msp/admincerts/org1-admin-cert.pem

cp /tmp/hyperledger/org1/admin/msp/signcerts/cert.pem /tmp/hyperledger/org1/peer2/msp/admincerts/org1-admin-cert.pem

```

# Enroll Org2’s Peers

## Enroll Org2 Peer1

### Enroll Org2 Peer1 ECert 证书

```bash
mkdir -p org2/peer1/assets/ca/ && cp org2/ca/crypto/ca-cert.pem org2/peer1/assets/ca/org2-ca-cert.pem

export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org2/peer1
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org2/peer1/assets/ca/org2-ca-cert.pem
export FABRIC_CA_CLIENT_MSPDIR=msp

fabric-ca-client enroll -d -u https://peer0.org2.example.com:peer1PW@0.0.0.0:7055

# 修改私钥文件名称

mv org2/peer1/msp/keystore/c3b7264bd582ea0835da850c914a8586d8268d60b84bf094765cf422f40d0c4d_sk org2/peer1/msp/keystore/priv_sk
```



### Enroll Org2 Peer1 TLS 证书

```bash
mkdir org2/peer1/assets/tls-ca/ && cp tls-ca/crypto/tls-ca-cert.pem org2/peer1/assets/tls-ca/tls-ca-cert.pem

export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org2/peer1
export FABRIC_CA_CLIENT_MSPDIR=tls-msp
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org2/peer1/assets/tls-ca/tls-ca-cert.pem

fabric-ca-client enroll -d -u https://peer0.org2.example.com:peer1PW@0.0.0.0:7052 --enrollment.profile tls --csr.hosts peer0.org2.example.com

# 修改私钥文件名称

mv org2/peer1/tls-msp/keystore/72c9b468a4c0bd6be9fcdafbe317290e68dcc02e309528efc6bd2b8268dc23ea_sk org2/peer1/tls-msp/keystore/key.pem
```



## Enroll Org2 Peer2

### Enroll Org2 Peer2 ECert 证书

```bash
mkdir -p org2/peer2/assets/ca/ && cp org2/ca/crypto/ca-cert.pem org2/peer2/assets/ca/org2-ca-cert.pem

export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org2/peer2
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org2/peer2/assets/ca/org2-ca-cert.pem
export FABRIC_CA_CLIENT_MSPDIR=msp

fabric-ca-client enroll -d -u https://peer1.org2.example.com:peer2PW@0.0.0.0:7055

# 修改私钥文件名称

mv org2/peer2/msp/keystore/8e26c0476fc100e4b24859470342ab6728aa793cb952cf58c3de899db97cf235_sk org2/peer2/msp/keystore/priv_sk
```



### Enroll Org2 Peer2 TLS 证书

```bash
mkdir -p org2/peer2/assets/tls-ca/ && cp tls-ca/crypto/tls-ca-cert.pem org2/peer2/assets/tls-ca/tls-ca-cert.pem

export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org2/peer2
export FABRIC_CA_CLIENT_MSPDIR=tls-msp
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org2/peer2/assets/tls-ca/tls-ca-cert.pem

fabric-ca-client enroll -d -u https://peer1.org2.example.com:peer2PW@0.0.0.0:7052 --enrollment.profile tls --csr.hosts peer1.org2.example.com

# 修改私钥文件名称

mv org2/peer2/tls-msp/keystore/56399b6b27ac9c45538876e05ab6a9fa9ad7ace509f736794d72a0506d6f9e95_sk org2/peer2/tls-msp/keystore/key.pem
```



## Enroll Org2’s Admin

```bash
mkdir -p org2/peer1/msp/admincerts
mkdir -p org2/peer2/msp/admincerts

export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org2/admin
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org2/peer1/assets/ca/org2-ca-cert.pem
export FABRIC_CA_CLIENT_MSPDIR=msp

fabric-ca-client enroll -d -u https://admin-org2:org2AdminPW@0.0.0.0:7055

cp org2/admin/msp/signcerts/cert.pem org2/peer1/msp/admincerts/org2-admin-cert.pem

cp org2/admin/msp/signcerts/cert.pem org2/peer2/msp/admincerts/org2-admin-cert.pem
```



# Enroll Orderer

## Enroll Orderer1

### Enroll Orderer1 ECert 证书

```bash
mkdir -p org0/orderer1/assets/ca/ && cp org0/ca/crypto/ca-cert.pem org0/orderer1/assets/ca/org0-ca-cert.pem

export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org0/orderer1
export FABRIC_CA_CLIENT_MSPDIR=msp
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org0/orderer1/assets/ca/org0-ca-cert.pem

fabric-ca-client enroll -d -u https://orderer0.example.com:ordererpw@0.0.0.0:7053

mv org0/orderer1/msp/keystore/f3cd89d3c1dc5d50ecafd79a9adbb1893e210bfddfdb34fe8f4567ef68cb6711_sk org0/orderer1/msp/keystore/priv_sk
```



### Enroll Orderer1 TLS 证书

```bash
mkdir -p org0/orderer1/assets/tls-ca/ && cp tls-ca/crypto/tls-ca-cert.pem org0/orderer1/assets/tls-ca/tls-ca-cert.pem

export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org0/orderer1
export FABRIC_CA_CLIENT_MSPDIR=tls-msp
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org0/orderer1/assets/tls-ca/tls-ca-cert.pem

fabric-ca-client enroll -d -u https://orderer0.example.com:ordererPW@0.0.0.0:7052 --enrollment.profile tls --csr.hosts 'orderer0.example.com,orderer0,192.169.0.105'

mv org0/orderer1/tls-msp/keystore/20a197c83800b88f386380c1529a261510c9a495af1c82130bf5eb9219e2f779_sk org0/orderer1/tls-msp/keystore/key.pem
```



## Enroll Orderer2

### Enroll Orderer2 ECert 证书

```bash
mkdir -p org0/orderer2/assets/ca/ && cp org0/ca/crypto/ca-cert.pem org0/orderer2/assets/ca/org0-ca-cert.pem

export FABRIC_CA_CLIENT_MSPDIR=msp
export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org0/orderer2
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org0/orderer2/assets/ca/org0-ca-cert.pem

fabric-ca-client enroll -d -u https://orderer1.example.com:ordererpw@0.0.0.0:7053

mv org0/orderer2/msp/keystore/9bcaf6b220814d84ee5795eba0011e5d9d50847ea32cc3bb59c01bec84637f0d_sk org0/orderer2/msp/keystore/priv_sk
```



### Enroll Orderer2 TLS 证书

```bash
mkdir -p org0/orderer2/assets/tls-ca/ && cp tls-ca/crypto/tls-ca-cert.pem org0/orderer2/assets/tls-ca/tls-ca-cert.pem

export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org0/orderer2
export FABRIC_CA_CLIENT_MSPDIR=tls-msp
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org0/orderer2/assets/tls-ca/tls-ca-cert.pem

fabric-ca-client enroll -d -u https://orderer1.example.com:ordererPW@0.0.0.0:7052 --enrollment.profile tls --csr.hosts 'orderer1.example.com,orderer1,192.168.0.105'

mv org0/orderer2/tls-msp/keystore/3897003b80122b6a00bece411f7654d53427a70feda6e87491472d9a59d8cdd3_sk org0/orderer2/tls-msp/keystore/key.pem
```



## Enroll Orderer3

### Enroll Orderer3 ECert 证书

```bash
mkdir -p org0/orderer3/assets/ca/ && cp org0/ca/crypto/ca-cert.pem org0/orderer3/assets/ca/org0-ca-cert.pem

export FABRIC_CA_CLIENT_MSPDIR=msp
export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org0/orderer3
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org0/orderer3/assets/ca/org0-ca-cert.pem

fabric-ca-client enroll -d -u https://orderer2.example.com:ordererpw@0.0.0.0:7053

mv org0/orderer3/msp/keystore/89329b97bd748043133384841ef82376fc4768076d148e4c4bc6ccc142d71c89_sk org0/orderer3/msp/keystore/priv_sk
```



### Enroll Orderer3 TLS 证书

```bash
mkdir -p org0/orderer3/assets/tls-ca/ && cp tls-ca/crypto/tls-ca-cert.pem org0/orderer3/assets/tls-ca/tls-ca-cert.pem

export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org0/orderer3
export FABRIC_CA_CLIENT_MSPDIR=tls-msp
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org0/orderer3/assets/tls-ca/tls-ca-cert.pem

fabric-ca-client enroll -d -u https://orderer2.example.com:ordererPW@0.0.0.0:7052 --enrollment.profile tls --csr.hosts 'orderer2.example.com,orderer2,192.168.0.105'

mv org0/orderer3/tls-msp/keystore/db74c24fdb7e684432e7b4364b1d6fd0899dd92f69a7ce6aad9805d27719296f_sk org0/orderer3/tls-msp/keystore/key.pem
```



## Enroll Org0’s Admin

```bash
export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org0/admin
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org0/ca/crypto/ca-cert.pem
export FABRIC_CA_CLIENT_MSPDIR=msp

fabric-ca-client enroll -d -u https://admin-org0:org0adminpw@0.0.0.0:7053

mv /tmp/hyperledger/org0/admin/msp/keystore/ffa358cd67f599c8425a5e904c864d28bf8668a71300f65c4cc01d2dff346776_sk /tmp/hyperledger/org0/admin/msp/keystore/priv_sk

mkdir /tmp/hyperledger/org0/orderer1/msp/admincerts && cp /tmp/hyperledger/org0/admin/msp/signcerts/cert.pem /tmp/hyperledger/org0/orderer1/msp/admincerts/orderer-admin-cert.pem
mkdir /tmp/hyperledger/org0/orderer2/msp/admincerts && cp /tmp/hyperledger/org0/admin/msp/signcerts/cert.pem /tmp/hyperledger/org0/orderer2/msp/admincerts/orderer-admin-cert.pem
mkdir /tmp/hyperledger/org0/orderer3/msp/admincerts && cp /tmp/hyperledger/org0/admin/msp/signcerts/cert.pem /tmp/hyperledger/org0/orderer3/msp/admincerts/orderer-admin-cert.pem
```



# 构建 Orderer 本地 MSP 结构

## Orderer 1 Local MSP

```bash
mkdir -p crypto-config/ordererOrganizations/example.com/orderers/orderer0.example.com/msp
mkdir -p crypto-config/ordererOrganizations/example.com/orderers/orderer0.example.com/tls
# TLS 私钥
cp org0/orderer1/tls-msp/keystore/key.pem crypto-config/ordererOrganizations/example.com/orderers/orderer0.example.com/tls/server.key
# TLS 签名证书
cp org0/orderer1/tls-msp/signcerts/cert.pem crypto-config/ordererOrganizations/example.com/orderers/orderer0.example.com/tls/server.crt
# TLS 根证书
cp org0/orderer1/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem crypto-config/ordererOrganizations/example.com/orderers/orderer0.example.com/tls/ca.crt

cp -r org0/orderer1/msp/ crypto-config/ordererOrganizations/example.com/orderers/orderer0.example.com/

mv crypto-config/ordererOrganizations/example.com/orderers/orderer0.example.com/msp/cacerts/0-0-0-0-7053.pem crypto-config/ordererOrganizations/example.com/orderers/orderer0.example.com/msp/cacerts/ca.example.com-cert.pem

mkdir -p crypto-config/ordererOrganizations/example.com/orderers/orderer0.example.com/msp/tlscacerts && cp org0/orderer1/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem crypto-config/ordererOrganizations/example.com/orderers/orderer0.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

# 编写 config.yaml 文件

vim crypto-config/ordererOrganizations/example.com/orderers/orderer0.example.com/msp/config.yaml

NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/ca.example.com-cert.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/ca.example.com-cert.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/ca.example.com-cert.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/ca.example.com-cert.pem
    OrganizationalUnitIdentifier: orderer
```




​	

## Orderer 2 Local MSP

```bash
mkdir -p crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp

mkdir -p crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/tls

# TLS 私钥

cp org0/orderer2/tls-msp/keystore/key.pem crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/tls/server.key

# TLS 签名证书

cp org0/orderer2/tls-msp/signcerts/cert.pem crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/tls/server.crt

# TLS 根证书

cp org0/orderer2/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/tls/ca.crt

# MSP

cp -r org0/orderer2/msp/ crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/

mv crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/cacerts/0-0-0-0-7053.pem crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/cacerts/ca.example.com-cert.pem

mkdir -p crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts && cp org0/orderer2/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

# 编写 config.yaml 文件

vim crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/config.yaml

NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/ca.example.com-cert.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/ca.example.com-cert.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/ca.example.com-cert.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/ca.example.com-cert.pem
    OrganizationalUnitIdentifier: orderer
```

​	
​	

## Orderer 3 Local MSP

```bash
mkdir -p crypto-config/ordererOrganizations/example.com/orderers/orderer2.example.com/msp

mkdir -p crypto-config/ordererOrganizations/example.com/orderers/orderer2.example.com/tls

# TLS 私钥

cp org0/orderer3/tls-msp/keystore/key.pem crypto-config/ordererOrganizations/example.com/orderers/orderer2.example.com/tls/server.key

# TLS 签名证书

cp org0/orderer3/tls-msp/signcerts/cert.pem crypto-config/ordererOrganizations/example.com/orderers/orderer2.example.com/tls/server.crt

# TLS 根证书

cp org0/orderer3/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem crypto-config/ordererOrganizations/example.com/orderers/orderer2.example.com/tls/ca.crt

# MSP

cp -r org0/orderer3/msp/ crypto-config/ordererOrganizations/example.com/orderers/orderer2.example.com/

mv crypto-config/ordererOrganizations/example.com/orderers/orderer2.example.com/msp/cacerts/0-0-0-0-7053.pem crypto-config/ordererOrganizations/example.com/orderers/orderer2.example.com/msp/cacerts/ca.example.com-cert.pem

mkdir -p crypto-config/ordererOrganizations/example.com/orderers/orderer2.example.com/msp/tlscacerts && cp org0/orderer3/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem crypto-config/ordererOrganizations/example.com/orderers/orderer2.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

# 编写 config.yaml 文件

vim crypto-config/ordererOrganizations/example.com/orderers/orderer2.example.com/msp/config.yaml

NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/ca.example.com-cert.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/ca.example.com-cert.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/ca.example.com-cert.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/ca.example.com-cert.pem
    OrganizationalUnitIdentifier: orderer
```



## crypto-config/ordererOrganizations/example.com/msp/

```bash
mkdir -p crypto-config/ordererOrganizations/example.com/msp/admincerts
mkdir -p crypto-config/ordererOrganizations/example.com/msp/cacerts
mkdir -p crypto-config/ordererOrganizations/example.com/msp/tlscacerts

cp org0/orderer1/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem crypto-config/ordererOrganizations/example.com/msp/tlscacerts/tlsca.example.com-cert.pem

cp org0/orderer1/msp/cacerts/0-0-0-0-7053.pem crypto-config/ordererOrganizations/example.com/msp/cacerts/ca.example.com-cert.pem

cp /tmp/hyperledger/org0/admin/msp/signcerts/cert.pem crypto-config/ordererOrganizations/example.com/msp/admincerts/orderer-admin-cert.pem

# 编写 config.yaml 文件

vim crypto-config/ordererOrganizations/example.com/msp/config.yaml

NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/ca.example.com-cert.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/ca.example.com-cert.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/ca.example.com-cert.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/ca.example.com-cert.pem
    OrganizationalUnitIdentifier: orderer
```

​	

# 构建 Org1 Peer 本地 MSP 结构

## Org1 Peer1 Local MSP

```bash
mkdir -p crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/ && cp -r org1/peer1/msp/ crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com

mkdir -p crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls

cp org1/peer1/tls-msp/signcerts/cert.pem crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/server.crt

cp org1/peer1/tls-msp/keystore/key.pem crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/server.key

cp org1/peer1/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt

# 编写 config.yaml 文件

vim crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/msp/config.yaml

NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/0-0-0-0-7054.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/0-0-0-0-7054.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/0-0-0-0-7054.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/0-0-0-0-7054.pem
    OrganizationalUnitIdentifier: orderer
```

​	
​	

## Org1 Peer2 Local MSP

```bash
mkdir -p crypto-config/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/ && cp -r org1/peer2/msp/ crypto-config/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/

mkdir -p crypto-config/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/tls

cp org1/peer2/tls-msp/signcerts/cert.pem crypto-config/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/tls/server.crt

cp org1/peer2/tls-msp/keystore/key.pem crypto-config/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/tls/server.key

cp org1/peer2/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem crypto-config/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/tls/ca.crt

# 编写 config.yaml 文件

vim crypto-config/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/msp/config.yaml

NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/0-0-0-0-7054.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/0-0-0-0-7054.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/0-0-0-0-7054.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/0-0-0-0-7054.pem
    OrganizationalUnitIdentifier: orderer
```

​	
​	

## crypto-config/peerOrganizations/org1.example.com/msp

```bash
mkdir -p crypto-config/peerOrganizations/org1.example.com/msp/admincerts
mkdir -p crypto-config/peerOrganizations/org1.example.com/msp/cacerts
mkdir -p crypto-config/peerOrganizations/org1.example.com/msp/tlscacerts

cp org1/admin/msp/cacerts/0-0-0-0-7054.pem crypto-config/peerOrganizations/org1.example.com/msp/cacerts/ca.org1.example.com-cert.pem

cp org1/peer1/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem crypto-config/peerOrganizations/org1.example.com/msp/tlscacerts/tlsca.org1.example.com-cert.pem

cp /tmp/hyperledger/org1/admin/msp/signcerts/cert.pem crypto-config/peerOrganizations/org1.example.com/msp/admincerts/org1-admin-cert.pem

# 编写 config.yaml 文件

vim crypto-config/peerOrganizations/org1.example.com/msp/config.yaml

NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/ca.org1.example.com-cert.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/ca.org1.example.com-cert.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/ca.org1.example.com-cert.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/ca.org1.example.com-cert.pem
    OrganizationalUnitIdentifier: orderer
```



## crypto-config/peerOrganizations/org1.example.com/users

```bash
mkdir -p crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com

cp -r org1/admin/msp/ crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com

mkdir -p crypto-config/peerOrganizations/org1.example.com/users/Admin\@org1.example.com/msp/admincerts

cp /tmp/hyperledger/org1/admin/msp/signcerts/cert.pem crypto-config/peerOrganizations/org1.example.com/users/Admin\@org1.example.com/msp/admincerts/org1-admin-cert.pem

mkdir -p crypto-config/peerOrganizations/org1.example.com/users/Admin\@org1.example.com/msp/tlscacerts

cp org1/peer1/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem crypto-config/peerOrganizations/org1.example.com/users/Admin\@org1.example.com/msp/tlscacerts/tlsca.org1.example.com-cert.pem


# 编写 config.yaml 文件
vim crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/config.yaml

NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/0-0-0-0-7054.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/0-0-0-0-7054.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/0-0-0-0-7054.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/0-0-0-0-7054.pem
    OrganizationalUnitIdentifier: orderer
```

​	
​	

# 构建 Org2 Peer 本地 MSP 结构

## Org2 Peer1 Local MSP

```bash
mkdir -p crypto-config/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/ && cp -r org2/peer1/msp/ crypto-config/peerOrganizations/org2.example.com/peers/peer0.org2.example.com

mkdir -p crypto-config/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls

cp org2/peer1/tls-msp/signcerts/cert.pem crypto-config/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/server.crt

cp org2/peer1/tls-msp/keystore/key.pem crypto-config/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/server.key

cp org2/peer1/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem crypto-config/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt

# 编写 config.yaml 文件
vim crypto-config/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/msp/config.yaml

NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/0-0-0-0-7055.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/0-0-0-0-7055.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/0-0-0-0-7055.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/0-0-0-0-7055.pem
    OrganizationalUnitIdentifier: orderer
```

​	

## Org2 Peer2 Local MSP

```bash
mkdir -p crypto-config/peerOrganizations/org2.example.com/peers/peer1.org2.example.com/ && cp -r org2/peer2/msp/ crypto-config/peerOrganizations/org2.example.com/peers/peer1.org2.example.com/

mkdir -p crypto-config/peerOrganizations/org2.example.com/peers/peer1.org2.example.com/tls

cp org2/peer2/tls-msp/signcerts/cert.pem crypto-config/peerOrganizations/org2.example.com/peers/peer1.org2.example.com/tls/server.crt

cp org2/peer2/tls-msp/keystore/key.pem crypto-config/peerOrganizations/org2.example.com/peers/peer1.org2.example.com/tls/server.key

cp org2/peer2/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem crypto-config/peerOrganizations/org2.example.com/peers/peer1.org2.example.com/tls/ca.crt

# 编写 config.yaml 文件

vim crypto-config/peerOrganizations/org2.example.com/peers/peer1.org2.example.com/msp/config.yaml

NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/0-0-0-0-7055.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/0-0-0-0-7055.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/0-0-0-0-7055.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/0-0-0-0-7055.pem
    OrganizationalUnitIdentifier: orderer
```

​	

## crypto-config/peerOrganizations/org2.example.com/msp

```bash
mkdir -p crypto-config/peerOrganizations/org2.example.com/msp/admincerts
mkdir -p crypto-config/peerOrganizations/org2.example.com/msp/cacerts
mkdir -p crypto-config/peerOrganizations/org2.example.com/msp/tlscacerts

cp org2/admin/msp/cacerts/0-0-0-0-7055.pem crypto-config/peerOrganizations/org2.example.com/msp/cacerts/ca.org2.example.com-cert.pem

cp org2/peer1/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem crypto-config/peerOrganizations/org2.example.com/msp/tlscacerts/tlsca.org2.example.com-cert.pem

cp /tmp/hyperledger/org2/admin/msp/signcerts/cert.pem crypto-config/peerOrganizations/org2.example.com/msp/admincerts/org2-admin-cert.pem

# 编写 config.yaml 文件

vim crypto-config/peerOrganizations/org2.example.com/msp/config.yaml

NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/ca.org2.example.com-cert.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/ca.org2.example.com-cert.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/ca.org2.example.com-cert.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/ca.org2.example.com-cert.pem
    OrganizationalUnitIdentifier: orderer
```

​	
​	

## crypto-config/peerOrganizations/org2.example.com/users

```bash
mkdir -p crypto-config/peerOrganizations/org2.example.com/users/Admin@org2.example.com

cp -r org2/admin/msp/ crypto-config/peerOrganizations/org2.example.com/users/Admin@org2.example.com

mkdir -p crypto-config/peerOrganizations/org2.example.com/users/Admin\@org2.example.com/msp/admincerts

cp /tmp/hyperledger/org2/admin/msp/signcerts/cert.pem crypto-config/peerOrganizations/org2.example.com/users/Admin\@org2.example.com/msp/admincerts/org2-admin-cert.pem

mkdir -p crypto-config/peerOrganizations/org2.example.com/users/Admin\@org2.example.com/msp/tlscacerts

cp org2/peer1/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem crypto-config/peerOrganizations/org2.example.com/users/Admin\@org2.example.com/msp/tlscacerts/tlsca.org2.example.com-cert.pem

# 编写 config.yaml 文件

vim crypto-config/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp/config.yaml

NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/0-0-0-0-7055.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/0-0-0-0-7055.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/0-0-0-0-7055.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/0-0-0-0-7055.pem
    OrganizationalUnitIdentifier: orderer
```


​	
​	
Fabric CA

使用 Fabric CA 生成 MSP: https://juejin.cn/post/7079334814196695054

网络部署: https://my.oschina.net/j4love/blog/5454098

java合约代码： https://gitee.com/kernelHP/hyperledger-fabric-contract-java-demo.git

演示如何在 java 应用中访问 fabric 测试网络中的合约
应用代码： https://gitee.com/kernelHP/hyperledger-fabric-app-java-demo.git
合约代码： https://gitee.com/kernelHP/hyperledger-fabric-contract-java-demo.git

升级合约代码：https://gitee.com/kernelHP/hyperledger-fabric-contract-java-demo.git

二进制部署orderer节点文档：https://my.oschina.net/j4love/blog/5454092

java APP client相关文档:

https://github.com/hyperledger/fabric-gateway

https://github.com/hyperledger/fabric-gateway-java

https://www.notion.so/Fabirc-86707e280aea4e739040b8d9609fc4c8