# Fabric-中间CA生成证书

# **Fabric-中间CA生成证书**

# **ca.root:7054 - ca.immediate:7055**

```bash
# rca-org证书服务器环境变量
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/immediateca/ca-cert.pem
export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/immediateca/admin
fabric-ca-client enroll -d -u https://admin:adminpw@ca.immediate.xinhe.com:7055
```

```bash
# 删除联盟成员
fabric-ca-client affiliation remove --force org1 -u https://ca.immediate.xinhe.com:7055
fabric-ca-client affiliation remove --force org2 -u https://ca.immediate.xinhe.com:7055

# 添加联盟成员
fabric-ca-client affiliation add com -u https://ca.immediate.xinhe.com:7055
fabric-ca-client affiliation add com.xinhe -u https://ca.immediate.xinhe.com:7055
fabric-ca-client affiliation add com.xinhe.org0 -u https://ca.immediate.xinhe.com:7055
fabric-ca-client affiliation add com.xinhe.org1 -u https://ca.immediate.xinhe.com:7055
fabric-ca-client affiliation add com.xinhe.org2 -u https://ca.immediate.xinhe.com:7055
fabric-ca-client affiliation add com.xinhe.org3 -u https://ca.immediate.xinhe.com:7055

# 注册peer节点
fabric-ca-client register -d --id.name peer0.org1.xinhe.com --id.affiliation com.xinhe.org1 --id.secret peerPW --id.type peer --id.attrs "hf.Registrar.Roles=peer" -u https://ca.immediate.xinhe.com:7055
fabric-ca-client register -d --id.name peer1.org1.xinhe.com --id.affiliation com.xinhe.org1 --id.secret peerPW --id.type peer --id.attrs "hf.Registrar.Roles=peer" -u https://ca.immediate.xinhe.com:7055

# 注册用户 org2
fabric-ca-client register -d --id.name peer0.org2.xinhe.com --id.affiliation com.xinhe.org2 --id.secret peerPW --id.type peer --id.attrs "hf.Registrar.Roles=peer" -u https://ca.immediate.xinhe.com:7055
fabric-ca-client register -d --id.name peer1.org2.xinhe.com --id.affiliation com.xinhe.org2 --id.secret peerPW --id.type peer --id.attrs "hf.Registrar.Roles=peer" -u https://ca.immediate.xinhe.com:7055

# 注册用户 org3
fabric-ca-client register -d --id.name peer0.org3.xinhe.com --id.affiliation com.xinhe.org3 --id.secret peerPW --id.type peer --id.attrs "hf.Registrar.Roles=peer" -u https://ca.immediate.xinhe.com:7055
fabric-ca-client register -d --id.name peer1.org3.xinhe.com --id.affiliation com.xinhe.org3 --id.secret peerPW --id.type peer --id.attrs "hf.Registrar.Roles=peer" -u https://ca.immediate.xinhe.com:7055

# 注册orderer节点
fabric-ca-client register -d --id.name orderer0.xinhe.com --id.affiliation com.xinhe.org0 --id.secret ordererpw --id.type orderer --id.attrs "hf.Registrar.Roles=orderer" -u https://ca.immediate.xinhe.com:7055
fabric-ca-client register -d --id.name orderer1.xinhe.com --id.affiliation com.xinhe.org0 --id.secret ordererpw --id.type orderer --id.attrs "hf.Registrar.Roles=orderer" -u https://ca.immediate.xinhe.com:7055
fabric-ca-client register -d --id.name orderer2.xinhe.com --id.affiliation com.xinhe.org0 --id.secret ordererpw --id.type orderer --id.attrs "hf.Registrar.Roles=orderer" -u https://ca.immediate.xinhe.com:7055
fabric-ca-client register -d --id.name orderer3.xinhe.com --id.affiliation com.xinhe.org0 --id.secret ordererpw --id.type orderer --id.attrs "hf.Registrar.Roles=orderer" -u https://ca.immediate.xinhe.com:7055

# 注册org0管理员
fabric-ca-client register -d --id.name admin-org0 --id.affiliation com.xinhe.org0 --id.secret orgadminpw --id.type admin --id.attrs "hf.Registrar.Roles=admin,hf.Registrar.Roles=*,hf.Registrar.DelegateRoles=*,hf.AffiliationMgr=true,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert" -u https://ca.immediate.xinhe.com:7055

# 注册org1管理员
fabric-ca-client register -d --id.name admin-org1 --id.affiliation com.xinhe.org1 --id.secret orgadminpw --id.type admin --id.attrs "hf.Registrar.Roles=admin,hf.Registrar.Roles=*,hf.Registrar.DelegateRoles=*,hf.AffiliationMgr=true,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert" -u https://ca.immediate.xinhe.com:7055

# 注册org2管理员
fabric-ca-client register -d --id.name admin-org2 --id.affiliation com.xinhe.org2 --id.secret orgadminpw --id.type admin --id.attrs "hf.Registrar.Roles=admin,hf.Registrar.Roles=*,hf.Registrar.DelegateRoles=*,hf.AffiliationMgr=true,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert" -u https://ca.immediate.xinhe.com:7055

# 注册org3管理员
fabric-ca-client register -d --id.name admin-org3 --id.affiliation com.xinhe.org3 --id.secret orgadminpw --id.type admin --id.attrs "hf.Registrar.Roles=admin,hf.Registrar.Roles=*,hf.Registrar.DelegateRoles=*,hf.AffiliationMgr=true,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert" -u https://ca.immediate.xinhe.com:7055

# 注册org1普通用户
fabric-ca-client register -d --id.name user1-org1 --id.attrs "hf.Registrar.Roles=client,hf.Registrar.Attributes=*" --id.affiliation com.xinhe.org1 --id.secret org1UserPW --id.type client -u https://ca.immediate.xinhe.com:7055

fabric-ca-client register -d --id.name user2-org1 --id.attrs "hf.Registrar.Roles=user,hf.Registrar.Attributes=*" --id.affiliation com.xinhe.org1 --id.secret org1UserPW --id.type user -u https://ca.immediate.xinhe.com:7055

fabric-ca-client register -d --id.name user3-org1 --id.attrs "hf.Registrar.Roles=admin,hf.Registrar.Attributes=*" --id.affiliation com.xinhe.org1 --id.secret org1UserPW --id.type admin -u https://ca.immediate.xinhe.com:7055

# 查看联盟信息
fabric-ca-client affiliation list -u https://ca.immediate.xinhe.com:7055

# 显示身份/用户列表
fabric-ca-client identity list -u https://ca.immediate.xinhe.com:7055
```

# **获取CA证书**

## **peer用户证书**

```bash
#org1 Ecert证书
# 将fabric-ca服务器自签证书拷贝到组织一，用于向服务器发出请求
mkdir -p org1/peer0/assets/ca/ && cp immediateca/ca-cert.pem org1/peer0/assets/ca/org-ca-cert.pem
export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org1/peer0
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org1/peer0/assets/ca/org-ca-cert.pem
export FABRIC_CA_CLIENT_MSPDIR=msp
fabric-ca-client enroll -d -u https://peer0.org1.xinhe.com:peerPW@ca.immediate.xinhe.com:7055

# 更改私钥文件名称
mv org1/peer0/msp/keystore/*_sk org1/peer0/msp/keystore/priv_sk
# 创建管理员证书目录，后面将管理员证书拷贝过来
mkdir -p org1/peer0/msp/admincerts/

#org1 TLS 证书
# 将tls服务器自签证书拷贝到组织一，用于向tls服务器发出请求
mkdir -p org1/peer0/assets/tls-ca/ && cp immediateca/tls-cert.pem org1/peer0/assets/tls-ca/tls-ca-cert.pem
export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org1/peer0
export FABRIC_CA_CLIENT_MSPDIR=tls-msp
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org1/peer0/assets/tls-ca/tls-ca-cert.pem

fabric-ca-client enroll -d -u https://peer0.org1.xinhe.com:peerPW@ca.immediate.xinhe.com:7055 --enrollment.profile tls --csr.hosts peer0.org1.xinhe.com

# 将 keystore 路径下的文件改名为 key.pem
mv org1/peer0/tls-msp/keystore/*_sk org1/peer0/tls-msp/keystore/key.pem
tree /tmp/hyperledger/org1/peer0
```

## **orderer用户证书**

```bash
#ECert 证书
mkdir -p orderer/orderer0/assets/ca/ && cp immediateca/ca-cert.pem orderer/orderer0/assets/ca/org-ca-cert.pem
export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/orderer/orderer0
export FABRIC_CA_CLIENT_MSPDIR=msp
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/orderer/orderer0/assets/ca/org-ca-cert.pem

fabric-ca-client enroll -d -u https://orderer0.xinhe.com:ordererpw@ca.immediate.xinhe.com:7055

mv orderer/orderer0/msp/keystore/*_sk orderer/orderer0/msp/keystore/priv_sk

#TLS 证书 -> 中间证书
mkdir -p orderer/orderer0/assets/tls-ca/ && cp immediateca/tls-cert.pem orderer/orderer0/assets/tls-ca/tls-ca-cert.pem

export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/orderer/orderer0
export FABRIC_CA_CLIENT_MSPDIR=tls-msp
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/orderer/orderer0/assets/tls-ca/tls-ca-cert.pem

fabric-ca-client enroll -d -u https://orderer0.xinhe.com:ordererpw@ca.immediate.xinhe.com:7055 --enrollment.profile tls --csr.hosts 'orderer0.xinhe.com,orderer0,192.168.1.135'
mv orderer/orderer0/tls-msp/keystore/*_sk orderer/orderer0/tls-msp/keystore/key.pem

tree /tmp/hyperledger/orderer/orderer0
```

## **组织管理员证书**

```bash
# orderer 管理员证书
export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/orderer/admin
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/immediateca/ca-cert.pem
export FABRIC_CA_CLIENT_MSPDIR=msp

fabric-ca-client enroll -d -u https://admin-org0:orgadminpw@ca.immediate.xinhe.com:7055
tree /tmp/hyperledger/orderer/admin

mv /tmp/hyperledger/orderer/admin/msp/keystore/*_sk /tmp/hyperledger/orderer/admin/msp/keystore/priv_sk

# 将组织管理员证书拷贝给组织成员
mkdir /tmp/hyperledger/orderer/orderer0/msp/admincerts && cp /tmp/hyperledger/orderer/admin/msp/signcerts/cert.pem /tmp/hyperledger/orderer/orderer0/msp/admincerts/orderer-admin-cert.pem
mkdir /tmp/hyperledger/orderer/orderer1/msp/admincerts && cp /tmp/hyperledger/orderer/admin/msp/signcerts/cert.pem /tmp/hyperledger/orderer/orderer1/msp/admincerts/orderer-admin-cert.pem
mkdir /tmp/hyperledger/orderer/orderer2/msp/admincerts && cp /tmp/hyperledger/orderer/admin/msp/signcerts/cert.pem /tmp/hyperledger/orderer/orderer2/msp/admincerts/orderer-admin-cert.pem
mkdir /tmp/hyperledger/orderer/orderer3/msp/admincerts && cp /tmp/hyperledger/orderer/admin/msp/signcerts/cert.pem /tmp/hyperledger/orderer/orderer3/msp/admincerts/orderer-admin-cert.pem
tree /tmp/hyperledger/orderer

```

```bash
#org 管理员证书
export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org1/admin
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/immediateca/ca-cert.pem
export FABRIC_CA_CLIENT_MSPDIR=msp

fabric-ca-client enroll -d -u https://admin-org1:orgadminpw@ca.immediate.xinhe.com:7055

mv /tmp/hyperledger/org1/admin/msp/keystore/*_sk /tmp/hyperledger/org1/admin/msp/keystore/priv_sk

tree /tmp/hyperledger/org1/admin

# 将组织管理员证书复制给组织成员
mkdir -p /tmp/hyperledger/org1/peer0/msp/admincerts && cp /tmp/hyperledger/org1/admin/msp/signcerts/cert.pem /tmp/hyperledger/org1/peer0/msp/admincerts/org1-admin-cert.pem
mkdir -p /tmp/hyperledger/org1/peer1/msp/admincerts && cp /tmp/hyperledger/org1/admin/msp/signcerts/cert.pem /tmp/hyperledger/org1/peer1/msp/admincerts/org1-admin-cert.pem

tree org1

```

## **组织用户证书**

```bash
#org 用户证书
export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org1/users/user1
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/immediateca/ca-cert.pem
export FABRIC_CA_CLIENT_MSPDIR=msp

rm -rf /tmp/hyperledger/org1/users/user1/msp/keystore/*
fabric-ca-client enroll -d -u https://user1-org1:org1UserPW@ca.immediate.xinhe.com:7055
mv -f /tmp/hyperledger/org1/users/user1/msp/keystore/*_sk /tmp/hyperledger/org1/users/user1/msp/keystore/priv_sk

mkdir -p /tmp/hyperledger/org1/users/user1/msp/admincerts && cp /tmp/hyperledger/org1/admin/msp/signcerts/cert.pem /tmp/hyperledger/org1/users/user1/msp/admincerts/org1-admin-cert.pem

tree /tmp/hyperledger/org1/users/user1
```

# **构建本地MSP结构**

## **orderer身份证书**

```bash
mkdir -p crypto-config/ordererOrganizations/xinhe.com/orderers/orderer0.xinhe.com/msp
mkdir -p crypto-config/ordererOrganizations/xinhe.com/orderers/orderer0.xinhe.com/tls
# TLS 私钥
cp orderer/orderer0/tls-msp/keystore/key.pem crypto-config/ordererOrganizations/xinhe.com/orderers/orderer0.xinhe.com/tls/server.key
# TLS 签名证书
cp orderer/orderer0/tls-msp/signcerts/cert.pem crypto-config/ordererOrganizations/xinhe.com/orderers/orderer0.xinhe.com/tls/server.crt
# TLS 根证书
#cp orderer/orderer0/tls-msp/tlscacerts/tls-ca-immediate-xinhe-com-7055.pem crypto-config/ordererOrganizations/xinhe.com/orderers/orderer0.xinhe.com/tls/ca.crt
cp immediateca/chain-cert.pem crypto-config/ordererOrganizations/xinhe.com/orderers/orderer0.xinhe.com/tls/ca.crt

cp -r orderer/orderer0/msp/ crypto-config/ordererOrganizations/xinhe.com/orderers/orderer0.xinhe.com/

#mv crypto-config/ordererOrganizations/xinhe.com/orderers/orderer0.xinhe.com/msp/cacerts/ca-immediate-xinhe-com-7055.pem crypto-config/ordererOrganizations/xinhe.com/orderers/orderer0.xinhe.com/msp/cacerts/ca-immediate-xinhe-com-7055.pem
#mv crypto-config/ordererOrganizations/xinhe.com/orderers/orderer0.xinhe.com/msp/cacerts/ca-immediate-xinhe-com-7055.pem crypto-config/ordererOrganizations/xinhe.com/orderers/orderer0.xinhe.com/msp/cacerts/ca-immediate-xinhe-com-7055.pem

#mkdir -p crypto-config/ordererOrganizations/xinhe.com/orderers/orderer0.xinhe.com/msp/tlscacerts && cp orderer/orderer0/tls-msp/tlscacerts/tls-ca-immediate-xinhe-com-7055.pem crypto-config/ordererOrganizations/xinhe.com/orderers/orderer0.xinhe.com/msp/tlscacerts/tls-ca-immediate-xinhe-com-7055.pem
mkdir -p crypto-config/ordererOrganizations/xinhe.com/orderers/orderer0.xinhe.com/msp/tlscacerts && cp immediateca/chain-cert.pem crypto-config/ordererOrganizations/xinhe.com/orderers/orderer0.xinhe.com/msp/tlscacerts/tlsca-immediate-xinhe-com-7055.pem

# 编写 config.yaml 文件
tee crypto-config/ordererOrganizations/xinhe.com/orderers/orderer0.xinhe.com/msp/config.yaml  <<-'EOF'
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/ca-immediate-xinhe-com-7055.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/ca-immediate-xinhe-com-7055.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/ca-immediate-xinhe-com-7055.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/ca-immediate-xinhe-com-7055.pem
    OrganizationalUnitIdentifier: orderer
EOF

```

### **orderer组织身份证书**

**crypto-config/ordererOrganizations/xinhe.com/msp/**

```bash
mkdir -p crypto-config/ordererOrganizations/xinhe.com/msp/admincerts
mkdir -p crypto-config/ordererOrganizations/xinhe.com/msp/cacerts
mkdir -p crypto-config/ordererOrganizations/xinhe.com/msp/tlscacerts
#mkdir -p crypto-config/ordererOrganizations/xinhe.com/msp/intermediatecerts

#cp orderer/orderer0/tls-msp/tlscacerts/tls-ca-immediate-xinhe-com-7055.pem crypto-config/ordererOrganizations/xinhe.com/msp/tlscacerts/tls-ca-immediate-xinhe-com-7055.pem
cp immediateca/chain-cert.pem crypto-config/ordererOrganizations/xinhe.com/msp/tlscacerts/tls-ca-immediate-xinhe-com-7055.pem

#cp orderer/orderer0/msp/cacerts/ca-immediate-xinhe-com-7055.pem crypto-config/ordererOrganizations/xinhe.com/msp/cacerts/ca-immediate-xinhe-com-7055.pem
cp immediateca/chain-cert.pem crypto-config/ordererOrganizations/xinhe.com/msp/cacerts/ca-immediate-xinhe-com-7055.pem

cp /tmp/hyperledger/orderer/admin/msp/signcerts/cert.pem crypto-config/ordererOrganizations/xinhe.com/msp/admincerts/orderer-admin-cert.pem

# 编写 config.yaml 文件
tee crypto-config/ordererOrganizations/xinhe.com/msp/config.yaml <<-'EOF'
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/ca-immediate-xinhe-com-7055.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/ca-immediate-xinhe-com-7055.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/ca-immediate-xinhe-com-7055.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/ca-immediate-xinhe-com-7055.pem
    OrganizationalUnitIdentifier: orderer
EOF

```

### **orderer组织管理员身份证书**

```bash
mkdir -p crypto-config/ordererOrganizations/xinhe.com/users/Admin@xinhe.com
mkdir -p crypto-config/ordererOrganizations/xinhe.com/users/Admin@xinhe.com/msp/admincerts
mkdir -p crypto-config/ordererOrganizations/xinhe.com/users/Admin@xinhe.com/msp/tlscacerts
mkdir -p crypto-config/ordererOrganizations/xinhe.com/users/Admin@xinhe.com/msp/tlsintermediatecerts

cp -r orderer/admin/msp/ crypto-config/ordererOrganizations/xinhe.com/users/Admin@xinhe.com
cp /tmp/hyperledger/orderer/admin/msp/signcerts/cert.pem crypto-config/ordererOrganizations/xinhe.com/users/Admin@xinhe.com/msp/admincerts/orderer-admin-cert.pem
cp orderer/orderer1/tls-msp/tlscacerts/tls-ca-immediate-xinhe-com-7055.pem crypto-config/ordererOrganizations/xinhe.com/users/Admin@xinhe.com/msp/tlscacerts/tlsca-immediate-xinhe-com-7055.pem
cp orderer/orderer1/tls-msp/tlsintermediatecerts/tls-ca-immediate-xinhe-com-7055.pem crypto-config/ordererOrganizations/xinhe.com/users/Admin@xinhe.com/msp/tlsintermediatecerts/tlsca-immediate-xinhe-com-7055.pem

# 编写 config.yaml 文件
tee crypto-config/ordererOrganizations/xinhe.com/users/Admin@xinhe.com/msp/config.yaml  <<-'EOF'
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/ca-immediate-xinhe-com-7055.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/ca-immediate-xinhe-com-7055.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/ca-immediate-xinhe-com-7055.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/ca-immediate-xinhe-com-7055.pem
    OrganizationalUnitIdentifier: orderer
EOF

```

## **peer身份证书**

```bash
mkdir -p crypto-config/peerOrganizations/org1.xinhe.com/peers/peer0.org1.xinhe.com/ && cp -r org1/peer0/msp/ crypto-config/peerOrganizations/org1.xinhe.com/peers/peer0.org1.xinhe.com
mkdir -p crypto-config/peerOrganizations/org1.xinhe.com/peers/peer0.org1.xinhe.com/tls

rm -f crypto-config/peerOrganizations/org1.xinhe.com/peers/peer0.org1.xinhe.com/msp/cacerts/ca-immediate-xinhe-com-7055.pem
cp immediateca/chain-cert.pem crypto-config/peerOrganizations/org1.xinhe.com/peers/peer0.org1.xinhe.com/msp/cacerts/ca-immediate-xinhe-com-7055.pem

cp org1/peer0/tls-msp/signcerts/cert.pem crypto-config/peerOrganizations/org1.xinhe.com/peers/peer0.org1.xinhe.com/tls/server.crt
cp org1/peer0/tls-msp/keystore/key.pem crypto-config/peerOrganizations/org1.xinhe.com/peers/peer0.org1.xinhe.com/tls/server.key
cp immediateca/chain-cert.pem crypto-config/peerOrganizations/org1.xinhe.com/peers/peer0.org1.xinhe.com/tls/ca.crt

# 编写 config.yaml 文件
tee crypto-config/peerOrganizations/org1.xinhe.com/peers/peer0.org1.xinhe.com/msp/config.yaml  <<-'EOF'
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/ca-immediate-xinhe-com-7055.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/ca-immediate-xinhe-com-7055.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/ca-immediate-xinhe-com-7055.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/ca-immediate-xinhe-com-7055.pem
    OrganizationalUnitIdentifier: orderer
EOF

```

### **peer组织证书**

**crypto-config/peerOrganizations/org1.xinhe.com/msp**

```bash
mkdir -p crypto-config/peerOrganizations/org1.xinhe.com/msp/admincerts
mkdir -p crypto-config/peerOrganizations/org1.xinhe.com/msp/cacerts
mkdir -p crypto-config/peerOrganizations/org1.xinhe.com/msp/tlscacerts

cp immediateca/chain-cert.pem crypto-config/peerOrganizations/org1.xinhe.com/msp/cacerts/ca-immediate-xinhe-com-7055.pem

cp immediateca/chain-cert.pem crypto-config/peerOrganizations/org1.xinhe.com/msp/tlscacerts/tlsca-immediate-xinhe-com-7055.pem

cp /tmp/hyperledger/org1/admin/msp/signcerts/cert.pem crypto-config/peerOrganizations/org1.xinhe.com/msp/admincerts/org1-admin-cert.pem

# 编写 config.yaml 文件
tee crypto-config/peerOrganizations/org1.xinhe.com/msp/config.yaml  <<-'EOF'
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/ca-immediate-xinhe-com-7055.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/ca-immediate-xinhe-com-7055.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/ca-immediate-xinhe-com-7055.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/ca-immediate-xinhe-com-7055.pem
    OrganizationalUnitIdentifier: orderer
EOF

```

### **peer组织管理员证书**

**crypto-config/peerOrganizations/org1.xinhe.com/users**

```bash
mkdir -p crypto-config/peerOrganizations/org1.xinhe.com/users/Admin@org1.xinhe.com

cp -r org1/admin/msp/ crypto-config/peerOrganizations/org1.xinhe.com/users/Admin@org1.xinhe.com

mkdir -p crypto-config/peerOrganizations/org1.xinhe.com/users/Admin@org1.xinhe.com/msp/admincerts

cp /tmp/hyperledger/org1/admin/msp/signcerts/cert.pem crypto-config/peerOrganizations/org1.xinhe.com/users/Admin@org1.xinhe.com/msp/admincerts/org1-admin-cert.pem

mkdir -p crypto-config/peerOrganizations/org1.xinhe.com/users/Admin@org1.xinhe.com/msp/tlscacerts

cp org1/peer1/tls-msp/tlscacerts/tls-ca-immediate-xinhe-com-7055.pem crypto-config/peerOrganizations/org1.xinhe.com/users/Admin@org1.xinhe.com/msp/tlscacerts/tlsca.org1.xinhe.com-cert.pem

  # 编写 config.yaml 文件
tee crypto-config/peerOrganizations/org1.xinhe.com/users/Admin@org1.xinhe.com/msp/config.yaml  <<-'EOF'
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/ca-immediate-xinhe-com-7055.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/ca-immediate-xinhe-com-7055.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/ca-immediate-xinhe-com-7055.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/ca-immediate-xinhe-com-7055.pem
    OrganizationalUnitIdentifier: orderer
EOF

```

## **普通用户证书**

```bash
mkdir -p crypto-config/peerOrganizations/org1.xinhe.com/users/User1@org1.xinhe.com

cp -r org1/users/user1/msp/ crypto-config/peerOrganizations/org1.xinhe.com/users/User1@org1.xinhe.com

mkdir -p crypto-config/peerOrganizations/org1.xinhe.com/users/User1@org1.xinhe.com/msp/user1certs

cp /tmp/hyperledger/org1/users/user1/msp/signcerts/cert.pem crypto-config/peerOrganizations/org1.xinhe.com/users/User1@org1.xinhe.com/msp/user1certs/org1-user1-cert.pem

mkdir -p crypto-config/peerOrganizations/org1.xinhe.com/users/User1@org1.xinhe.com/msp/tlscacerts

cp org1/peer1/tls-msp/tlscacerts/tls-0-0-0-0-7055.pem crypto-config/peerOrganizations/org1.xinhe.com/users/User1@org1.xinhe.com/msp/tlscacerts/tlsca.org1.xinhe.com-cert.pem

  # 编写 config.yaml 文件
tee crypto-config/peerOrganizations/org1.xinhe.com/users/Admin@org1.xinhe.com/msp/config.yaml  <<-'EOF'
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
EOF
```