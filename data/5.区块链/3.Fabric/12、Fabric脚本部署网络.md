# 脚本部署

**init_ca.sh**: 操作ca证书脚本

**node_start_stop_restart_list_log_open.sh**: 操作节点脚本

**channel_init_join_list_json_addorg_sign_update_config.sh**: 操作通道脚本

**chaincode_install_commit_invoke_query_info.sh**: 操作链码脚本

# 第一章 **操作ca证书脚本**

### 1.1. **配置身份**

编辑init_ca.sh脚本

![img](../../picture/wps28.jpg)

![img](../../picture/wps29.jpg)

![img](../../picture/wps30.jpg)

![img](../../picture/wps31.jpg)

![img](../../picture/wps32.jpg)

### 1.2. **执行脚本**

```
./init_ca.sh
```

无报错输出目录树

![img](../../picture/wps33.jpg)

# 第二章 **操作节点脚本**

## 1. **start启动**

start启动节点, 启动脚本目录下所有docker容器yaml配置

```
./node_start_stop_restart_list_log_open.sh start
```

start启动指定节点, 多个用空格分开

```
./node_start_stop_restart_list_log_open.sh start orderer1.yaml orderer0.yaml
```

## 2. **stop**停止

stop停止节点, 停止脚本目录下所有docker容器yaml配置

 ```
./node_start_stop_restart_list_log_open.sh stop
 ```

stop停止指定节点, 多个用空格分开

 ```
./node_start_stop_restart_list_log_open.sh stop orderer1.yaml orderer0.yaml
 ```

## 3. **restart**重启

restart重启节点, 重启脚本目录下所有docker容器yaml配置

```
./node_start_stop_restart_list_log_open.sh restart
```

restart重启指定节点, 多个用空格分开

```
./node_start_stop_restart_list_log_open.sh restart orderer1.yaml orderer0.yaml
```

## 4. **list**查询

list查询所有启动的节点

```
./node_start_stop_restart_list_log_open.sh list
```

## 5. **log**日志

log查询所有节点日志

```
./node_start_stop_restart_list_log_open.sh log
```

log查询指定节点日志

```
./node_start_stop_restart_list_log_open.sh log orderer0.yaml
```

## 6. **open打开节点工具**

open打开cli客户端容器, 选择操作cli工具客户端

```
./node_start_stop_restart_list_log_open.sh open
```

## 7. **resetting重置**

重置区块链网络, 重置读取区块网络, 包括容器、通道、链码

```
./node_start_stop_restart_list_log_open.sh resetting
```

# 第三章 **操作通道脚本**

## 1. **init**初始化

init初始化通道, onechannel:通道名称

```
./channel_init_join_list_json_addorg_sign_update_config.sh init onechannel
```

![img](../../picture/wps34.jpg)

## 2. **join**加入通道

join加入通道, onechannel:通道名称

```
./channel_init_join_list_json_addorg_sign_update_config.sh join onechannel
```

**示例:**

每一个cli代表一个peer节点, 选择一个cli执行后续脚本

选择加入的节点, peer节点只能再对应的cli中加入

orderer节点可以选择任意一个cli执行加入, 只需要加入一次即可

![img](../../picture/wps35.jpg)

加入成功打印日志, peer 和 orderer会分别打印

![img](../../picture/wps36.jpg)

![img](../../picture/wps37.jpg)

![img](../../picture/wps38.jpg)

![img](../../picture/wps39.jpg)

继续重复执行加入节点, 选择剩余未执行的peer节点cli工具容器

![img](../../picture/wps40.jpg)

**重复以上步骤执行所有需要加入的peer节点**

## 3. **list查询加入通道的节点**

mychannel通道名称

```
./channel_init_join_list_json_addorg_sign_update_config.sh list mychannel
```

**示例:**

![img](../../picture/wps41.jpg)

## 4. **json获取最新通道json**

获取通道最新通道json、block文件

```
./channel_init_join_list_json_addorg_sign_update_config.sh json mychannel
```

![img](../../picture/wps42.jpg)

## 5. **addorg动态添加peer组织**

1. 获取通道最新通道json、block文件

```
./channel_init_join_list_json_addorg_sign_update_config.sh json mychannel
```

![img](../../picture/wps43.jpg)

2. 拷贝最新通道json、block文件到需要添加的组织的服务器

如果新加的组织在同一个服务器就不需要拷贝

```
scp ./channel-artifacts/mychannel.block root@192.168.1.16:/data/hyperledger/channel-artifacts/mychannel.block

scp ./channel-artifacts/mychannel.json root@192.168.1.16:/data/hyperledger/channel-artifacts/mychannel.json
```

3. configtx.yaml配置通道组织信息

例如:

```
  - &Org16
    Name: Org16
    ID: Org16MSP
    MSPDir: ./crypto-config/peerOrganizations/org16.bob.com/msp
    Policies:
      Readers:
        Type: Signature
        Rule: "OR('Org16MSP.member')"
      Writers:
        Type: Signature
        Rule: "OR('Org16MSP.member')"
      Admins:
        Type: Signature
        Rule: "OR('Org16MSP.admin')"
      # 背书策略, 只有经过身份验证的 Peer 节点才能对交易进行背书，从而保证了交易的安全性和可信度
      Endorsement:
        Type: Signature
        Rule: "OR('Org16MSP.peer')"
    AnchorPeers:
      - Host: peer0.org16.bob.com  # 锚节点的host地址
        Port: 7150     # 锚节点开放的端口号
```

4. 在新组织服务器执行addorg

```
./channel_init_join_list_json_addorg_sign_update_config.sh addorg mychannel
```

![img](../../picture/wps44.jpg)

5. 将addorg生成的更新json文件拷贝到有通道权限的背书节点服务器

如果是一台服务器, 就不需要拷贝, 输入y继续执行背书验证即可

```
./channel_init_join_list_json_addorg_sign_update_config.sh sign mychannel ./channel-artifacts/mychannel-addorg-Org16.json
```

![img](../../picture/wps45.jpg)

6. 将新组织的peer节点加入通道

```
./channel_init_join_list_json_addorg_sign_update_config.sh join mychannel 
```

![img](../../picture/wps46.jpg)

## 6. **更新通道配置**

1. 获取通道最新通道json、block文件

```
./channel_init_join_list_json_addorg_sign_update_config.sh json mychannel1
```

![img](../../picture/wps47.jpg)

2. 打开通道配置json文件, 修改通道配置

![img](../../picture/wps48.jpg)

3. 提交更新配置

```
./channel_init_join_list_json_addorg_sign_update_config.sh config mychannel1
```

![img](../../picture/wps49.jpg)

## 7. **sign 对更新配置签名**

```
./channel_init_join_list_json_addorg_sign_update_config.sh sign mychannel ./channel-artifacts/mychannel-addorg-Org16.json
```

![img](../../picture/wps50.jpg)

## 8. **update 更新签名配置**

```
./channel_init_join_list_json_addorg_sign_update_config.sh update mychannel ./channel-artifacts/mychannel-addorg-Org16.json
```

# 第四章 **操作链码脚本**

脚本内包含dnsConfig="xinhe.com"的固定配置

用于配置证书等动态域名使用

例如:

脚本: ordererOrganizations/dnsConfig/msp/tlscacerts/tlsca.dnsConfig-cert.pem

替换: ordererOrganizations/xinhe.com/msp/tlscacerts/tlsca.xinhe.com-cert.pem

## 1. **install**安装/升级

install安装/升级链码

onechannel: 通道名称, onecc:链码名称 1.0:版本 1:版本号

默认版本1.0和版本号1, 升级一个存在的链码时, 需要指定版本和版本号

注: 版本号全局唯一, 每升级一次应该手动递增+1

```
./chaincode_install_commit_invoke_query_info.sh install onechannel onecc 1.0 1
```

升级/更新onecc链码时, 版本号手动递增+1:

```
./chaincode_install_commit_invoke_query_info.sh install onechannel onecc 1.0 2
```

**示例:**

理论上安装链码需要各个组织内超过半数peer节点批准同意

我们更改了权限,只需要一个就可以

这里选择多个做示范, 可以只选择一个

![img](../../picture/wps51.jpg)

安装完成, 每个cli会打印安装的链码日志和链码的唯一编号

后补步骤

![img](../../picture/wps52.jpg)

![img](../../picture/wps53.jpg)

理论上需要所有msp都为true才可以提交到通道运行, 我们更改了权限, 只需要一个msp为true就可以提交到通道运行了

![img](../../picture/wps54.jpg)

选择y可以继续执行commit提交链码到通道运行

可以单独执行commit提交, 看下面commit提交功能

## 2. **commit**提交

commit提交链码到通道, 注意版本和版本号与安装时对应

```
./chaincode_install_commit_invoke_query_info.sh commit onechannel onecc 1.0 1
```

**示例:**

参数通道名称、链码名称、版本、版本号

提交链码到通道只需要选择一个peer节点的cli工具类即可

![img](../../picture/wps55.jpg)

第一次提交一个新链码会有初始化, 保存了一条默认数据,后面可以使用query查询

之后升级/更新这个链码, 不会初始化

## 3. **query查询链码记录**

query查询链码记录

onechannel:通道名称, onecc:链码名称, [\"queryCat\",\"cat-1\"]: 链码参数

queryCat: 链码中的方法名称, cat-1: 记录id

```
./chaincode_install_commit_invoke_query_info.sh query onechannel onecc [\"queryCat\",\"cat-1\"]
```

**示例:**

![img](../../picture/wps56.jpg)

## 4. **invoke**调用链码

invoke调用链码, 执行链码方法, 加入一条测试记录

createCat: 链码方法名称, [\"cat-2\",\"tom\",\"3\",\"红色\",\"小懒猫\"]: 参数

cat-2: 记录id

```
./chaincode_install_commit_invoke_query_info.sh invoke onechannel onecc createCat  [\"cat-2\",\"tom\",\"3\",\"红色\",\"小懒猫\"]
```

**示例**

注意: 记录id是唯一的, 不可重复, 默认存在一条cat-1不可再存

![img](../../picture/wps57.jpg)

此时已经创建成功一条id=cat-2的记录

使用query 查询这条记录

```
./chaincode_install_commit_invoke_query_info.sh query onechannel onecc [\"queryCat\",\"cat-2\"]
```

![img](../../picture/wps58.jpg)

## 5. **info**链码信息

info链码信息, 查看链码版本等信息

```
./chaincode_install_commit_invoke_query_info.sh info onechannel
```

**示例:**

查询通道内所有运行中的链码信息

![img](../../picture/wps59.jpg)

# 脚本附录

## init_ca.sh

```sh
#!/bin/bash
# author luode

###########           脚本配置开始 ↓            ################
#############通用配置###################
# ca节点挂载目录|节点自签根证书(中间ca使用证书链)|tls自签证书|证书生成目录
CaHome=/data/hyperledger/tls-ca # ca服务器挂载目录
CaCert=/data/hyperledger/tls-ca/crypto/ca-cert.pem # ca服务器自签根证书
#CaCert=/data/hyperledger/tls-ca/crypto/ca-chain.pem # ca服务器自签证书链(当且仅当 此ca不是顶级ca服务器,属于下级服务器时配置)
TlsCaCert=/data/hyperledger/tls-ca/crypto/tls-cert.pem # ca服务器自签tls证书
OutputConfig=/data/hyperledger/crypto-config # 证书生成输出目录
#######################################

################本地ca###################
# ca用户名|密码|ca主机|端口
CaUserName="admin" # ca服务器的用户名, 此配置是ca启动yaml配置中配置的
CaPassWord="adminpw" # ca服务器的密码, 此配置是ca启动yaml配置中配置的
CaHostname="0.0.0.0" # ca服务器的ip, 本机使用0.0.0.0即可
CaPort="7054" # ca服务器的端口
#######################################

################peer###################
# 定义 Peer 数组 
# "组织|域名|主机名|ca节点|组织普通用户数量(同一个域名取最大值)"
PeerOrgs=(
  "com.cndtcloud.org1|org1.cndtcloud.com|peer0|0.0.0.0:7054|1"
  "com.cndtcloud.org1|org1.cndtcloud.com|peer1|0.0.0.0:7054|1"
 )
# 注: 一个域名下只能有一个peer组织, 可以有多个主机名
# 	- org1.cndtcloud.com域名下存在com.cndtcloud.org1组织, 再次定义com.cndtcloud.org2会覆盖之前的com.cndtcloud.org1
#######################################

################order##################
# 定义 Orderer 数组 
# "组织|域名|主机名|ca节点(本机节点使用0.0.0.0,外部ca需要配置Other)|组织普通用户数量(取最大值)"
OrdererOrgs=(
  "com.cndtcloud.OrdererOrg|cndtcloud.com|orderer0|0.0.0.0:7054|0"
  "com.cndtcloud.OrdererOrg|cndtcloud.com|orderer1|0.0.0.0:7054|0"
  "com.cndtcloud.OrdererOrg|cndtcloud.com|orderer2|0.0.0.0:7054|0"
)
# 注: 一个域名下只能有一个orderer组织, 可以有多个主机名
#  -> cndtcloud.com域名下存在com.cndtcloud.OrdererOrg组织, 再次定义com.cndtcloud.OrdererOrg2会覆盖之前的com.cndtcloud.OrdererOrg
#######################################

################ Other 外部ca ###########
# 当且仅当 orderer 配置ca节点不为 0.0.0.0 时生效, 配置连接外部ca节点ip地址
OtherCaCert=/data/hyperledger/tls-ca/root-ca-cert.pem # 外部ca节点ca证书
OtherKey=/data/hyperledger/tls-ca/root-priv-sk # 外部ca节点ca证书私钥
OtherTlsCaCert=/data/hyperledger/tls-ca/root-tls-cert.pem # 外部ca节点tls证书私钥
OtherTlsKey=/data/hyperledger/tls-ca/root-tls-priv-sk # 外部ca节点tls证书私钥
OtherUserName="admin.OrdererOrg" # 用户名通过ca服务器数据表users获取管理员id
OtherPassWord="adminPW" # 密码统一为adminPw
#######################################

###########           脚本配置结束 ↑            ################

envCa(){
      # ca节点根证书|ca节点签名证书目录
      export FABRIC_CA_CLIENT_TLS_CERTFILES=${TlsCaCert}
      export FABRIC_CA_CLIENT_HOME=${CaHome}/admin
}

#注册
registerUser() {
    envCa
    rm -rf ${CaHome}/admin/
		fabric-ca-client enroll -d -u https://${CaUserName}:${CaPassWord}@${CaHostname}:${CaPort} 2>&1 | grep -E "^Error: " | grep -v -E "already exists|already registered"
}

# 查询ca服务器私钥, 并重命名私钥
renamePrivateKey() {
    # 遍历keystore文件夹下的所有密钥文件
    for private_key_file in ${CaHome}/crypto/msp/keystore/*; do
        file_name=$(basename "$private_key_file")
        # 检查文件名是否需要排除
        if [ "$file_name" = "IssuerRevocationPrivateKey" ] || [ "$file_name" = "IssuerSecretKey" ] || [ "$file_name" = "priv_ca_sk" ] || [ "$file_name" = "priv_tls_ca_sk" ]  ; then
            continue
        fi

        # 获取私钥的公钥
        private_key_pub=$(openssl ec -in ${CaHome}/crypto/msp/keystore/$file_name -pubout 2>/dev/null)

        # 获取根证书的公钥
        certificate_pub=$(openssl x509 -in ${CaCert} -noout -pubkey 2>/dev/null)

        # 比较公钥是否相同
        if [ "$private_key_pub" = "$certificate_pub" ]; then
            # 重命名密钥文件为priv_ca_sk
            mv -f "${CaHome}/crypto/msp/keystore/$file_name" "${CaHome}/crypto/msp/keystore/priv_ca_sk"
        fi

        # 获取tls证书的公钥
        tls_certificate_pub=$(openssl x509 -in ${TlsCaCert} -noout -pubkey)
        # 比较公钥是否相同
        if [ "$private_key_pub" = "$tls_certificate_pub" ]; then
            # 重命名密钥文件为priv_tls_ca_sk
            mv -f "${CaHome}/crypto/msp/keystore/$file_name" "${CaHome}/crypto/msp/keystore/priv_tls_ca_sk"
        fi
    done
}

# 动态创建证书目录结构
creatDirectory() {
    # 固定创建
    mkdir -p ${OutputConfig}/${orgDirectory}/$orgDNS/ca
    mkdir -p ${OutputConfig}/${orgDirectory}/$orgDNS/msp/admincerts
    mkdir -p ${OutputConfig}/${orgDirectory}/$orgDNS/msp/cacerts
    mkdir -p ${OutputConfig}/${orgDirectory}/$orgDNS/msp/tlscacerts
    mkdir -p ${OutputConfig}/${orgDirectory}/$orgDNS/tlsca

    # 动态创建
    mkdir -p ${adjustmentNameHome}/msp/admincerts
    mkdir -p ${adjustmentNameHome}/msp/tlscacerts
}

# 创建组织
creatOrg(){
  # 是否启用外部ca, 启用不创建组织
  if [[ "${orgCa}" != *0.0.0.0* ]]; then
    return
  fi
  # 拆分组织名称为层级数组
  IFS='.' read -ra orgLevels <<< "$org"

  # 创建组织关联
  affiliation=""
  for level in "${orgLevels[@]}"; do
    if [ -z "$affiliation" ]; then
      affiliation="$level"
    else
      affiliation="$affiliation.$level"
    fi
    fabric-ca-client affiliation add ${affiliation} -u https://${orgCa} 2>&1 | grep -E "^Error: " | grep -v -E "already exists|already registered"
  done
}

# 创建管理员,节点用户,普通用户, 并生成用户证书
creatAdminUser() {
  # 是否启用外部ca, 启用外部则只生成管理员证书
    if [[ "${orgCa}" != *0.0.0.0* ]]; then
      generateAdmin $orgDNS $org $orgCa $orgDirectory
      return
    fi
    fabric-ca-client register -d --id.name admin.${org}  --id.affiliation ${org} --id.secret adminPW --id.type admin -u https://${orgCa} --id.attrs "hf.Registrar.Roles=*,hf.Registrar.DelegateRoles=*,hf.AffiliationMgr=true,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert" 2>&1 | grep -E "^Error: " | grep -v -E "already exists|already registered"
    generateAdmin $orgDNS $org $orgCa $orgDirectory
    fabric-ca-client register -d --id.name ${orgHostname}.${orgDNS} --id.affiliation ${org} --id.secret ${orgNode}PW --id.type ${orgNode} -u https://${orgCa} 2>&1 | grep -E "^Error: " | grep -v -E "already exists|already registered"
    # todo 没有生成节点用户证书
    #generateNode
    for((i=1;i<=$orgUser;i++))
    do
        fabric-ca-client register -d --id.name user${i}.${org} --id.affiliation ${org} --id.secret userPW --id.type user -u https://${orgCa} --id.attrs "hf.Registrar.Roles=*,hf.Registrar.DelegateRoles=*,hf.AffiliationMgr=true,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert" 2>&1 | grep -E "^Error: " | grep -v -E "already exists|already registered"
        generateUser $orgDNS $org $orgCa $orgDirectory $i
    done
}

# 生成管理员证书
generateAdmin(){
    # 删除旧数据
    rm -rf ${OutputConfig}/${orgDirectory}/$orgDNS/users/Admin@$orgDNS
    # 定义起始目录
    adjustmentNameHome=${OutputConfig}/${orgDirectory}/$orgDNS/users/Admin@$orgDNS
    # 创建证书目录结构
    creatDirectory $orgDirectory $orgDNS $orgNodes $orgHostname $adjustmentNameHome

    # 保存初始环境变量
    CLIENT_HOME=${FABRIC_CA_CLIENT_HOME}
    CLIENT_TLS_CERTFILES=${FABRIC_CA_CLIENT_TLS_CERTFILES}
    CLIENT_MSPDIR=${FABRIC_CA_CLIENT_MSPDIR}
    CLIENT_CERTFILE=${FABRIC_CA_CLIENT_TLS_CLIENT_CERTFILE}
    CLIENT_KEYFILE=${FABRIC_CA_CLIENT_TLS_CLIENT_KEYFILE}

		# org 管理员证书
		export FABRIC_CA_CLIENT_HOME=$adjustmentNameHome
		export FABRIC_CA_CLIENT_TLS_CERTFILES=${TlsCaCert}
		export FABRIC_CA_CLIENT_MSPDIR=msp
    # 是否启用外部ca
    if [[ "${orgCa}" != *0.0.0.0* ]]; then
      export FABRIC_CA_CLIENT_TLS_CERTFILES=${OtherTlsCaCert}
      export FABRIC_CA_CLIENT_TLS_CLIENT_CERTFILE=${OtherCaCert}
      export FABRIC_CA_CLIENT_TLS_CLIENT_KEYFILE=${OtherKey}
		  fabric-ca-client enroll -d -u https://${OtherUserName}:${OtherPassWord}@$orgCa 2>&1 | grep -E "^Error: "
    else
		  fabric-ca-client enroll -d -u https://admin.${org}:adminPW@$orgCa 2>&1 | grep -E "^Error: "
    fi

		# org 管理员tls证书
		export FABRIC_CA_CLIENT_HOME=$adjustmentNameHome
		export FABRIC_CA_CLIENT_TLS_CERTFILES=${TlsCaCert}
		export FABRIC_CA_CLIENT_MSPDIR=tls
    # 是否启用外部ca
    if [[ "${orgCa}" != *0.0.0.0* ]]; then
      export FABRIC_CA_CLIENT_TLS_CERTFILES=${OtherTlsCaCert}
      export FABRIC_CA_CLIENT_TLS_CLIENT_CERTFILE=${OtherCaCert}
      export FABRIC_CA_CLIENT_TLS_CLIENT_KEYFILE=${OtherKey}
		  fabric-ca-client enroll -d -u https://${OtherUserName}:${OtherPassWord}@$orgCa  --enrollment.profile tls 2>&1 | grep -E "^Error: "
    else
		  fabric-ca-client enroll -d -u https://admin.${org}:adminPW@$orgCa  --enrollment.profile tls 2>&1 | grep -E "^Error: "
    fi

    # 还原初始环境变量
    export FABRIC_CA_CLIENT_HOME=${CLIENT_HOME}
    export FABRIC_CA_CLIENT_TLS_CERTFILES=${CLIENT_TLS_CERTFILES}
    export FABRIC_CA_CLIENT_MSPDIR=${CLIENT_MSPDIR}
    export FABRIC_CA_CLIENT_TLS_CLIENT_CERTFILE=${CLIENT_CERTFILE}
    export FABRIC_CA_CLIENT_TLS_CLIENT_KEYFILE=${CLIENT_KEYFILE}

    # 调整证书、私钥名称
    # 定义前缀|调整的起始目录
    adjustmentNameType="Admin@"
    adjustmentName $orgDNS $orgHostname $orgNodes $orgCa $orgDirectory $adjustmentNameHome $adjustmentNameType

    ###########管理员 admincerts 目录证书############
    cp -f ${adjustmentNameHome}/msp/signcerts/* ${adjustmentNameHome}/msp/admincerts/
    ###########        外层msp目录      ###########
    cp -f ${adjustmentNameHome}/msp/admincerts/* ${OutputConfig}/${orgDirectory}/$orgDNS/msp/admincerts/
    cp -f ${adjustmentNameHome}/msp/cacerts/* ${OutputConfig}/${orgDirectory}/$orgDNS/msp/cacerts/
    cp -f ${adjustmentNameHome}/msp/tlscacerts/* ${OutputConfig}/${orgDirectory}/$orgDNS/msp/tlscacerts/
    # 是否启用外部ca
    if [[ "${orgCa}" != *0.0.0.0* ]]; then
      ###########        外层ca目录       ###########
      cp -f ${OtherCaCert} ${OutputConfig}/${orgDirectory}/$orgDNS/ca/ca.${orgDNS}-cert.pem
      cp -f ${OtherKey} ${OutputConfig}/${orgDirectory}/$orgDNS/ca/priv_sk
      ###########        外层tls目录       ###########
      cp -f ${OtherTlsCaCert} ${OutputConfig}/${orgDirectory}/$orgDNS/tlsca/tlsca.${orgDNS}-cert.pem
      cp -f ${OtherTlsKey} ${OutputConfig}/${orgDirectory}/$orgDNS/tlsca/priv_sk
    else
      ###########        外层ca目录       ###########
      cp -f ${CaCert} ${OutputConfig}/${orgDirectory}/$orgDNS/ca/ca.${orgDNS}-cert.pem
      cp -f ${CaHome}/crypto/msp/keystore/priv_ca_sk ${OutputConfig}/${orgDirectory}/$orgDNS/ca/priv_sk
      ###########        外层tls目录       ###########
      cp -f ${TlsCaCert} ${OutputConfig}/${orgDirectory}/$orgDNS/tlsca/tlsca.${orgDNS}-cert.pem
      cp -f ${CaHome}/crypto/msp/keystore/priv_tls_ca_sk ${OutputConfig}/${orgDirectory}/$orgDNS/tlsca/priv_sk
    fi

		# 编写 admin config.yaml 文件
		tee ${adjustmentNameHome}/msp/config.yaml  <<-EOF > /dev/null
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/ca.${orgDNS}-cert.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/ca.${orgDNS}-cert.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/ca.${orgDNS}-cert.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/ca.${orgDNS}-cert.pem
    OrganizationalUnitIdentifier: orderer
EOF

		# 编写外层 msp config.yaml 文件
		tee ${OutputConfig}/${orgDirectory}/$orgDNS/msp/config.yaml  <<-EOF > /dev/null
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/ca.${orgDNS}-cert.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/ca.${orgDNS}-cert.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/ca.${orgDNS}-cert.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/ca.${orgDNS}-cert.pem
    OrganizationalUnitIdentifier: orderer
EOF
}

# 生成普通用户证书
generateUser(){
    # 删除旧数据
    rm -rf ${OutputConfig}/${orgDirectory}/$orgDNS/users/User${i}@$orgDNS
    # 定义起始目录
    adjustmentNameHome=${OutputConfig}/${orgDirectory}/$orgDNS/users/User${i}@$orgDNS
    # 创建证书目录结构
    creatDirectory $orgDirectory $orgDNS $orgNodes $orgHostname $adjustmentNameHome

    # 保存初始环境变量
    CLIENT_HOME=${FABRIC_CA_CLIENT_HOME}
    CLIENT_TLS_CERTFILES=${FABRIC_CA_CLIENT_TLS_CERTFILES}
    CLIENT_MSPDIR=${FABRIC_CA_CLIENT_MSPDIR}

		# org 普通用户证书
		export FABRIC_CA_CLIENT_HOME=$adjustmentNameHome
		export FABRIC_CA_CLIENT_TLS_CERTFILES=${TlsCaCert}
		export FABRIC_CA_CLIENT_MSPDIR=msp
		fabric-ca-client enroll -d -u https://user${i}.${org}:userPW@$orgCa 2>&1 | grep -E "^Error: "

		# org 普通用户tls证书
		export FABRIC_CA_CLIENT_HOME=$adjustmentNameHome
		export FABRIC_CA_CLIENT_TLS_CERTFILES=${TlsCaCert}
		export FABRIC_CA_CLIENT_MSPDIR=tls
		fabric-ca-client enroll -d -u https://user${i}.${org}:userPW@$orgCa  --enrollment.profile tls 2>&1 | grep -E "^Error: "

    # 还原初始环境变量
    export FABRIC_CA_CLIENT_HOME=${CLIENT_HOME}
    export FABRIC_CA_CLIENT_TLS_CERTFILES=${CLIENT_TLS_CERTFILES}
    export FABRIC_CA_CLIENT_MSPDIR=${CLIENT_MSPDIR}

    # 调整证书、私钥名称
    # 定义 signcerts 前缀|调整的起始目录
    adjustmentNameType="User${i}@"
    adjustmentName $orgDNS $orgHostname $orgNodes $orgCa $orgDirectory $adjustmentNameHome $adjustmentNameType

    ###########copy 管理员证书############
    cp -f ${OutputConfig}/${orgDirectory}/$orgDNS/users/Admin@$orgDNS/msp/admincerts/* ${adjustmentNameHome}/msp/admincerts/

		# 编写 config.yaml 文件
		tee ${adjustmentNameHome}/msp/config.yaml  <<-EOF > /dev/null
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/ca.${orgDNS}-cert.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/ca.${orgDNS}-cert.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/ca.${orgDNS}-cert.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/ca.${orgDNS}-cert.pem
    OrganizationalUnitIdentifier: orderer
EOF
}

# 节点证书生成
generateNode() {
    # 删除旧数据
    rm -rf ${OutputConfig}/${orgDirectory}/$orgDNS/$orgNodes/${orgHostname}.${orgDNS}
    #起始目录
    adjustmentNameHome=${OutputConfig}/${orgDirectory}/$orgDNS/$orgNodes/${orgHostname}.${orgDNS}
    # 创建证书目录结构
    creatDirectory $orgDirectory $orgDNS $orgNodes $orgHostname $adjustmentNameHome

    # 保存初始环境变量
    CLIENT_HOME=${FABRIC_CA_CLIENT_HOME}
    CLIENT_TLS_CERTFILES=${FABRIC_CA_CLIENT_TLS_CERTFILES}
    CLIENT_MSPDIR=${FABRIC_CA_CLIENT_MSPDIR}
    CLIENT_CERTFILE=${FABRIC_CA_CLIENT_TLS_CLIENT_CERTFILE}
    CLIENT_KEYFILE=${FABRIC_CA_CLIENT_TLS_CLIENT_KEYFILE}

    # 申请Cert 证书
    export FABRIC_CA_CLIENT_HOME=$adjustmentNameHome
    export FABRIC_CA_CLIENT_TLS_CERTFILES=${TlsCaCert}
    export FABRIC_CA_CLIENT_MSPDIR=msp

    # 是否启用外部ca
    if [[ "${orgCa}" != *0.0.0.0* ]]; then
      export FABRIC_CA_CLIENT_TLS_CERTFILES=${OtherTlsCaCert}
      export FABRIC_CA_CLIENT_TLS_CLIENT_CERTFILE=${OtherCaCert}
      export FABRIC_CA_CLIENT_TLS_CLIENT_KEYFILE=${OtherKey}
    fi

    if [ "${orgDirectory}" = "peerOrganizations" ]; then
      fabric-ca-client enroll -d -u https://${orgHostname}.${orgDNS}:${orgNode}PW@$orgCa 2>&1 | grep -E "^Error: "
    else
      fabric-ca-client enroll -d -u https://${orgHostname}.${orgDNS}:${orgNode}PW@$orgCa --csr.hosts "${orgHostname}.${orgDNS},${orgHostname}" 2>&1 | grep -E "^Error: "
    fi

    # 申请TLS 证书
    export FABRIC_CA_CLIENT_HOME=$adjustmentNameHome
    export FABRIC_CA_CLIENT_TLS_CERTFILES=${TlsCaCert}
    export FABRIC_CA_CLIENT_MSPDIR=tls

    # 是否启用外部ca
    if [[ "${orgCa}" != *0.0.0.0* ]]; then
      export FABRIC_CA_CLIENT_TLS_CERTFILES=${OtherTlsCaCert}
      export FABRIC_CA_CLIENT_TLS_CLIENT_CERTFILE=${OtherCaCert}
      export FABRIC_CA_CLIENT_TLS_CLIENT_KEYFILE=${OtherKey}
    fi

    if [ "${orgDirectory}" = "peerOrganizations" ]; then
      fabric-ca-client enroll -d -u https://${orgHostname}.${orgDNS}:${orgNode}PW@$orgCa  --enrollment.profile tls --csr.hosts "${orgHostname}.${orgDNS}" 2>&1 | grep -E "^Error: "
    else
      fabric-ca-client enroll -d -u https://${orgHostname}.${orgDNS}:${orgNode}PW@$orgCa  --enrollment.profile tls --csr.hosts "${orgHostname}.${orgDNS},${orgHostname}" 2>&1 | grep -E "^Error: "
    fi

    # 还原初始环境变量
    export FABRIC_CA_CLIENT_HOME=${CLIENT_HOME}
    export FABRIC_CA_CLIENT_TLS_CERTFILES=${CLIENT_TLS_CERTFILES}
    export FABRIC_CA_CLIENT_MSPDIR=${CLIENT_MSPDIR}
    export FABRIC_CA_CLIENT_TLS_CLIENT_CERTFILE=${CLIENT_CERTFILE}
    export FABRIC_CA_CLIENT_TLS_CLIENT_KEYFILE=${CLIENT_KEYFILE}

    # 调整证书、私钥名称
    # 定义前缀|调整的起始目录
    adjustmentNameType="${orgHostname}."
    adjustmentName $orgDNS $orgHostname $orgNodes $orgCa $orgDirectory $adjustmentNameHome $adjustmentNameType

    ###########copy 管理员证书############
    cp -f ${OutputConfig}/${orgDirectory}/$orgDNS/users/Admin@$orgDNS/msp/admincerts/* ${adjustmentNameHome}/msp/admincerts/

		# 编写 config.yaml 文件
		tee ${adjustmentNameHome}/msp/config.yaml  <<-EOF > /dev/null
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/ca.${orgDNS}-cert.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/ca.${orgDNS}-cert.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/ca.${orgDNS}-cert.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/ca.${orgDNS}-cert.pem
    OrganizationalUnitIdentifier: orderer
EOF
}

# 调整证书、私钥名称
adjustmentName(){
    # 0.0.0.0:7054 替换 0-0-0-0-7054
    newOrgCa=$(echo "$orgCa" | sed 's/\./-/g; s/:/-/')

    # 删除 msp/cacerts 目录证书, 重新copy自签证书到 msp/cacerts 目录, , 如果是中间ca, 则copy的是证书链
    rm -rf ${adjustmentNameHome}/msp/cacerts/${newOrgCa}.pem

    # 是否启用外部ca
    if [[ "${orgCa}" != *0.0.0.0* ]]; then
      # 复制节点自签根证书到 msp/cacerts 目录, 如果是中间ca, 则复制的是证书链
      cp -f ${OtherCaCert} ${adjustmentNameHome}/msp/cacerts/ca.${orgDNS}-cert.pem
      # 复制节点自签根证书到 msp/tlscacerts 目录, 如果是中间ca, 则复制的是证书链
      cp -f ${OtherCaCert} ${adjustmentNameHome}/msp/tlscacerts/tlsca.${orgDNS}-cert.pem
    else
      cp -f ${CaCert} ${adjustmentNameHome}/msp/cacerts/ca.${orgDNS}-cert.pem
      # 复制节点自签根证书到 msp/tlscacerts 目录, 如果是中间ca, 则复制的是证书链
      cp -f ${CaCert} ${adjustmentNameHome}/msp/tlscacerts/tlsca.${orgDNS}-cert.pem
    fi

    # 重命名 intermediatecerts 中间证书
    mv ${adjustmentNameHome}/msp/intermediatecerts/${newOrgCa}.pem ${adjustmentNameHome}/msp/intermediatecerts/intermediatecerts.${orgDNS}-cert.pem 2>&1 | grep -E "^Error"
    # 重命名 signcerts 签名证书
    mv ${adjustmentNameHome}/msp/signcerts/cert.pem ${adjustmentNameHome}/msp/signcerts/${adjustmentNameType}${orgDNS}-cert.pem
    # 重命名 keystore 私钥
    mv ${adjustmentNameHome}/msp/keystore/*_sk ${adjustmentNameHome}/msp/keystore/priv_sk

    ###########构建 tls 目录的 ca.crt、server.crt、server.key############
    # 是否启用外部ca
    if [[ "${orgCa}" != *0.0.0.0* ]]; then
      # 复制节点自签根证书到 ca.crt, 如果是中间ca, 则复制的是证书链
      cp -f ${OtherCaCert} ${adjustmentNameHome}/tls/ca.crt
    else
      # 复制节点自签根证书到 ca.crt, 如果是中间ca, 则复制的是证书链
      cp -f ${CaCert} ${adjustmentNameHome}/tls/ca.crt
    fi
    cp -f ${adjustmentNameHome}/tls/signcerts/cert.pem ${adjustmentNameHome}/tls/server.crt
    cp -f ${adjustmentNameHome}/tls/keystore/*_sk ${adjustmentNameHome}/tls/server.key
    # 删除tls目录中除了ca.crt、server.crt和server.key这三个文件之外的所有文件和文件夹
    find ${adjustmentNameHome}/tls -mindepth 1 -type f -not \( -name "ca.crt" -o -name "server.crt" -o -name "server.key" \) -exec rm {} +
    find ${adjustmentNameHome}/tls -mindepth 1 -type d -not \( -name "ca.crt" -o -name "server.crt" -o -name "server.key" \) -exec rm -r {} +

    ####################验证证书-开始####################
    if [ -f "${adjustmentNameHome}/msp/cacerts/ca.${orgDNS}-cert.pem" ] && [ -f "${adjustmentNameHome}/msp/intermediatecerts/intermediatecerts.${orgDNS}-cert.pem" ]; then
        openssl verify -verbose -CAfile "${adjustmentNameHome}/msp/cacerts/ca.${orgDNS}-cert.pem" "${adjustmentNameHome}/msp/intermediatecerts/intermediatecerts.${orgDNS}-cert.pem" 2>&1 | grep -v -E "OK"
    fi
    openssl verify -verbose -CAfile ${adjustmentNameHome}/msp/cacerts/ca.${orgDNS}-cert.pem ${adjustmentNameHome}/msp/signcerts/${adjustmentNameType}${orgDNS}-cert.pem 2>&1 | grep -v -E "OK"
    openssl verify -verbose -CAfile ${adjustmentNameHome}/tls/ca.crt ${adjustmentNameHome}/tls/server.crt 2>&1 | grep -v -E "OK"
    ####################验证证书-结束####################
}

#生成证书
gainCert() {

  # 循环遍历 PeerOrgs
  for key in "${PeerOrgs[@]}"; do
    orgNode="peer"
    orgNodes="peers"
    orgDirectory="peerOrganizations"
    # 使用冒号分隔符将域名和主机名拆分为变量
    IFS="|" read -r org orgDNS orgHostname orgCa orgUser <<< "$key"
    echo "----------------"
    echo "节点: $orgNode"
    echo "组织: $org"
    echo "组织普通用户数量: $orgUser"
    echo "域名: $orgDNS"
    echo "主机名: $orgHostname"
    echo "ca节点: $orgCa"
    echo "----------------"

    # 创建组织
    creatOrg $org $orgCa $orgDirectory
    # 创建管理员,节点用户,普通用户, 并生成用户证书
    creatAdminUser $org $orgNode $orgDNS $orgHostname $orgCa $orgUser $orgDirectory
    # 生成节点证书
    generateNode $orgDirectory $orgDNS $orgNode $orgNodes $orgHostname
  done

  # 循环遍历 OrdererOrgs
  for key in "${OrdererOrgs[@]}"; do
    orgNode="orderer"
    orgNodes="orderers"
    orgDirectory="ordererOrganizations"
    # 使用冒号分隔符将域名和主机名拆分为变量
    IFS="|" read -r org orgDNS orgHostname orgCa orgUser <<< "$key"
    echo "----------------"
    echo "节点: $orgNode"
    echo "组织: $org"
    echo "组织普通用户数量: $orgUser"
    echo "域名: $orgDNS"
    echo "主机名: $orgHostname"
    echo "ca节点: $orgCa"
    echo "----------------"

    # 创建组织
    creatOrg $org $orgCa $orgDirectory
    # 创建管理员|节点用户|普通用户, 并生成证书
    creatAdminUser $org $orgNode $orgDNS $orgHostname $orgCa $orgUser $orgDirectory
    # 生成节点证书
    generateNode $orgDirectory $orgDNS $orgNode $orgNodes $orgHostname
  done
  tree ${OutputConfig}
}

renamePrivateKey
registerUser
gainCert

#installFun
#echo $?
#sourceFun
#closeFire
#installDocker 5
#inittrustedChain

```

## node_start_stop_restart_list_log_open.sh

```sh
#!/bin/bash
# author 罗德

#./xx.sh start/stop/restart/list 操作当前目录下的docker-compose.yaml

#例: 
#支持一次性操作多个 -> ./xx.sh start orderer0.yaml orderer1.yaml orderer2.yaml
#当前目录下全部docker-compose.yaml -> ./xx.sh start
#stop、restart同理
#查询节点,输出名称、端口、状态3个字段 -> ./xx.sh list

# 流程控制 start=创建并启动节点 stop=停止节点 restart=重启 resetting=重置当前区块链网络
# 还可以查询当前启动的容器./xx.sh list
process=$1

# 节点配置文件
# 可以启动/停止/重启多个./xx.sh start/stop/restart configPath1.yaml configPath2.yaml
configPaths=("${@:2}")

# 启动节点
startNode() {
    if [ ${#configPaths[@]} -eq 0 ]; then
        read -p $'没有指定要启动的节点配置文件，是否要启动当前目录下所有yaml配置\n可能会执行到不属于docker-compose的yaml配置, 输出部分异常信息？[y/n] ' choice
        if [ "$choice" == "y" ]; then
            configPaths=($(ls *.yaml))
        else
            exit 1
        fi
    fi
    
    checkConfigFiles
	for configPath in "${configPaths[@]}"; do
		docker-compose -f "$configPath" up -d
		if [ $? -eq 0 ]; then
			echo "节点 $(basename "$configPath" .yaml) 启动成功"
		else
			echo "节点 $(basename "$configPath" .yaml) 启动失败"
		fi
	done
	listNode
}


# 停止节点
stopNode() {
    if [ ${#configPaths[@]} -eq 0 ]; then
        read -p  $'没有指定要停止的节点配置文件，是否要停止当前目录下所有yaml配置\n可能会执行到不属于docker-compose的yaml配置, 输出部分异常信息？[y/n] ' choice
        if [ "$choice" == "y" ]; then
            configPaths=($(ls *.yaml))
        else
            exit 1
        fi
    fi
    
    checkConfigFiles
    
    for configPath in "${configPaths[@]}"; do
		docker-compose -f "$configPath" stop
		if [ $? -eq 0 ]; then
			echo "节点 $(basename "$configPath" .yaml) 停止成功"
		else
			echo "节点 $(basename "$configPath" .yaml) 停止失败"
		fi
    done
    listNode
}

# 卸载节点
downNode() {
    for configPath in "${configPaths[@]}"; do
		docker-compose -f "$configPath" down
		if [ $? -eq 0 ]; then
			echo "节点 $(basename "$configPath" .yaml) 卸载成功"
		else
			echo "节点 $(basename "$configPath" .yaml) 卸载异常"
		fi
    done
}

# 重启节点
restartNode() {
    for configPath in "${configPaths[@]}"; do
		docker-compose -f "$configPath" restart
		if [ $? -eq 0 ]; then
			echo "节点 $(basename "$configPath" .yaml) 重启成功"
		else
			echo "节点 $(basename "$configPath" .yaml) 重启失败"
		fi
    done
    listNode
}

# 查询docker
listNode() {
   docker ps --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}"
}

# 重置网络
resettingNode() {
        read -p  $'你将重置当前节点的信息,容器节点、通道链码配置将会删除\n是否继续？[y/n] ' choice
        if [ "$choice" == "y" ]; then
			read -p  $'你将重置当前节点的信息,容器节点、通道链码配置将会删除\n再次确认是否继续？[y/n] ' choice
			if [ "$choice" == "y" ]; then
					configPaths=($(ls *.yaml))
				    for configPath in "${configPaths[@]}"; do
						docker-compose -f "$configPath" down
						if [ $? -eq 0 ]; then
							echo "节点 $(basename "$configPath" .yaml) 卸载成功"
						else
							echo "节点 $(basename "$configPath" .yaml) 卸载异常"
						fi
					done
			else
				exit 1
			fi
        else
            exit 1
        fi
    
    echo "重置网络完成, 你可以通过 ./xx.sh start 命令重新部署节点, 重新配置通道、链码等信息"
    read -p  $'重新start部署节点,是否继续？[y/n] ' choice
	if [ "$choice" == "y" ]; then
		startNode
	else
		exit 1
	fi
}

# 打开容器
openNode() {
	echo "运行中的客户端工具容器："
	docker ps --filter "name=cli*" --format "table {{.Names}}"
	# 获取第一个容器名称
	container_name=$(docker ps --filter "name=cli*" --format "{{.Names}}" | head -n 1)

	# 读取用户输入的容器名称，如果用户没有输入，则使用第一个容器名称
	read  -e -i "$container_name" -p "请选择加入了通道的peer客户端：" input_container_name
	container_name=${input_container_name:-$container_name}
	
	docker exec -it $container_name bash
}

# 查询日志
logNode() {
    if [ ${#configPaths[@]} -eq 0 ]; then
        docker-compose -f org1-peer0.yaml -f org1-peer1.yaml -f org2-peer0.yaml -f org2-peer1.yaml logs -f
        exit 1
    fi
    for configPath in "${configPaths[@]}"; do
		docker-compose -f "$configPath" logs -f
    done
}

# 检查配置文件是否存在
checkConfigFiles() {
    for configPath in "${configPaths[@]}"; do
        if [ ! -f "$configPath" ]; then
            echo "配置文件 $configPath 不存在"
            exit 1
        fi
    done
}

if [ $process == "start" ]; then
    #启动节点
    startNode
elif [ $process == "stop" ]; then
    #停止节点
    stopNode
elif [ $process == "down" ]; then
    #卸载节点
    downNode
elif [ $process == "restart" ]; then
    #重启 
    restartNode
elif [ $process == "list" ]; then
    #查询 
    listNode
elif [ $process == "resetting" ]; then
    #重置当前整个网络
    resettingNode
elif [ $process == "open" ]; then
    #打开一个容器
    openNode
elif [ $process == "log" ]; then
    #查询日志
    logNode
else
    echo "请检查执行格式, 例:启动节点 ./xx.sh start configPath.yaml"
fi

```

## channel_init_join_list_json_addorg_sign_update_config.sh

```sh
#!/bin/bash
# author 罗德

# 例子:
# ./xx.sh init 通道名称 [通道模板]
# ./xx.sh join 通道名称 
# 根据后边的流程输入执行

# 流程控制 init=初始化通道 join=加入通道 list=查询通道
# json=获取通道最新配置块(1) addorg=通道添加组织(2) sign=组织签名(3) update=提交更新(4)
process=$1

# 通道名称
nameChannel=$2

# [可选]通道模板: one、two / 签名json: ./channel-artifacts/mychannel-addorg-Org3-update.json
templateChannel=$3
updateChannel=$3

# 初始化通道: 创建 通道初始区块、通道配置
initChannel() {
############################  参数校验  ##############################
	checkConfigFiles

	# 检查通道名称参数是否为空
    if [ -z "$nameChannel" ]; then
        echo "通道名称 参数不能为空, 例: ./xx.sh init mychannel [one] "
        exit 1
    fi
    # 检查通道模板名称参数是否为空
    if [ -z "$templateChannel" ]; then
        templateChannel="TwoOrgsChannel" 
        echo "通道模板默认使用TwoOrgsChannel"
    fi
############################  创建通道配置  ##############################
    # 创建通道配置生成目录
    mkdir -p channel-artifacts
    # 授予configtxgen命令权限
    chmod -R 777 offlineInstaller/trustedChain-samples/bin
    
	if configtxgen -profile $templateChannel -outputBlock ./channel-artifacts/$nameChannel.block -channelID $nameChannel; then
		echo "通道初始区块"$nameChannel".block初始化完成, 目录: ./channel-artifacts/"$nameChannel".block"
	else
		echo "通道初始区块"$nameChannel".block初始化失败"
	fi
    
	if configtxgen -profile $templateChannel -outputCreateChannelTx ./channel-artifacts/$nameChannel.tx -channelID $nameChannel; then
		echo "通道配置"$nameChannel".tx初始化完成, 目录: ./channel-artifacts/"$nameChannel".tx"
	else
		echo "通道配置"$nameChannel".tx初始化失败"
	fi
	# 授予通道配置权限
	chmod -R 777 channel-artifacts
}

# 加入通道
joinChannel() {
############################  参数校验 #######################################
	checkConfigFiles
    if [ -z "$nameChannel" ]; then
        echo "通道名称 参数不能为空, 例: ./xx.sh join mychannel "
        exit 1
    fi
    
############################  选择cli客户端工具 ################################
	# 执行 docker 命令并输出容器名称
	echo "运行中的客户端工具容器："
	docker ps --filter "name=cli*" --format "table {{.Names}}"
	# 获取第一个容器名称
	docker_exec=$(docker ps --filter "name=cli*" --format "{{.Names}}" | head -n 1)

	# 读取用户输入的容器名称，如果用户没有输入，则使用第一个容器名称
	read  -e -i "$docker_exec" -p "请选择输入客户端工具容器名称(cli*)：" input_cli_address
	docker_exec=${input_cli_address:-$docker_exec}

############################  选择peer/orderer节点 ##########################
	# 列出所有正在运行的 Docker 容器
	containers=$(docker ps --format '{{.Names}}')

	# 截取容器名称中的组织和 Peer 名称
	org=$(echo $docker_exec | cut -d'-' -f2)
	peer=$(echo $docker_exec | cut -d'-' -f3)

	# 遍历容器名称，查找包含指定关键字的容器
	for container in $containers
	do
	  if [[  $container == peer* && $container == *"$org"* && $container == *"$peer"*  || $container =~ order ]]; then
		if [ -z "$first_container" ]; then
		  first_container="$container"
		fi
		echo $container
	  fi
	done
	
	# 获取第一个容器名称
	node_name=$first_container
	# 读取用户输入的容器名称,默认第一个
	read -e -i "$node_name" -p "请选择输入加入的节点名称（多个节点名称用空格分隔）
orderer节点在任意一个容器执行一次加入即可 ：" input_node_address
	node_address=${input_node_address:-$node_name}

############################  docker加入通道 ###############################

	# 重启刷新挂载的文件
	docker restart $docker_exec
	# 同步时间
	hwclock --hctosys
	clock -w
	# 遍历加入通道
	for node in $node_address
	do
	  # 获取 ":" 之前的第二个点部分(orderer0.xinhe.com -> xinhe.com)
	  dnsPath=$(echo $node | awk -F ':' '{print $1}' | cut -d'.' -f2- )

	  # 获取orderer0前缀类型: orderer
	  type_prefix=$(echo $node | cut -d'.' -f1)
	  prefix="${type_prefix%%[0-9]*}"
	  
	  # 执行加入通道
	  docker exec -it $docker_exec bash -c "\
	  case $prefix in
	  	\"peer\") 
	  		# peer加入通道
	  		peer channel join -b channel-artifacts/$nameChannel.block
	  		echo \"${docker_exec:4}加入的通道列表：\"
	  		peer channel list
	  		;;
	  	\"orderer\") 
	  		# orderer加入通道
	  		osnadmin channel join --channelID $nameChannel --config-block ./channel-artifacts/$nameChannel.block -o $node:9443 \
	  		--ca-file /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/$dnsPath/orderers/$node/tls/ca.crt \
	  		--client-cert /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/$dnsPath/orderers/$node/tls/server.crt \
	  		--client-key /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/$dnsPath/orderers/$node/tls/server.key
	  		
	  		echo \"$node加入的通道列表：\"
	  		osnadmin channel list -o $node:9443 \
	  		--ca-file /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/$dnsPath/orderers/$node/tls/ca.crt \
	  		--client-cert /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/$dnsPath/orderers/$node/tls/server.crt \
	  		--client-key /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/$dnsPath/orderers/$node/tls/server.key
	  		;;		
	  esac"
	done
	
}

# 获取通道最新配置块
jsonChannel() {
############################  参数校验 #####################################
	echo "通道添加组织: 例: ./xx.sh json mychannel"
	checkConfigFiles
	# 检查通道名称参数是否为空
    if [ -z "$nameChannel" ]; then
        echo "通道名称 参数不能为空: 例: ./xx.sh json mychannel"
        exit 1
    fi

############################  选择cli客户端工具 #############################
	echo "运行中的客户端工具容器："
	docker ps --filter "name=cli*" --format "table {{.Names}}"
	# 获取第一个容器名称
	docker_exec=$(docker ps --filter "name=cli*" --format "{{.Names}}" | head -n 1)

	# 读取用户输入的容器名称，如果用户没有输入，则使用第一个容器名称
	read  -e -i "$docker_exec" -p "请选择加入了通道的peer客户端：" input_peer_address
	docker_exec=${input_peer_address:-$docker_exec}
	
############################  选择orderer节点 ############################
	# 列出所有正在运行的 Docker 容器 
	echo "正在运行的 orderer 节点："
	docker ps --format "{{.Names}} {{.Ports}}" | grep order | while read -r name ports; do
		node_dns=$(echo "$name" | awk '{print $1}')
		node_port=$(echo "$ports" | sed 's/.*->\([0-9]*\).*/\1/g')
		echo "$node_dns:$node_port"
	done
	
	# 获取第一个容器的 IP 地址和端口号
	node_dns=$(docker ps --format "{{.Names}}\t{{.Ports}}" | grep order | head -n 1 | awk '{print $1}')
	node_port=$(docker ps --format "{{.Names}}\t{{.Ports}}" | grep order | head -n 1 | sed 's/.*->\([0-9]*\).*/\1/g')
	node_dns="$node_dns:$node_port"

	# 读取用户输入的容器名称，默认第一个
	read -e -i "$node_dns" -p "请选择通道内可执行交易的orderer节点(ip:port)
如果需要提交交易到其他服务器的排序节点, 请手动调整：" input_orderer_address
	orderer_address=${input_orderer_address:-$node_dns}

############################  docker #################################
	# 获取 ":" 之前的第二个点部分(orderer0.xinhe.com -> xinhe.com)
	dnsPath=$(echo $orderer_address | awk -F ':' '{print $1}' | cut -d'.' -f2- )

	docker exec -it $docker_exec bash -c "\
		# 获取初始区块, 等同于获取init初始化通道配置
		peer channel fetch 0 /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/${nameChannel}.block -o $orderer_address -c $nameChannel --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/$dnsPath/msp/tlscacerts/*
		echo \"初始区块:  ./channel-artifacts/${nameChannel}.block \"
		
		# 获取最新的配置区块 -> onechannel.pb
		peer channel fetch config /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/${nameChannel}.pb -o $orderer_address -c $nameChannel --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/$dnsPath/msp/tlscacerts/*
		echo \"最新的配置区块:  ./channel-artifacts/${nameChannel}.pb \"
		
		# 转为json, 取其中config部分的数据
		configtxlator proto_decode --input /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/${nameChannel}.pb --type common.Block | jq .data.data[0].payload.data.config > /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/${nameChannel}.json
		echo \"最新的配置区块json:  ./channel-artifacts/${nameChannel}.json \"
	"
}

# 通道添加组织
addorgChannel() {
############################  参数校验 ######################
	echo "通道添加组织: 例: ./xx.sh addorg mychannel"
	checkConfigFiles
	# 检查通道名称参数是否为空
    if [ -z "$nameChannel" ]; then
        echo "通道名称 参数不能为空: 例: ./xx.sh addorg mychannel"
        exit 1
    fi
    # 检查通道模板名称参数是否为空
    if [ -z "$templateChannel" ]; then
        templateChannel="TwoOrgsChannel" 
        echo "通道模板默认使用TwoOrgsChannel"
    fi
    # 组织name名称
	read  -e -i "Org"  -p "指定要添加的组织name, 该name必须在configtx中配置(例: Org16)：" input_org
	org=($input_org)

############################  更新 ######################################
	#1 生成新添组织json
	configtxgen -profile $templateChannel -outputBlock ./channel-artifacts/$nameChannel-addorg-${org}.block -channelID $nameChannel
	configtxgen -inspectBlock ./channel-artifacts/$nameChannel-addorg-${org}.block > ./channel-artifacts/$nameChannel-${org}.json
	jq ".data.data[0].payload.data.config.channel_group.groups.Application.groups.${org}" ./channel-artifacts/$nameChannel-${org}.json > ./channel-artifacts/${org}.json
	echo "1/7 新组织json"
	
	#2 新组织合并到通道json
	jq_filter=".[0] * {\"channel_group\":{\"groups\":{\"Application\":{\"groups\": {\"${org}\":.[1]}}}}}"
	jq -s "$jq_filter" ./channel-artifacts/${nameChannel}.json <(jq -s add ./channel-artifacts/$org.json) > ./channel-artifacts/${nameChannel}-addorg-${org}-update.json
	echo "2/7 新组织合并到通道json"
	
	#3 将旧通道json文件转为pb
	configtxlator proto_encode --input ./channel-artifacts/${nameChannel}.json --type common.Config --output ./channel-artifacts/${nameChannel}.pb
	echo "3/7 将旧通道json文件转为二进制pb"

	#4 将新通道json文件转为pb
	configtxlator proto_encode --input ./channel-artifacts/${nameChannel}-addorg-${org}-update.json --type common.Config --output ./channel-artifacts/${nameChannel}-addorg-${org}-update.pb
	echo "4/7 将新通道json文件转为二进制pb"
	
	#5 计算pb之间的差异pb
	configtxlator compute_update --channel_id ${nameChannel} --original ./channel-artifacts/${nameChannel}.pb --updated ./channel-artifacts/${nameChannel}-addorg-${org}-update.pb --output ./channel-artifacts/${nameChannel}-addorg-${org}-disparity.pb
	echo "5/7 计算pb之间的差异pb"
	
	#6 将差异pb转为json
	configtxlator proto_decode --input ./channel-artifacts/${nameChannel}-addorg-${org}-disparity.pb --type common.ConfigUpdate | jq . > ./channel-artifacts/${nameChannel}-addorg-${org}-disparity.json
	echo "6/7 将差异pb转为json"
	
	#7 差异json添加header头信息, 生成更新json
	update_json="{\"payload\":{\"header\":{\"channel_header\":{\"channel_id\":\"${nameChannel}\", \"type\":2}},\"data\":{\"config_update\":$(cat ./channel-artifacts/${nameChannel}-addorg-${org}-disparity.json)}}}"
	echo "$update_json" | jq . > ./channel-artifacts/${nameChannel}-addorg-${org}.json
	echo "7/7 生成更新通道json: ./channel-artifacts/${nameChannel}-addorg-${org}.json"
	
	rm -f ./channel-artifacts/${org}.json
	rm -f ./channel-artifacts/$nameChannel-addorg-${org}.block
	rm -f ./channel-artifacts/$nameChannel-${org}.json
	rm -f ./channel-artifacts/${nameChannel}-addorg-${org}-update.json
	rm -f ./channel-artifacts/${nameChannel}-addorg-${org}-update.pb
	rm -f ./channel-artifacts/${nameChannel}.pb
	rm -f ./channel-artifacts/${nameChannel}-addorg-${org}-disparity.pb
	rm -f ./channel-artifacts/${nameChannel}-addorg-${org}-disparity.json
	echo ""
				
	read -p $'是否继续执行提交更新通道[y/n] ' choice
	if [ "$choice" == "y" ]; then
		updateChannel="./channel-artifacts/${nameChannel}-addorg-${org}.json"
		signChannel
	else
		exit 1
	fi
}

# 更新通道配置
updateConfig(){
############################  参数校验 ######################
	echo "更新通道配置: 例: ./xx.sh config mychannel"
	checkConfigFiles
	# 检查通道名称参数是否为空
    if [ -z "$nameChannel" ]; then
        echo "通道名称 参数不能为空: 例: ./xx.sh config mychannel"
        exit 1
    fi
    
    echo ""
    echo "修改通道配置前, 请确保已经获取最新的通道json, 并修改了${nameChannel}.json"
    echo ""
        
	#1 将新通道json文件转为pb
	configtxlator proto_encode --input ./channel-artifacts/${nameChannel}.json --type common.Config --output ./channel-artifacts/${nameChannel}-updateConfig-update.pb

	configtxlator proto_decode --input ./channel-artifacts/${nameChannel}.pb --type common.Block | jq .data.data[0].payload.data.config >  ./channel-artifacts/${nameChannel}-updateConfig-json.json
	configtxlator proto_encode --input ./channel-artifacts/${nameChannel}-updateConfig-json.json --type common.Config --output ./channel-artifacts/${nameChannel}-updateConfig-pb.pb
	echo "1/4 将新通道json文件转为二进制pb"
	
	#2 计算pb之间的差异pb
	configtxlator compute_update --channel_id ${nameChannel} --original ./channel-artifacts/${nameChannel}-updateConfig-pb.pb --updated ./channel-artifacts/${nameChannel}-updateConfig-update.pb --output ./channel-artifacts/${nameChannel}-updateConfig-disparity.pb
	echo "2/4 计算pb之间的差异pb"
	
	#3 将差异pb转为json
	configtxlator proto_decode --input ./channel-artifacts/${nameChannel}-updateConfig-disparity.pb --type common.ConfigUpdate | jq . > ./channel-artifacts/${nameChannel}-updateConfig-disparity.json
	echo "3/4 将差异pb转为json"

	#4 差异json添加header头信息, 生成更新json
	update_json="{\"payload\":{\"header\":{\"channel_header\":{\"channel_id\":\"${nameChannel}\", \"type\":2}},\"data\":{\"config_update\":$(cat ./channel-artifacts/${nameChannel}-updateConfig-disparity.json)}}}"
	echo "$update_json" | jq . > ./channel-artifacts/${nameChannel}-updateConfig.json
	echo "4/4 生成更新通道配置json: ./channel-artifacts/${nameChannel}-updateConfig.json"
	
	rm -f ./channel-artifacts/${nameChannel}-updateConfig-update.pb
	rm -f ./channel-artifacts/${nameChannel}-updateConfig-disparity.pb
	rm -f ./channel-artifacts/${nameChannel}-updateConfig-disparity.json
	rm -f ./channel-artifacts/${nameChannel}-updateConfig-json.json
	rm -f ./channel-artifacts/${nameChannel}-updateConfig-pb.pb
	echo ""

	read -p $'是否继续执行提交更新通道[y/n] ' choice
	if [ "$choice" == "y" ]; then
		updateChannel="./channel-artifacts/${nameChannel}-updateConfig.json"
		echo ""
		# 读取用户输入的容器名称，默认第一个
		read -e -i "OrdererMSP" -p "输入排序组织的MSPID：" input_org_name
		org_MSP=${input_org_name:-OrdererMSP}
		echo ""
		
		updateChannel
	else
		exit 1
	fi
}

# 通道添加orderer
addordererChannel(){
############################  参数校验 ######################
	echo "通道添加组织: 例: ./xx.sh addorderer mychannel"
	checkConfigFiles
	# 检查通道名称参数是否为空
    if [ -z "$nameChannel" ]; then
        echo "通道名称 参数不能为空: 例: ./xx.sh addorderer mychannel"
        exit 1
    fi
    # 检查通道模板名称参数是否为空
    if [ -z "$templateChannel" ]; then
        templateChannel="TwoOrgsChannel" 
        echo "通道模板默认使用TwoOrgsChannel"
    fi
    # orderer节点
	read  -e -i "orderer3.aoa.com:7051"  -p "指定要添加的orderer节点(ip:端口)：" input_org
	orderer=($input_org)
	
############################  更新 ######################################
	#1 生成新添组织json
	# 获取 ":" 之前的第二个点部分(orderer0.xinhe.com -> xinhe.com)
	dnsPath=$(echo $orderer | awk -F ':' '{print $1}' | cut -d'.' -f2- )
	node=$(echo $orderer | awk -F ':' '{print $1}')
	port=$(echo $orderer | awk -F ':' '{print $2}')
	
	#1 新orderer合并到通道json
	# orderer证书
	cert=$(cat ./crypto-config/ordererOrganizations/${dnsPath}/orderers/${node}/tls/server.crt | base64) 
	jq_addresses=".channel_group.values.OrdererAddresses.value.addresses += [\"$orderer\"]"
	jq_consensusType=".channel_group.groups.Orderer.values.ConsensusType.value.metadata.consenters += [{\"client_tls_cert\": \"${cert}\",\"host\": \"${node}\",\"port\": ${port},\"server_tls_cert\": \"${cert}\"}]"
	
	jq "$jq_addresses | $jq_consensusType" ./channel-artifacts/${nameChannel}.json > ./channel-artifacts/${nameChannel}-addorderer-update.json
	echo "1/6 新orderer合并到通道json"
		
	#2 将旧通道json文件转为pb
	configtxlator proto_encode --input ./channel-artifacts/${nameChannel}.json --type common.Config --output ./channel-artifacts/${nameChannel}.pb
	echo "2/6 将旧通道json文件转为二进制pb"

	#3 将新通道json文件转为pb
	configtxlator proto_encode --input ./channel-artifacts/${nameChannel}-addorderer-update.json --type common.Config --output ./channel-artifacts/${nameChannel}-addorderer-update.pb
	echo "3/6 将新通道json文件转为二进制pb"
	
	#4 计算pb之间的差异pb
	configtxlator compute_update --channel_id ${nameChannel} --original ./channel-artifacts/${nameChannel}.pb --updated ./channel-artifacts/${nameChannel}-addorderer-update.pb --output ./channel-artifacts/${nameChannel}-addorderer-disparity.pb
	echo "4/6 计算pb之间的差异pb"
	
	#5 将差异pb转为json
	configtxlator proto_decode --input ./channel-artifacts/${nameChannel}-addorderer-disparity.pb --type common.ConfigUpdate | jq . > ./channel-artifacts/${nameChannel}-addorderer-disparity.json
	echo "5/6 将差异pb转为json"
	
	#6 差异json添加header头信息, 生成更新json
	update_json="{\"payload\":{\"header\":{\"channel_header\":{\"channel_id\":\"${nameChannel}\", \"type\":2}},\"data\":{\"config_update\":$(cat ./channel-artifacts/${nameChannel}-addorderer-disparity.json)}}}"
	echo "$update_json" | jq . > ./channel-artifacts/${nameChannel}-addorderer.json
	echo "6/6 生成更新通道json: ./channel-artifacts/${nameChannel}-addorderer.json"
	
	rm -f ./channel-artifacts/${nameChannel}-addorderer.block
	#rm -f ./channel-artifacts/${nameChannel}-addorderer-temp.block
	#rm -f ./channel-artifacts/${nameChannel}-addorderer-temp.json
	rm -f ./channel-artifacts/${orderer}.json
	#rm -f ./channel-artifacts/${nameChannel}-addorderer-update.json
	rm -f ./channel-artifacts/${nameChannel}-addorderer-update.pb
	rm -f ./channel-artifacts/${nameChannel}.pb
	rm -f ./channel-artifacts/${nameChannel}-addorderer-disparity.pb
	rm -f ./channel-artifacts/${nameChannel}-addorderer-disparity.json
	echo ""
	echo "将创建完成的更新通道json文件拷贝至背书策略指定的背书节点服务器"
	echo "执行更新通道json背书签名..."
				
	read -p $'是否继续执行更新通道json
注意: 更新通道json背书签名必须在有权限的背书节点执行？[y/n] ' choice
	if [ "$choice" == "y" ]; then
		updateChannel="./channel-artifacts/${nameChannel}-addorderer.json"
		signChannel
	else
		exit 1
	fi
}


# 组织签名
signChannel(){
############################  参数校验 #################################
	# 检查通道名称参数是否为空
    if [ -z "$nameChannel" ]; then
        echo "通道名称 参数不能为空, 例: ./xx.sh sign mychannel ./channel-artifacts/mychannel-addorg-Org3.json"
        exit 1
    fi
	# 检查通道名称参数是否为空
    if [ -z "$updateChannel" ]; then
        echo "签名文件路径 参数不能为空, 例: ./xx.sh sign mychannel ./channel-artifacts/mychannel-addorg-Org3.json"
        exit 1
    fi
    
############################  选择cli客户端工具 ########################
	echo "运行中的客户端工具容器："
	docker ps --filter "name=cli*" --format "table {{.Names}}"
	# 获取第一个容器名称
	docker_exec=$(docker ps --filter "name=cli*" --format "{{.Names}}" | head -n 1)

	# 读取用户输入的容器名称，如果用户没有输入，则使用第一个容器名称
	read  -e -i "$docker_exec" -p "请选择加入了通道的peer客户端：" input_peer_address
	docker_exec=${input_peer_address:-$docker_exec}
	
############################  签名 ###################################
	# 去掉json后缀
    updateChannel=$(echo "$updateChannel" | sed 's/\.json$//')
	# json转为pb
	configtxlator proto_encode --input ${updateChannel}.json --type common.Envelope --output ${updateChannel}.pb
	
	docker exec -it $docker_exec bash -c "\
		# 签名
		peer channel signconfigtx -f ${updateChannel}.pb
		echo \"签名完成\"
	"
	read -p $'是否继续执行提交更新？[y/n] ' choice
	if [ "$choice" == "y" ]; then
		updateChannel
	else
		exit 1
	fi
	
}

# 提交更新
updateChannel(){
############################  参数校验 #################################
	# 检查通道名称参数是否为空
    if [ -z "$nameChannel" ]; then
        echo "通道名称 为空, 例: ./xx.sh update mychannel ./channel-artifacts/mychannel-addorg-Org3-update.json"
        exit 1
    fi
	# 检查通道名称参数是否为空
    if [ -z "$updateChannel" ]; then
        echo "签名文件路径 为空, 例: ./xx.sh update mychannel ./channel-artifacts/mychannel-addorg-Org3-update.json"
        exit 1
    fi
############################  选择cli客户端工具 ##########################
	if [ -z "$docker_exec" ]; then
		echo "运行中的客户端工具容器："
		docker ps --filter "name=cli*" --format "table {{.Names}}"
		# 获取第一个容器名称
		docker_exec=$(docker ps --filter "name=cli*" --format "{{.Names}}" | head -n 1)

		# 读取用户输入的容器名称，如果用户没有输入，则使用第一个容器名称
		read  -e -i "$docker_exec" -p "请选择加入了通道的peer客户端：" input_cli_address
		docker_exec=${input_cli_address:-$docker_exec}
	fi
	
############################  选择orderer节点 ###########################
	if [ -z "$container_address" ]; then
		# 列出所有正在运行的 Docker 容器 
		echo "正在运行的 orderer 节点："
		docker ps --format "{{.Names}} {{.Ports}}" | grep order | while read -r name ports; do
			node_dns=$(echo "$name" | awk '{print $1}')
			node_port=$(echo "$ports" | sed 's/.*->\([0-9]*\).*/\1/g')
			echo "$node_dns:$node_port"
		done
		
		# 获取第一个容器的 IP 地址和端口号
		node_dns=$(docker ps --format "{{.Names}}\t{{.Ports}}" | grep order | head -n 1 | awk '{print $1}')
		node_port=$(docker ps --format "{{.Names}}\t{{.Ports}}" | grep order | head -n 1 | sed 's/.*->\([0-9]*\).*/\1/g')
		node_address="$node_dns:$node_port"

		# 读取用户输入的容器名称，默认第一个
		read -e -i "$node_address" -p "请选择通道内可执行交易的orderer节点(ip:port)
如果需要提交交易到其他服务器的排序节点, 请手动调整：" input_orderer_address
		node_address=${input_orderer_address:-$node_address}
	fi

############################  提交 #####################################
	# 获取 ":" 之前的第二个点部分(orderer0.xinhe.com -> xinhe.com)
	dnsPath=$(echo $node_address | awk -F ':' '{print $1}' | cut -d'.' -f2- )
	dnsRootPath=$(echo $node_address | awk -F ':' '{print $1}' | cut -d':' -f1)
	# 去掉json后缀
    updateChannel=$(echo "$updateChannel" | sed 's/\.json$//')
	# json转为pb
	configtxlator proto_encode --input ${updateChannel}.json --type common.Envelope --output ${updateChannel}.pb

	docker exec -it $docker_exec bash -c "\
	if [ -n \"$org_MSP\" ]; then
export CORE_PEER_LOCALMSPID=${org_MSP}
export CORE_PEER_ADDRESS=$node_address
CORE_PEER_TLS_CERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/$dnsPath/orderers/${dnsRootPath}/tls/server.crt
CORE_PEER_TLS_KEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/$dnsPath/orderers/${dnsRootPath}/tls/server.key
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/$dnsPath/orderers/${dnsRootPath}/tls/ca.crt
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/$dnsPath/msp/
	fi

		# 提交更新
		peer channel update -f ${updateChannel}.pb -c $nameChannel -o $node_address --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/$dnsPath/msp/tlscacerts/*
		echo \"通道更新完成\"
	"

	rm -f ${updateChannel}.pb
}

# 查询通道
listChannel() {
############################  参数校验 ###################################
	# 检查通道名称参数是否为空
    if [ -z "$nameChannel" ]; then
        echo "通道名称 参数不能为空: 例: ./xx.sh list mychannel"
        exit 1
    fi
############################  选择cli客户端工具 ############################
   	echo "运行中的客户端工具容器："
	docker ps --filter "name=cli*" --format "table {{.Names}}"

	# 获取第一个容器名称
	docker_exec=$(docker ps --filter "name=cli*" --format "{{.Names}}" | head -n 1)

	# 读取用户输入的容器名称，如果用户没有输入，则使用第一个容器名称
	read -e -i "$docker_exec" -p "请选择输入客户端工具容器名称：" input_peer_address
	docker_exec=${input_peer_address:-$docker_exec}

############################  选择peer节点 ##################################
	# 截取容器名称中的组织
	org=$(echo $docker_exec | cut -d'-' -f2)
	peer=$(echo $docker_exec | cut -d'-' -f3)
	# 获取第一个容器的 IP 地址和端口号
	node_dns=$(docker ps --format "{{.Names}}\t{{.Ports}}" | grep "^peer"  | grep $org | grep $peer | head -n 1 | awk '{print $1}')
	node_port=$(docker ps --format "{{.Names}}\t{{.Ports}}"  | grep "^peer"  | grep $org | grep $peer | head -n 1 | sed 's/[^->]*->\([0-9]*\).*/\1/g')
	node="$node_dns:$node_port"
	
############################  docker查询 ###############################
	# 遍历通道
	# 获取 ":" 之前第二个点的部分(peer.org.xinhe.com -> org.xinhe.com)
	dnsPath=$(echo $node | awk -F ':' '{print $1}' | cut -d'.' -f2- )
	node_org=$(echo $node | cut -d'.' -f2 | sed 's/[^0-9]*//g')
	
	# 执行查询通道
	docker exec -it $docker_exec bash -c "\
		echo \"通道$nameChannel的peer节点：\"
		discover peers --channel $nameChannel --peerTLSCA /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/$dnsPath/users/Admin\@$dnsPath/msp/tlscacerts/* --userKey /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/$dnsPath/users/Admin@$dnsPath/msp/keystore/* --userCert /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/$dnsPath/users/Admin\@$dnsPath/msp/signcerts/* --MSP Org${node_org}MSP --server $node | jq -r '.[] | .Endpoint'
		"
}

# 检查配置文件是否存在
checkConfigFiles() {
	if [ ! -f "configtx.yaml" ]; then
	  echo "当前目录下没有找到 configtx.yaml 通道配置文件"
	  exit 1
	fi
}

if [ $process == "init" ]; then
    #初始化通道
    initChannel
elif [ $process == "join" ]; then
    #加入通道
    joinChannel
elif [ $process == "json" ]; then
    #查询通道json
    jsonChannel
elif [ $process == "addorg" ]; then
    #通道添加组织
    addorgChannel
elif [ $process == "addorderer" ]; then
    #通道添加orderer
    addordererChannel
elif [ $process == "sign" ]; then
    #组织签名
    signChannel
elif [ $process == "config" ]; then
    #更新通道配置
    updateConfig
elif [ $process == "update" ]; then
    #提交更新
    updateChannel
elif [ $process == "list" ]; then
    #查询通道
    listChannel
else
    echo "请检查执行格式, 例:加入通道 ./xx.sh init/join/json/list mychannel"
fi
```

## chaincode_install_commit_invoke_query_info.sh

```sh
#!/bin/bash
# author 罗德

# 例子: 默认使用当前目录下chaincode.jar
# ./xx.sh install 通道名称 链码名称
# ./xx.sh commit 通道名称 链码名称
# 根据后边的流程输入执行

# 流程控制 install=安装/升级链码 commit=提交 invoke=调用链码 query=查询链码 info=链码信息
process=$1

# 链码通道
channelChainCode=$2

# 链码名称: 例 mycc
nameChainCode=$3

# 链码方法名称(调用链码时使用):  createCat
functionChainCode=$4
# 链码版本(调用安装/提交链码时选择使用): 默认 1.0
versionChainCode=$4

# 链码方法参数(调用链码时使用): (注意双引号转义) [\"cat-2\",\"tom\",\"3\",\"红色\",\"大懒猫\"]
ArgsChainCode=$5
# 链码版本号(调用安装/提交链码时选择使用): 默认 1
sequenceChainCode=$5

#链码源码路径
ChainCodePath="chaincode/go/xinhe-contract-golang"

# 安装/升级链码
installChainCode() {
	echo "安装/升级链码示例: ./xx.sh install mychannel mycc 1.0 1"
############################  安装/升级链码 -> 参数校验  ############################################################	
	# 检查链码通道是否为空
    if [ -z "$channelChainCode" ]; then
        echo "必须指定链码通道: 例: ./xx.sh install mychannel mycc 1.0 1"
        exit 1
    fi
	# 检查链码名称是否为空
    if [ -z "$nameChainCode" ]; then
        echo "必须指定链码名称: 例: ./xx.sh install mychannel mycc 1.0 1"
        exit 1
    fi
    # 检查链码版本是否为空
    if [ -z "$versionChainCode" ]; then
        echo "注意: 默认链码版本(1.0), 对已经存在的链码安装/升级尽量不使用默认版本: 
例: ./xx.sh install mychannel mycc 1.0"
		versionChainCode="1.0"
    fi
    # 检查链码版本号是否为空
    if [ -z "$sequenceChainCode" ]; then
        echo "注意: 默认链码版本号(1), 版本号唯一, 对已经存在的链码安装/升级不能使用默认版本号, 指定递增的版本号: 
例: ./xx.sh install mychannel mycc 1.0 1"
		sequenceChainCode="1"
    fi
    
    # 默认使用当前目录下chaincode.jar
    echo "默认使用当前目录下chaincode.jar"
    cp -r chaincode.jar /data/hyperledger/chaincode/go/chaincode.jar
    chmod -R 777 /data/hyperledger/chaincode/go

############################  安装/升级链码 -> 选择cli客户端工具 ###################
    # 执行 docker 命令并输出容器名称
	echo "运行中的客户端工具容器："
	docker ps --filter "name=cli*" --format "table {{.Names}}"
	# 获取第一个容器名称
	container_name=$(docker ps --filter "name=cli*" --format "{{.Names}}" | head -n 1)

	# 读取用户输入的容器名称，如果用户没有输入，则使用第一个容器名称
	read  -e -i "$container_name" -p "请选择输入客户端工具容器名称：" input_container_names
	container_name=${input_container_names:-$container_name}

############################ 选择orderer节点  #########################################
	# 列出所有正在运行的 Docker 容器 
	echo "正在运行的 orderer 排序节点："
	docker ps --format "{{.Names}} {{.Ports}}" | grep order | while read -r name ports; do
		node_address=$(echo "$name" | awk '{print $1}')
		node_port=$(echo "$ports" | sed 's/.*->\([0-9]*\).*/\1/g')
		echo "$node_address:$node_port"
	done

	# 获取第一个容器的 IP 地址和端口号
	node_address=$(docker ps --format "{{.Names}}\t{{.Ports}}" | grep order | head -n 1 | awk '{print $1}')
	node_port=$(docker ps --format "{{.Names}}\t{{.Ports}}" | grep order | head -n 1 | sed 's/.*->\([0-9]*\).*/\1/g')
	node_address="$node_address:$node_port"

	# 读取用户输入的容器名称，默认第一个
	read -e -i "$node_address" -p "请选择通道内可执行交易的orderer节点(ip:port)
如果需要提交交易到其他服务器的排序节点, 请手动调整：" input_node_address
	orderer_address=${input_node_address:-$node_address}
	
############################  安装/升级链码 -> docker安装/升级链码  ###################
	# 打包安装链码
    if [ -d "${ChainCodePath}" ]; then
		cd chaincode/go/xinhe-contract-golang
		go env -w GOPROXY=https://goproxy.cn,direct
		go mod vendor
		gojava="golang"
		echo "go语言环境..."
	else
		ChainCodePath="chaincode/go"
		gojava="java"
		echo "java语言环境..."
	fi


	docker exec -it $container_name bash -c "\
		# 打包java链码
		echo \"$container_name正在打包链码... \"
		peer lifecycle chaincode package $nameChainCode.tar.gz --path /opt/gopath/src/github.com/hyperledger/fabric-cluster/${ChainCodePath} --lang ${gojava} --label $nameChainCode
		
		# 安装链码
		echo \"$container_name正在安装链码... \"
		peer lifecycle chaincode install $nameChainCode.tar.gz
		echo \"已安装的$nameChainCode链码:  \"
		peer lifecycle chaincode queryinstalled --output json | jq -r '.installed_chaincodes[] | select(.label == \"$nameChainCode\") | .package_id'
	"
	
############################ 选择链码  ################################################
	# 读取用户输入的容器名称
	echo "批准链码(如果该链码已经在组织其他节点批准, 则不需要再次批准, 安装后可直接使用)..."
	read -p "请选择安装好的链码(mycc:xxxxxx)：" package_id

############################ 批准链码  ############################################################	
	# 获取 ":" 之前的第二个点部分(orderer0.xinhe.com -> xinhe.com)
	dnsPath=$(echo $orderer_address | awk -F ':' '{print $1}' | cut -d'.' -f2- )
	
	# 同步时间
	hwclock --hctosys
	clock -w
	# 批准链码
	docker exec -it $container_name bash -c "\
		# 批准链码定义
		echo \"$container_name正在批准链码... \"
		peer lifecycle chaincode approveformyorg --channelID $channelChainCode --name $nameChainCode --version $versionChainCode --init-required --package-id $package_id --sequence $sequenceChainCode --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/$dnsPath/msp/tlscacerts/* --orderer $orderer_address

		# 查询链码就绪状态
		echo \"\"
		echo \"$container_name正在检测就绪状态(如果该链码在其他组织检测完成提交, 可忽略检测信息): \"
		peer lifecycle chaincode checkcommitreadiness --channelID $channelChainCode --name $nameChainCode --version $versionChainCode --init-required --sequence $sequenceChainCode --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/$dnsPath/msp/tlscacerts/* --orderer $orderer_address --output json
	"	
			
	read -p $'是否继续执行提交链码？[y/n] ' choice
	if [ "$choice" == "y" ]; then
		commitChainCode
	else
		exit 1
	fi
}

# 提交链码
commitChainCode() {
	echo "提交链码示例: ./xx.sh commit mychannel mycc 1.0 1"
############################  提交链码 -> 参数校验 ######################################
	# 检查链码通道是否为空
    if [ -z "$channelChainCode" ]; then
        echo "必须指定链码通道: 例: ./xx.sh commit mychannel mycc 1.0 1"
        exit 1
    fi
	# 检查链码名称是否为空
    if [ -z "$nameChainCode" ]; then
        echo "必须指定链码名称: 例: ./xx.sh commit mychannel mycc 1.0 1"
        exit 1
    fi
    # 检查链码版本是否为空
    if [ -z "$versionChainCode" ]; then
        echo "注意: 使用默认链码版本(1.0), 对已经存在的链码安装/升级不能使用默认版本: 
例: ./xx.sh install mychannel mycc 1.0 1"
		versionChainCode="1.0"
    fi
    # 检查链码版本号是否为空
    if [ -z "$sequenceChainCode" ]; then
        echo "注意: 使用默认链码版本号(1), 对已经存在的链码安装/升级不能使用默认版本号: 
例: ./xx.sh install mychannel mycc 1.0 1"
		sequenceChainCode="1"
    fi
    
############################  提交链码 -> 选择cli客户端工具  ############################################################
	if [ -z "$container_name" ]; then
		echo "运行中的客户端工具容器："
		docker ps --filter "name=cli*" --format "table {{.Names}}"
		# 获取第一个容器名称
		container_name=$(docker ps --filter "name=cli*" --format "{{.Names}}" | head -n 1)

		# 读取用户输入的容器名称，如果用户没有输入，则使用第一个容器名称
		read  -e -i "$container_name" -p "请选择加入了通道的peer客户端：" input_container_name
		container_name=${input_container_name:-$container_name}
	fi
	
############################  提交链码 -> 选择peer节点  #####################		
	if [ -z "$peer_names" ]; then
		# 截取容器名称中的组织
		org=$(echo $container_name | cut -d'-' -f2)
		peer=$(echo $container_name | cut -d'-' -f3)
		
		# 获取第一个容器的 IP 地址和端口号
		node_address=$(docker ps --format "{{.Names}}\t{{.Ports}}" | grep "^peer" | grep $org | grep $peer | head -n 1 | awk '{print $1}')
		node_port=$(docker ps --format "{{.Names}}\t{{.Ports}}" | grep "^peer"  | grep $org | grep $peer | head -n 1 | sed 's/[^->]*->\([0-9]*\).*/\1/g')
		peer_names="$node_address:$node_port"
	fi
	
############################  提交链码 -> 选择orderer节点  ##########################	
	if [ -z "$orderer_address" ]; then
		# 列出所有正在运行的 Docker 容器 
		echo "正在运行的 orderer 排序节点："
		docker ps --format "{{.Names}} {{.Ports}}" | grep order | while read -r name ports; do
			node_address=$(echo "$name" | awk '{print $1}')
			node_port=$(echo "$ports" | sed 's/.*->\([0-9]*\).*/\1/g')
			echo "$node_address:$node_port"
		done

		# 获取第一个容器的 IP 地址和端口号
		node_address=$(docker ps --format "{{.Names}}\t{{.Ports}}" | grep order | head -n 1 | awk '{print $1}')
		node_port=$(docker ps --format "{{.Names}}\t{{.Ports}}" | grep order | head -n 1 | sed 's/.*->\([0-9]*\).*/\1/g')
		node_address="$node_address:$node_port"

		# 读取用户输入的容器名称，默认第一个
		read -e -i "$node_address" -p "请选择通道内可执行交易的orderer节点(ip:port)
如果需要提交交易到其他服务器的排序节点, 请手动调整：" input_orderer_address
		orderer_address=${input_orderer_address:-$node_address}
	fi
	
############################  提交链码 -> docker提交链码  #######################	
	# 获取 ":" 之前的第二个点部分(orderer0.xinhe.com -> xinhe.com)
	dnsPath=$(echo $orderer_address | awk -F ':' '{print $1}' | cut -d'.' -f2- )
	
	peer=$(echo "$peer_names" | sed 's/:.*//')
	order=$(echo "$orderer_address" | sed 's/:.*//')
	org=$(echo "$peer" | sed 's/^[^.]*\.//')
	# 提交链码
    if [ "${gojava}" = "golang" ]; then
		gojava="'{\"Args\":[\"a\",\"bb\"]}'"
		echo "go语言环境..."
	else
		gojava="'{\"function\":\"createCat\",\"Args\":[\"cat-1\" , \"tom\" ,  \"3\" , \"蓝色\" , \"大懒猫\"]}'"
		echo "java语言环境..."
	fi

	docker exec -it $container_name bash -c "\
		echo \"\"
		echo \"$container_name正在提交链码(如果该链码在其他组织检测完成提交, 可忽略版本异常信息)... \"
		peer lifecycle chaincode commit -o $orderer_address --channelID $channelChainCode --name $nameChainCode --version $versionChainCode --sequence $sequenceChainCode --init-required --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/$dnsPath/msp/tlscacerts/* --peerAddresses $peer_names --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/$org/peers/$peer/tls/ca.crt
		
		if [ \"$sequenceChainCode\" = \"1\" ]; then
			echo \"\"
			echo \"$container_name链码初始化(如果该链码在其他组织检测完成提交, 可忽略版本异常信息)... \"
			peer chaincode invoke -o $orderer_address --isInit --ordererTLSHostnameOverride $order --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/$dnsPath/msp/tlscacerts/* -C $channelChainCode -n $nameChainCode --peerAddresses $peer_names --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/$org/peers/$peer/tls/ca.crt -c ${gojava}

		fi
		echo \"\"
		echo \"查询$channelChainCode通道已成功提交的$nameChainCode链码信息: \"
		peer lifecycle chaincode querycommitted -C $channelChainCode -n $nameChainCode
	"
}

# 调用链码
invokeChainCode() {
	echo "调用链码示例:
./xx.sh invoke mychannel mycc createCat [\\\"cat-2\\\",\\\"tom\\\",\\\"3\\\",\\\"红色\\\",\\\"大懒猫\\\"]"

############################  调用链码 -> 参数校验  ############################################################
	# 检查链码通道是否为空
    if [ -z "$channelChainCode" ]; then
        echo "必须指定链码通道: 例: ./xx.sh invoke mychannel mycc createCat [\\\"cat-2\\\",\\\"tom\\\",\\\"3\\\",\\\"红色\\\",\\\"大懒猫\\\"]"
        exit 1
    fi
	# 检查链码名称是否为空
    if [ -z "$nameChainCode" ]; then
        echo "必须指定链码名称: 例: ./xx.sh invoke mychannel mycc createCat [\\\"cat-2\\\",\\\"tom\\\",\\\"3\\\",\\\"红色\\\",\\\"大懒猫\\\"]"
        exit 1
    fi
    # 检查链码方法是否为空
    if [ -z "$functionChainCode" ]; then
        echo "调用链码方法为空: 例: ./xx.sh invoke mychannel mycc createCat [\\\"cat-2\\\",\\\"tom\\\",\\\"3\\\",\\\"红色\\\",\\\"大懒猫\\\"]"
        exit 1
    fi
    # 检查链码方法参数是否为空
    if [ -z "$ArgsChainCode" ]; then
        echo "调用链码方法参数为空(注意双引号需要转义): 
例: ./xx.sh invoke mychannel mycc createCat [\\\"cat-2\\\",\\\"tom\\\",\\\"3\\\",\\\"红色\\\",\\\"大懒猫\\\"]"
        exit 1
    fi

############################  调用链码 -> 选择cli客户端工具  ############################################################
	echo "运行中的客户端工具容器："
	docker ps --filter "name=cli*" --format "table {{.Names}}"
	# 获取第一个容器名称
	container_name=$(docker ps --filter "name=cli*" --format "{{.Names}}" | head -n 1)

	# 读取用户输入的容器名称，如果用户没有输入，则使用第一个容器名称
	read  -e -i "$container_name" -p "请选择加入了通道的peer客户端：" input_container_name
	container_name=${input_container_name:-$container_name}
	
############################  调用链码 -> 选择pee节点  ############################################################	
	# 截取容器名称中的组织
	org=$(echo $container_name | cut -d'-' -f2)
	peer=$(echo $container_name | cut -d'-' -f3)

	# 获取第一个容器的 IP 地址和端口号
	node_address=$(docker ps --format "{{.Names}}\t{{.Ports}}" | grep "^peer" | grep $org | grep $peer  | head -n 1 | awk '{print $1}')
	node_port=$(docker ps --format "{{.Names}}\t{{.Ports}}" | grep "^peer"  | grep $org | grep $peer | head -n 1 | sed 's/[^->]*->\([0-9]*\).*/\1/g')
	peer_names="$node_address:$node_port"
	
############################  调用链码 -> 选择orderer节点  ############################################################
	# 列出所有正在运行的 Docker 容器 
	echo "正在运行的 orderer 排序节点："
	docker ps --format "{{.Names}} {{.Ports}}" | grep order | while read -r name ports; do
		node_address=$(echo "$name" | awk '{print $1}')
		node_port=$(echo "$ports" | sed 's/.*->\([0-9]*\).*/\1/g')
		echo "$node_address:$node_port"
	done

	# 获取第一个容器的 IP 地址和端口号
	node_address=$(docker ps --format "{{.Names}}\t{{.Ports}}" | grep order | head -n 1 | awk '{print $1}')
	node_port=$(docker ps --format "{{.Names}}\t{{.Ports}}" | grep order | head -n 1 | sed 's/.*->\([0-9]*\).*/\1/g')
	node_address="$node_address:$node_port"

	# 读取用户输入的容器名称，默认第一个
	read -e -i "$node_address" -p "请选择通道内可执行交易的orderer节点(ip:port)
如果需要提交交易到其他服务器的排序节点, 请手动调整：" input_orderer_address
	orderer_address=${input_orderer_address:-$node_address}

############################  调用链码 -> docker调用链码  ############################################################
	# 获取 ":" 之前的第二个点部分(orderer0.xinhe.com -> xinhe.com)
	dnsPath=$(echo $orderer_address | awk -F ':' '{print $1}' | cut -d'.' -f2- )
	
	peer=$(echo "$peer_names" | sed 's/:.*//')
	order=$(echo "$orderer_address" | sed 's/:.*//')
	org=$(echo "$peer" | sed 's/^[^.]*\.//')
	docker exec -it $container_name bash -c "\
		echo \"$container_name调用链码... \"
		
		peer chaincode invoke -o $orderer_address --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/$dnsPath/msp/tlscacerts/* -C $channelChainCode -n $nameChainCode --peerAddresses $peer_names --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/$org/peers/$peer/tls/ca.crt -c '{\"function\":\"$functionChainCode\",\"Args\":$ArgsChainCode}'
		
	"
}

# 查询链码
queryChainCode() {
	echo "查询链码示例:
./xx.sh query mychannel mycc [\\\"queryCat\\\",\\\"cat-1\\\"]"

############################  查询链码 -> 参数校验  ############################################################
	# 检查链码通道是否为空
    if [ -z "$channelChainCode" ]; then
        echo "必须指定链码通道: 例: ./xx.sh query mychannel mycc [\\\"queryCat\\\",\\\"cat-1\\\"]"
        exit 1
    fi
	# 检查链码名称是否为空
    if [ -z "$nameChainCode" ]; then
        echo "必须指定链码名称: 例: ./xx.sh query mychannel mycc [\\\"queryCat\\\",\\\"cat-1\\\"]"
        exit 1
    fi
    # 检查链码方法是否为空
    if [ -z "$functionChainCode" ]; then
        echo "调用链码方法参数为空(注意双引号需要转义): 
例: ./xx.sh query mychannel mycc [\\\"queryCat\\\",\\\"cat-1\\\"]"
        exit 1
    fi
	ArgsChainCode=$functionChainCode

############################  查询链码 -> 选择cli客户端工具  ############################################################
	echo "运行中的客户端工具容器："
	docker ps --filter "name=cli*" --format "table {{.Names}}"
	# 获取第一个容器名称
	container_name=$(docker ps --filter "name=cli*" --format "{{.Names}}" | head -n 1)

	# 读取用户输入的容器名称，如果用户没有输入，则使用第一个容器名称
	read  -e -i "$container_name" -p "请选择加入了通道的peer客户端：" input_container_name
	container_name=${input_container_name:-$container_name}

############################  查询链码 -> 调用查询链码  ############################################################
	docker exec -it $container_name bash -c "\
		echo \"查询$channelChainCode通道已完成提交的链码信息: \"
		peer chaincode query -C $channelChainCode -n $nameChainCode -c '{\"Args\":$ArgsChainCode}'
	"
}

# 链码信息
infoChainCode() {
	echo "链码信息示例:
./xx.sh query mychannel [mycc]"

############################  链码信息 -> 参数校验  ############################################################
	# 检查链码通道是否为空
    if [ -z "$channelChainCode" ]; then
        echo "必须指定链码通道: 例: ./xx.sh query mychannel [mycc]"
        exit 1
    fi

############################  链码信息 -> 选择cli客户端工具  ############################################################
	echo "运行中的客户端工具容器："
	docker ps --filter "name=cli*" --format "table {{.Names}}"
	# 获取第一个容器名称
	container_name=$(docker ps --filter "name=cli*" --format "{{.Names}}" | head -n 1)

	# 读取用户输入的容器名称，如果用户没有输入，则使用第一个容器名称
	read  -e -i "$container_name" -p "请选择加入了通道的peer客户端：" input_container_name
	container_name=${input_container_name:-$container_name}

############################  链码信息 -> docker查询链码  ############################################################
	docker exec -it $container_name bash -c "\
		echo \"$container_name调用查询链码... \"
		if [ -z \"$nameChainCode\" ]; then
			echo \"默认$channelChainCode通道查询所有链码: \"
			peer lifecycle chaincode querycommitted -C $channelChainCode
		else
			peer lifecycle chaincode querycommitted -C $channelChainCode -n $nameChainCode
		fi
	"
}

if [ $process == "install" ]; then
    # 安装/升级链码
    installChainCode
elif [ $process == "commit" ]; then
    # 提交链码
    commitChainCode
elif [ $process == "invoke" ]; then
    # 调用链码
    invokeChainCode
elif [ $process == "query" ]; then
    # 查询链码
    queryChainCode
elif [ $process == "info" ]; then
    # 链码信息
    infoChainCode
else
    echo "请检查执行格式, 例:加入通道 ./xx.sh install/commit/invoke/query/info mychannel mycc"
fi
```

# 配置文件附录

## configtx.yaml

```yaml
---
# 配置执行入口在最后面的Profiles, 修改或者补充更新在Profiles修改

# 全局替换, 注意替换使用 区分大小写替换
# 域名: cndtcloud.com
# 排序组织name: OrdererOrg
# 排序组织mspid: OrdererMSP
# peer组织: org1
# peer组织name: Org1
# peer组织mspid: Org1MSP

# 着重配置点:
# 1. Organizations组织: 新增Org组织必须配置AnchorPeers锚节点
# 2. Profiles入口: Application:Organizations必须补充配置好的组织引用
# 3. Profiles入口: Orderer:Addresses必须配置好orderer节点, 否则peer不能与orderer通信
# 4. Profiles入口: Orderer:Organizations必须补充配置好的组织引用
# 5. Profiles入口: Orderer:OrdererType必须补充共识机制
# 6. Profiles入口: Orderer:EtcdRaft必须补充共识节点配置

# Capabilities、Application、Orderer、Channel都是通用配置, 非必要不更改, 自定义配置在Profiles入口补充

# 组织配置：定义了不同的组织标志, 这些组织将在 Profiles 部分(最后面)被引用。
Organizations:
    # 定义一个排序组织
    # 名称=OrdererOrg、id=OrdererMSP(也就是msp名称)
    # MSPDir=组织的MSP证书路径, 之后我们将组织下的成员加入这个通道的时候, 必须结果msp的验证, 不属于组织的节点将不能加入通道
    - &OrdererOrg
        Name: OrdererOrg
        ID: OrdererMSP # mspid, 此配置后面节点启动时有关联配置
        MSPDir: ./crypto-config/ordererOrganizations/cndtcloud.com/msp # 这个组织的证书msp路径
        # 定义的组织策略, 也就是权限, 包括Readers读、Writers写等
        Policies:
            # 控制谁可以 读取 通道中的交易数据
            # Signature=签名, 组织下的成员member必须经过 签名证书 通过身份验证才能被认为是有效
            Readers:
                Type: Signature
                Rule: "OR('OrdererMSP.member')" 
            # 控制谁可以 写入 通道的交易数据, type、Rule同上
            Writers:
                Type: Signature
                Rule: "OR('OrdererMSP.member')"
            # 控制敏感操作，如创建通道、更新通道等
            # Signature=签名, Rule=只有admin管理员通过签名验证才可以创建通道、更新通道
            Admins:
                Type: Signature
                Rule: "OR('OrdererMSP.admin')"
#        OrdererEndpoints:
#            - orderer0.aoa.com:7051
#            - orderer1.aoa.com:7052
#            - orderer2.aoa.com:7053

    - &Org1
        Name: Org1 
        ID: Org1MSP # mspid, 此配置后面节点启动时有关联配置
        MSPDir: ./crypto-config/peerOrganizations/org1.cndtcloud.com/msp # 这个组织的证书msp路径
        Policies:
            Readers:
                Type: Signature
                Rule: "OR('Org1MSP.member')"
            Writers:
                Type: Signature
                Rule: "OR('Org1MSP.member')"
            Admins:
                Type: Signature
                Rule: "OR('Org1MSP.admin')"
            # 背书策略, 只有经过身份验证的 Peer 节点才能对交易进行背书，从而保证了交易的安全性和可信度
            Endorsement:
                Type: Signature
                Rule: "OR('Org1MSP.peer')"
        AnchorPeers:
            -   Host: peer0.org1.cndtcloud.com  # 锚节点的host地址, 等同于这个组织的主节点
                Port: 7150        # 锚节点开放的端口号

# 定义版本的兼容情况, 会在Peer、Orderer、Channel处使用
Capabilities:
    # Channel配置同时应用于 orderer 节点与 peer 节点，并且必须被两种节点同时支持
    # 将该配置项设置为ture表明要求节点具备该能力,false则不要求该节点具备该能力
    # 要求Channel上的所有Orderer节点和Peer节点达到v2.0.0或更高版本
    Channel: &ChannelCapabilities
        V2_0: true

    # Orderer功能仅适用于 orderer 节点，可以安全地操作，而无需担心升级peers
    Orderer: &OrdererCapabilities
        V2_0: true

    # 应用程序功能仅适用于 Peer 网络，可以安全地操作，而无需担心升级或更新orderers
    Application: &ApplicationCapabilities
        V2_0: true

# Peer配置：指定 Peer 节点的一些基本属性和行为, 例如：权限策略等，　这些将应用于所有的通道和链码
Application: &ApplicationDefaults
    # ImplicitMeta：支持多个子策略，并且只有满足所有子策略的签名才能通过验证
    # ANY Readers: 任何拥有 Readers 角色都可以读取通道和链码的数据
    Policies:
        Readers:
            Type: ImplicitMeta
            Rule: "ANY Readers"
        Writers:
            Type: ImplicitMeta
            Rule: "ANY Writers"
        Admins:
            Type: Signature
            Rule: "OR('OrdererMSP.admin')"

        # LifecycleEndorsement 策略用于指定链码的生命周期操作（例如安装、批准和提交）的策略
        # ANY Endorsement: 任何拥有 Endorsement 背书角色都可以对链码的生命周期操作进行安装、批准和提交
        LifecycleEndorsement:
            Type: ImplicitMeta
            Rule: "ANY Endorsement"
        # 背书策略：任何 Endorsement 背书节点都可以执行并且验证交易输出
        Endorsement:
            Type: ImplicitMeta
            Rule: "ANY Endorsement"

    # 版本的兼容情况, 满足Capabilities.Application的配置即可
    Capabilities:
        <<: *ApplicationCapabilities

# Orderer配置：指定默认的排序服务配置, 例如权限策略、批处理大小、超时时间等
Orderer: &OrdererDefaults
    Policies:
        Readers:
            Type: ImplicitMeta
            Rule: "ANY Readers"
        Writers:
            Type: ImplicitMeta
            Rule: "ANY Writers"
        Admins:
            Type: Signature
            Rule: "OR('OrdererMSP.admin')"
        # 指定排序服务对区块的验证策略, 任何拥有 Writers 写角色的都可以对区块进行验证
        BlockValidation:
            Type: ImplicitMeta
            Rule: "ANY Writers"
    # 区块打包的最大超时时间 (到了该时间就打包区块)
    BatchTimeout: 1s
    # 区块打包的最大包含交易数（orderer端切分区块的参数）
    BatchSize:
        MaxMessageCount: 100000
        AbsoluteMaxBytes: 99 MB
        PreferredMaxBytes: 99 MB
    # 表示Orderer允许的最大通道数， 默认0表示没有最大通道数
    MaxChannels: 0
    # 版本兼容
    Capabilities:
        <<: *OrdererCapabilities

# Channel通道配置: 指定通道的一些基本属性，例如权限策略等
Channel: &ChannelDefaults
    Policies:
        Readers:
            Type: ImplicitMeta
            Rule: "ANY Readers"
        Writers:
            Type: ImplicitMeta
            Rule: "ANY Writers"
        Admins:
            Type: ImplicitMeta
            Rule: "ANY Admins"
    # 版本的兼容情况, 满足Capabilities.Channel的配置即可
    Capabilities:
        <<: *ChannelCapabilities

#配置入口: 命令选择一个配置模板执行即可
Profiles:
    # 默认模板名称:
    TwoOrgsChannel:
        # 通道所关联的联盟名称，Fabric无系统通道模式，不需要联盟
        Consortium: xinheKeXinLian

        # 继承ChannelDefaults 通道默认属性到该位置, 也就是Policies、Capabilities属性
        <<: *ChannelDefaults

        # peer节点配置, 包括继承的默认配置, 自定义的组织配置 和 自定义组织的AnchorPeers锚节点
        Application:
            # 继承 ApplicationDefaults 默认配置, 包括Policies、Capabilities属性
            <<: *ApplicationDefaults

            # [自定义补充]
            # Organizations 组织属性: 组织配置,引用Org1、Org2组织, AnchorPeers 锚节点配置(通常选择组织的第一个节点)
            Organizations:
                -   <<: *Org1

        # Orderer排序节点配置, 包括默认的配置, 自定义组织配置 和 OrdererType共识机制、共识配置
        Orderer:
            # 继承 OrdererDefaults 默认配置, 包括Policies、OrdererType、Capabilities等属性
            <<: *OrdererDefaults

            # [自定义补充]
            # Organizations 组织属性: 组织配置,引用OrdererOrg组织, 组织在 Organizations 处配置
            Organizations:
                -   <<: *OrdererOrg
            # orderer节点, 必须配置, 否则peer无法与orderer通信
            Addresses:
                - orderer0.cndtcloud.com:7051
                - orderer1.cndtcloud.com:7052
                - orderer2.cndtcloud.com:7053

            # 排序节点的共识机制, 使用 etcd 作为共识存储后端, 还有单机的solo和传统的Kafka机制
            # etcdraft：在机制下最终只有一个Orderer节点进行排序，所以其性能非常的高，并不需要多个节点之间同步状态的拜占庭问题。
            OrdererType: etcdraft
            # 定义 etcdRaft 排序配置, 例如 etcd 共识节点地址地址(至少3个)、TLS 配置、共识算法等
            # 如果有多个或者很多个排序节点, 需要他们参与共识机制，那么需要在配置文件中显示地配置每个排序节点的地址和 TLS 配置
            EtcdRaft:
                Consenters:
                    -   Host: orderer0.cndtcloud.com
                        Port: 7051
                        ClientTLSCert: ./crypto-config/ordererOrganizations/cndtcloud.com/orderers/orderer0.cndtcloud.com/tls/server.crt
                        ServerTLSCert: ./crypto-config/ordererOrganizations/cndtcloud.com/orderers/orderer0.cndtcloud.com/tls/server.crt
                    -   Host: orderer1.cndtcloud.com
                        Port: 7052
                        ClientTLSCert: ./crypto-config/ordererOrganizations/cndtcloud.com/orderers/orderer1.cndtcloud.com/tls/server.crt
                        ServerTLSCert: ./crypto-config/ordererOrganizations/cndtcloud.com/orderers/orderer1.cndtcloud.com/tls/server.crt
                    -   Host: orderer2.cndtcloud.com
                        Port: 7053
                        ClientTLSCert: ./crypto-config/ordererOrganizations/cndtcloud.com/orderers/orderer2.cndtcloud.com/tls/server.crt
                        ServerTLSCert: ./crypto-config/ordererOrganizations/cndtcloud.com/orderers/orderer2.cndtcloud.com/tls/server.crt

                # 选举领导者leader节点配置
                Options:
                    TickInterval: 500ms
                    ElectionTick: 10
                    HeartbeatTick: 1
                    MaxInflightBlocks: 5
                    SnapshotIntervalSize: 16 MB

```

## fabric-bind-ca.yaml

```yaml
version: '3'

services:
  xinhe-ca:
    container_name: xinhe-ca #容器名称
    image: hyperledger/fabric-ca #镜像名称
    command: sh -c 'fabric-ca-server start -d -b admin:adminpw --port 7054 --cfg.affiliations.allowremove  --cfg.identities.allowremove' #指定ca端口 账号 密码
    environment:
      - FABRIC_CA_HOME=/data/hyperledger/fabric-ca/crypto
      - FABRIC_CA_SERVER_HOME=/data/hyperledger/fabric-ca/crypto
      - FABRIC_CA_CLIENT_HOME=/data/hyperledger/fabric-ca/crypto
      - FABRIC_CA_SERVER_TLS_ENABLED=true
      - FABRIC_CA_SERVER_CSR_HOSTS=192.168.1.16,0.0.0.0,localhost,ca.immediateca.xinhe.com # 本机ip
      - FABRIC_CA_SERVER_DEBUG=true
      - FABRIC_CA_SERVER_DB_TYPE=mysql
      - FABRIC_CA_SERVER_DB_DATASOURCE=root:root@tcp(192.168.1.16:3306)/fabric_immediateca_ca?parseTime=true #ca连接的数据库
      - FABRIC_CA_SERVER_CSR_CN=xinhe-ca
    #      - FABRIC_CA_SERVER_INTERMEDIATE_PARENTSERVER_URL=https://admin:adminpw@192.168.1.78:7054 # 新增父级url
    #      - FABRIC_CA_SERVER_INTERMEDIATE_TLS_CERTFILES=/data/hyperledger/fabric-ca/root-tls-cert.pem # 新增父级tls
    #      - FABRIC_CA_SERVER_INTERMEDIATE_TLS_CLIENT_CERTFILE=/data/hyperledger/fabric-ca/root-ca-cert.pem # 新增父级ca
    #      - FABRIC_CA_SERVER_INTERMEDIATE_TLS_CLIENT_KEYFILE=/data/hyperledger/fabric-ca/root-priv-sk # 新增父级私钥
    volumes:
      - /data/hyperledger/tls-ca:/data/hyperledger/fabric-ca
    ports:
      - 7054:7054

```

## orderer0.yaml

```yaml
version: '3'

#全局替换下面的k-v的value
#域名: cndtcloud.com
#主机名: orderer0
#端口: 7051
#通道配置mspid: OrdererMSP


#networks:
#    fabric_net:
#        external: true

services:
    orderer0.cndtcloud.com:
        container_name: orderer0.cndtcloud.com
        image: n.cndtcloud.com/trusted-chain/xinhe/xinhe-orderer:2.4.6
#        networks:
#            - fabric_net
        environment:
            - FABRIC_LOGGING_SPEC=INFO  # 指定日志级别
            - ORDERER_GENERAL_LISTENADDRESS=0.0.0.0     # 服务绑定的监听地址，一般需要指定为所服务的特定网络接口的地址或全网（0.0.0.0）
            - ORDERER_GENERAL_LISTENPORT=7051       # 服务绑定的监听端口
#            - ORDERER_GENERAL_GENESISMETHOD=file   # 当 ORDERER_GENERAL_BOOTSTRAPMETHOD 为 file 时启用，指定创世区块类型
#            - ORDERER_GENERAL_GENESISFILE=/var/hyperledger/orderer/orderer.genesis.block   # 指定创世区块位置
            - ORDERER_GENERAL_LOCALMSPID=OrdererMSP     # orderer 所关联的 MSPID ，一般为所属组织名称，需要与通道配置内名称一致
            - ORDERER_GENERAL_LOCALMSPDIR=/var/hyperledger/orderer/msp      # 本地 MSP 文件路径
            - ORDERER_GENERAL_TLS_ENABLED=true      # 启用TLS时的相关配置
            - ORDERER_GENERAL_TLS_PRIVATEKEY=/var/hyperledger/orderer/tls/server.key    # Orderer 签名私钥
            - ORDERER_GENERAL_TLS_CERTIFICATE=/var/hyperledger/orderer/tls/server.crt   # Orderer 身份证书
            - ORDERER_GENERAL_TLS_ROOTCAS=[/var/hyperledger/orderer/tls/ca.crt]     # 信任的根证书
#            - ORDERER_KAFKA_TOPIC_REPLICATIONFACTOR=1   # 要在其中复制主题的Kafka代理的数量，默认为3个
#            - ORDERER_KAFKA_VERBOSE=true    # 启用与Kafka集群交互的日志记录
            - ORDERER_GENERAL_CLUSTER_CLIENTCERTIFICATE=/var/hyperledger/orderer/tls/server.crt     # 双向TLS认证时，作为客户端证书的文件路径，如果没设置会使用 TLS.Certificate
            - ORDERER_GENERAL_CLUSTER_CLIENTPRIVATEKEY=/var/hyperledger/orderer/tls/server.key      # 双向TLS认证时，作为客户端私钥的文件路径，如果没设置会使用 TLS.PrivateKey
            - ORDERER_GENERAL_CLUSTER_ROOTCAS=[/var/hyperledger/orderer/tls/ca.crt]     # 信任的根证书
#           配置无系统通道
            - ORDERER_GENERAL_BOOTSTRAPMETHOD=none  # 当 ORDERER_GENERAL_BOOTSTRAPMETHOD 为 file 时启用，指定创世区块类型
            - ORDERER_ADMIN_LISTENADDRESS=0.0.0.0:9443  # 管理服务监听地址
            - ORDERER_ADMIN_TLS_ENABLED=true    # 是否启用 orderer 的管理服务面板
            - ORDERER_ADMIN_TLS_PRIVATEKEY=/var/hyperledger/orderer/tls/server.key      # 管理服务的私钥
            - ORDERER_ADMIN_TLS_CERTIFICATE=/var/hyperledger/orderer/tls/server.crt     # 管理服务的证书
            - ORDERER_ADMIN_TLS_CLIENTROOTCAS=[/var/hyperledger/orderer/tls/ca.crt]     # 管理服务的可信根证书
            - ORDERER_ADMIN_TLS_CLIENTAUTHREQUIRED=true
            - ORDERER_CHANNELPARTICIPATION_ENABLED=true     # 是否提供参与通道的 API
            # metrics
#            - ORDERER_OPERATIONS_LISTENADDRESS=orderer0.cndtcloud.com:8125
#            - ORDERER_METRICS_PROVIDER=statsd
#            - ORDERER_METRICS_STATSD_ADDRESS=graphite:8125
#            - ORDERER_METRICS_STATSD_NETWORK=udp
#            - ORDERER_METRICS_STATSD_PREFIX=orderer0
        working_dir: /opt/gopath/src/github.com/hyperledger/fabric
        command: orderer
        volumes:
            - /etc/localtime:/etc/localtime
#            - ./channel-artifacts/genesis.block:/var/hyperledger/orderer/orderer.genesis.block
            - ./crypto-config/ordererOrganizations/cndtcloud.com/orderers/orderer0.cndtcloud.com/msp:/var/hyperledger/orderer/msp
            - ./crypto-config/ordererOrganizations/cndtcloud.com/orderers/orderer0.cndtcloud.com/tls/:/var/hyperledger/orderer/tls
            - ./hyperledger/orderer0:/var/hyperledger/production
        ports:
            - 7051:7051

```

## orderer1.yaml

```yaml
version: '3'

#全局替换下面的k-v的value
#域名: cndtcloud.com
#主机名: orderer1
#端口: 7052
#通道配置mspid: OrdererMSP

#networks:
#    fabric_net:
#        external: true

services:
  orderer1.cndtcloud.com:
    container_name: orderer1.cndtcloud.com
    image: n.cndtcloud.com/trusted-chain/xinhe/xinhe-orderer:2.4.6
    #        networks:
    #            - fabric_net
    environment:
      - FABRIC_LOGGING_SPEC=INFO  # 指定日志级别
      - ORDERER_GENERAL_LISTENADDRESS=0.0.0.0     # 服务绑定的监听地址，一般需要指定为所服务的特定网络接口的地址或全网（0.0.0.0）
      - ORDERER_GENERAL_LISTENPORT=7052       # 服务绑定的监听端口
      #            - ORDERER_GENERAL_GENESISMETHOD=file   # 当 ORDERER_GENERAL_BOOTSTRAPMETHOD 为 file 时启用，指定创世区块类型
      #            - ORDERER_GENERAL_GENESISFILE=/var/hyperledger/orderer/orderer.genesis.block   # 指定创世区块位置
      - ORDERER_GENERAL_LOCALMSPID=OrdererMSP     # orderer 所关联的 MSPID ，一般为所属组织名称，需要与通道配置内名称一致
      - ORDERER_GENERAL_LOCALMSPDIR=/var/hyperledger/orderer/msp      # 本地 MSP 文件路径
      - ORDERER_GENERAL_TLS_ENABLED=true      # 启用TLS时的相关配置
      - ORDERER_GENERAL_TLS_PRIVATEKEY=/var/hyperledger/orderer/tls/server.key    # Orderer 签名私钥
      - ORDERER_GENERAL_TLS_CERTIFICATE=/var/hyperledger/orderer/tls/server.crt   # Orderer 身份证书
      - ORDERER_GENERAL_TLS_ROOTCAS=[/var/hyperledger/orderer/tls/ca.crt]     # 信任的根证书
      #            - ORDERER_KAFKA_TOPIC_REPLICATIONFACTOR=1   # 要在其中复制主题的Kafka代理的数量，默认为3个
      #            - ORDERER_KAFKA_VERBOSE=true    # 启用与Kafka集群交互的日志记录
      - ORDERER_GENERAL_CLUSTER_CLIENTCERTIFICATE=/var/hyperledger/orderer/tls/server.crt     # 双向TLS认证时，作为客户端证书的文件路径，如果没设置会使用 TLS.Certificate
      - ORDERER_GENERAL_CLUSTER_CLIENTPRIVATEKEY=/var/hyperledger/orderer/tls/server.key      # 双向TLS认证时，作为客户端私钥的文件路径，如果没设置会使用 TLS.PrivateKey
      - ORDERER_GENERAL_CLUSTER_ROOTCAS=[/var/hyperledger/orderer/tls/ca.crt]     # 信任的根证书
      #           配置无系统通道
      - ORDERER_GENERAL_BOOTSTRAPMETHOD=none  # 当 ORDERER_GENERAL_BOOTSTRAPMETHOD 为 file 时启用，指定创世区块类型
      - ORDERER_ADMIN_LISTENADDRESS=0.0.0.0:9443  # 管理服务监听地址
      - ORDERER_ADMIN_TLS_ENABLED=true    # 是否启用 orderer 的管理服务面板
      - ORDERER_ADMIN_TLS_PRIVATEKEY=/var/hyperledger/orderer/tls/server.key      # 管理服务的私钥
      - ORDERER_ADMIN_TLS_CERTIFICATE=/var/hyperledger/orderer/tls/server.crt     # 管理服务的证书
      - ORDERER_ADMIN_TLS_CLIENTROOTCAS=[/var/hyperledger/orderer/tls/ca.crt]     # 管理服务的可信根证书
      - ORDERER_ADMIN_TLS_CLIENTAUTHREQUIRED=true
      - ORDERER_CHANNELPARTICIPATION_ENABLED=true     # 是否提供参与通道的 API
      # metrics
    #            - ORDERER_OPERATIONS_LISTENADDRESS=orderer1.cndtcloud.com:8125
    #            - ORDERER_METRICS_PROVIDER=statsd
    #            - ORDERER_METRICS_STATSD_ADDRESS=graphite:8125
    #            - ORDERER_METRICS_STATSD_NETWORK=udp
    #            - ORDERER_METRICS_STATSD_PREFIX=orderer1
    working_dir: /opt/gopath/src/github.com/hyperledger/fabric
    command: orderer
    volumes:
      - /etc/localtime:/etc/localtime
      #            - ./channel-artifacts/genesis.block:/var/hyperledger/orderer/orderer.genesis.block
      - ./crypto-config/ordererOrganizations/cndtcloud.com/orderers/orderer1.cndtcloud.com/msp:/var/hyperledger/orderer/msp
      - ./crypto-config/ordererOrganizations/cndtcloud.com/orderers/orderer1.cndtcloud.com/tls/:/var/hyperledger/orderer/tls
      - ./hyperledger/orderer1:/var/hyperledger/production
    ports:
      - 7052:7052

```

## orderer2.yaml

```yaml
version: '3'

#全局替换下面的k-v的value
#域名: cndtcloud.com
#主机名: orderer2
#端口: 7051
#通道配置mspid: OrdererMSP

#networks:
#    fabric_net:
#        external: true

services:
    orderer2.cndtcloud.com:
        container_name: orderer2.cndtcloud.com
        image: n.cndtcloud.com/trusted-chain/xinhe/xinhe-orderer:2.4.6
#        networks:
#            - fabric_net
        environment:
            - FABRIC_LOGGING_SPEC=INFO  # 指定日志级别
            - ORDERER_GENERAL_LISTENADDRESS=0.0.0.0     # 服务绑定的监听地址，一般需要指定为所服务的特定网络接口的地址或全网（0.0.0.0）
            - ORDERER_GENERAL_LISTENPORT=7053       # 服务绑定的监听端口
#            - ORDERER_GENERAL_GENESISMETHOD=file   # 当 ORDERER_GENERAL_BOOTSTRAPMETHOD 为 file 时启用，指定创世区块类型
#            - ORDERER_GENERAL_GENESISFILE=/var/hyperledger/orderer/orderer.genesis.block   # 指定创世区块位置
            - ORDERER_GENERAL_LOCALMSPID=OrdererMSP     # orderer 所关联的 MSPID ，一般为所属组织名称，需要与通道配置内名称一致
            - ORDERER_GENERAL_LOCALMSPDIR=/var/hyperledger/orderer/msp      # 本地 MSP 文件路径
            - ORDERER_GENERAL_TLS_ENABLED=true      # 启用TLS时的相关配置
            - ORDERER_GENERAL_TLS_PRIVATEKEY=/var/hyperledger/orderer/tls/server.key    # Orderer 签名私钥
            - ORDERER_GENERAL_TLS_CERTIFICATE=/var/hyperledger/orderer/tls/server.crt   # Orderer 身份证书
            - ORDERER_GENERAL_TLS_ROOTCAS=[/var/hyperledger/orderer/tls/ca.crt]     # 信任的根证书
#            - ORDERER_KAFKA_TOPIC_REPLICATIONFACTOR=1   # 要在其中复制主题的Kafka代理的数量，默认为3个
#            - ORDERER_KAFKA_VERBOSE=true    # 启用与Kafka集群交互的日志记录
            - ORDERER_GENERAL_CLUSTER_CLIENTCERTIFICATE=/var/hyperledger/orderer/tls/server.crt     # 双向TLS认证时，作为客户端证书的文件路径，如果没设置会使用 TLS.Certificate
            - ORDERER_GENERAL_CLUSTER_CLIENTPRIVATEKEY=/var/hyperledger/orderer/tls/server.key      # 双向TLS认证时，作为客户端私钥的文件路径，如果没设置会使用 TLS.PrivateKey
            - ORDERER_GENERAL_CLUSTER_ROOTCAS=[/var/hyperledger/orderer/tls/ca.crt]     # 信任的根证书
#           配置无系统通道
            - ORDERER_GENERAL_BOOTSTRAPMETHOD=none  # 当 ORDERER_GENERAL_BOOTSTRAPMETHOD 为 file 时启用，指定创世区块类型
            - ORDERER_ADMIN_LISTENADDRESS=0.0.0.0:9443  # 管理服务监听地址
            - ORDERER_ADMIN_TLS_ENABLED=true    # 是否启用 orderer 的管理服务面板
            - ORDERER_ADMIN_TLS_PRIVATEKEY=/var/hyperledger/orderer/tls/server.key      # 管理服务的私钥
            - ORDERER_ADMIN_TLS_CERTIFICATE=/var/hyperledger/orderer/tls/server.crt     # 管理服务的证书
            - ORDERER_ADMIN_TLS_CLIENTROOTCAS=[/var/hyperledger/orderer/tls/ca.crt]     # 管理服务的可信根证书
            - ORDERER_ADMIN_TLS_CLIENTAUTHREQUIRED=true
            - ORDERER_CHANNELPARTICIPATION_ENABLED=true     # 是否提供参与通道的 API
            # metrics
#            - ORDERER_OPERATIONS_LISTENADDRESS=orderer2.cndtcloud.com:8125
#            - ORDERER_METRICS_PROVIDER=statsd
#            - ORDERER_METRICS_STATSD_ADDRESS=graphite:8125
#            - ORDERER_METRICS_STATSD_NETWORK=udp
#            - ORDERER_METRICS_STATSD_PREFIX=orderer2
        working_dir: /opt/gopath/src/github.com/hyperledger/fabric
        command: orderer
        volumes:
            - /etc/localtime:/etc/localtime
#            - ./channel-artifacts/genesis.block:/var/hyperledger/orderer/orderer.genesis.block
            - ./crypto-config/ordererOrganizations/cndtcloud.com/orderers/orderer2.cndtcloud.com/msp:/var/hyperledger/orderer/msp
            - ./crypto-config/ordererOrganizations/cndtcloud.com/orderers/orderer2.cndtcloud.com/tls/:/var/hyperledger/orderer/tls
            - ./hyperledger/orderer2:/var/hyperledger/production
        ports:
            - 7053:7053

```

## org1-peer0.yaml

```yaml
version: '3'

#全局替换下面的k-v的value
#dns: cndtcloud.com
#node: peer0
#couchdbport: 5985
#peerport: 7150
#peerport2: 7250
#cliport: 9080
#mspid: Org1MSP
#org: org1

#networks:
#    fabric_net:
#        external: true

services:
    couchdb.peer0.org1.cndtcloud.com:
        container_name: couchdb.peer0.org1.cndtcloud.com
        image: n.cndtcloud.com/trusted-chain/xinhe/couchdb:2.1.1
#        networks:
#            - fabric_net
        environment:
            - COUCHDB_USER=admin
            - COUCHDB_PASSWORD=adminpw
            - COUCHDB_CLUSTERED=true
            - COUCHDB_LOG_LEVEL=error
        ports:
            - 5985:5984
        volumes:
            - /etc/localtime:/etc/localtime

    peer0.org1.cndtcloud.com:
        container_name: peer0.org1.cndtcloud.com
        image: n.cndtcloud.com/trusted-chain/xinhe/xinhe-peer:2.4.6
#        networks:
#            - fabric_net
        environment:
            - CORE_PEER_GOSSIP_STATE_ENABLED=true
            - CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
            - CORE_PEER_ID=peer0.org1.cndtcloud.com
            - CORE_PEER_ADDRESS=peer0.org1.cndtcloud.com:7150
            - CORE_PEER_LISTENADDRESS=0.0.0.0:7150
            - CORE_PEER_CHAINCODEADDRESS=127.0.0.1:7250
            - CORE_PEER_CHAINCODELISTENADDRESS=0.0.0.0:7250
            - CORE_PEER_GOSSIP_BOOTSTRAP=peer0.org1.cndtcloud.com:7150
            - CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer0.org1.cndtcloud.com:7150
            - CORE_PEER_LOCALMSPID=Org1MSP
            - FABRIC_LOGGING_SPEC=INFO
            - CORE_PEER_TLS_ENABLED=true
            - CORE_PEER_GOSSIP_USELEADERELECTION=true
            - CORE_PEER_GOSSIP_ORGLEADER=false
            - CORE_PEER_PROFILE_ENABLED=true
            - CORE_PEER_TLS_CERT_FILE=/etc/hyperledger/fabric/tls/server.crt
            - CORE_PEER_TLS_KEY_FILE=/etc/hyperledger/fabric/tls/server.key
            - CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/tls/ca.crt
            - CORE_CHAINCODE_EXECUTETIMEOUT=300s
            - CORE_LEDGER_STATE_STATEDATABASE=CouchDB
            - CORE_LEDGER_STATE_COUCHDBCONFIG_COUCHDBADDRESS=couchdb.peer0.org1.cndtcloud.com:5984
            - CORE_LEDGER_STATE_COUCHDBCONFIG_USERNAME=admin
            - CORE_LEDGER_STATE_COUCHDBCONFIG_PASSWORD=adminpw
              # metrics
              #- CORE_OPERATIONS_LISTENADDRESS=peer0.org1.cndtcloud.com:8125
              #- CORE_METRICS_PROVIDER=statsd
              #- CORE_METRICS_STATSD_ADDRESS=graphite:8125
              # - CORE_METRICS_STATSD_NETWORK=udp
              # - CORE_METRICS_STATSD_PREFIX=peer0_org1
        depends_on:
            - couchdb.peer0.org1.cndtcloud.com
        working_dir: /opt/gopath/src/github.com/hyperledger/fabric/peer
        command: peer node start
        volumes:
            - /etc/localtime:/etc/localtime
            - /var/run/:/host/var/run/
            - ./crypto-config/peerOrganizations/org1.cndtcloud.com/peers/peer0.org1.cndtcloud.com/msp:/etc/hyperledger/fabric/msp
            - ./crypto-config/peerOrganizations/org1.cndtcloud.com/peers/peer0.org1.cndtcloud.com/tls:/etc/hyperledger/fabric/tls
            - ./hyperledger/peer0.org1:/var/hyperledger/paoauction
        ports:
            - 7150:7150
            - 7250:7250
#        extra_hosts:
#            - "orderer0.xinhe.com:192.168.1.16"
#            - "orderer1.xinhe.com:192.168.1.16"
#            - "orderer2.xinhe.com:192.168.1.16"

            
    cli-org1-peer0:
        container_name: cli-org1-peer0
        image: n.cndtcloud.com/trusted-chain/xinhe/xinhe-tools:2.4.6
        #        networks:
        #            - fabric_net
        tty: true
        stdin_open: true
        environment:
            - GOPATH=/opt/gopath
            - CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
            - FABRIC_LOGGING_SPEC=INFO
            - CORE_PEER_ID=cli
            - CORE_PEER_ADDRESS=peer0.org1.cndtcloud.com:7150
            - CORE_PEER_LOCALMSPID=Org1MSP
            - CORE_PEER_TLS_ENABLED=true
            - CORE_PEER_TLS_CERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.cndtcloud.com/peers/peer0.org1.cndtcloud.com/tls/server.crt
            - CORE_PEER_TLS_KEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.cndtcloud.com/peers/peer0.org1.cndtcloud.com/tls/server.key
            - CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.cndtcloud.com/peers/peer0.org1.cndtcloud.com/tls/ca.crt
            - CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.cndtcloud.com/users/Admin@org1.cndtcloud.com/msp
        working_dir: /opt/gopath/src/github.com/hyperledger/fabric/peer
        command: sh -c "/usr/local/bin/configtxlator start --port=9080"
        volumes:
            - /etc/localtime:/etc/localtime
            - /var/run/:/host/var/run/
            - ./chaincode/go/:/opt/gopath/src/github.com/hyperledger/fabric-cluster/chaincode/go/
            - ./crypto-config:/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/
            - ./channel-artifacts:/opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts
        ports:
            - 9080:9080
#        extra_hosts:
#            - "orderer0.xinhe.com:192.168.1.16"
#            - "orderer1.xinhe.com:192.168.1.16"
#            - "orderer2.xinhe.com:192.168.1.16"

```

## org1-peer1.yaml

```yaml
version: '3'

#全局替换下面的k-v的value
#dns: cndtcloud.com
#node: peer1
#couchdbport: 5986
#peerport: 7151
#peerport2: 7251
#cliport: 9081
#mspid: Org1MSP
#org: org1

#networks:
#    fabric_net:
#        external: true

services:
    couchdb.peer1.org1.cndtcloud.com:
        container_name: couchdb.peer1.org1.cndtcloud.com
        image: n.cndtcloud.com/trusted-chain/xinhe/couchdb:2.1.1
#        networks:
#            - fabric_net
        environment:
            - COUCHDB_USER=admin
            - COUCHDB_PASSWORD=adminpw
            - COUCHDB_CLUSTERED=true
            - COUCHDB_LOG_LEVEL=error
        ports:
            - 5986:5984
        volumes:
            - /etc/localtime:/etc/localtime

    peer1.org1.cndtcloud.com:
        container_name: peer1.org1.cndtcloud.com
        image: n.cndtcloud.com/trusted-chain/xinhe/xinhe-peer:2.4.6
#        networks:
#            - fabric_net
        environment:
            - CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
            - CORE_PEER_ID=peer1.org1.cndtcloud.com
            - CORE_PEER_ADDRESS=peer1.org1.cndtcloud.com:7151
            - CORE_PEER_LISTENADDRESS=0.0.0.0:7151
            - CORE_PEER_CHAINCODEADDRESS=127.0.0.1:7251
            - CORE_PEER_CHAINCODELISTENADDRESS=0.0.0.0:7251
            - CORE_PEER_GOSSIP_BOOTSTRAP=peer1.org1.cndtcloud.com:7151
            - CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer1.org1.cndtcloud.com:7151
            - CORE_PEER_LOCALMSPID=Org1MSP
            - FABRIC_LOGGING_SPEC=INFO
            - CORE_PEER_TLS_ENABLED=true
            - CORE_PEER_GOSSIP_USELEADERELECTION=true
            - CORE_PEER_GOSSIP_ORGLEADER=false
            - CORE_PEER_PROFILE_ENABLED=true
            - CORE_PEER_TLS_CERT_FILE=/etc/hyperledger/fabric/tls/server.crt
            - CORE_PEER_TLS_KEY_FILE=/etc/hyperledger/fabric/tls/server.key
            - CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/tls/ca.crt
            - CORE_CHAINCODE_EXECUTETIMEOUT=300s
            - CORE_LEDGER_STATE_STATEDATABASE=CouchDB
            - CORE_LEDGER_STATE_COUCHDBCONFIG_COUCHDBADDRESS=couchdb.peer1.org1.cndtcloud.com:5984
            - CORE_LEDGER_STATE_COUCHDBCONFIG_USERNAME=admin
            - CORE_LEDGER_STATE_COUCHDBCONFIG_PASSWORD=adminpw
              # metrics
              #- CORE_OPERATIONS_LISTENADDRESS=peer1.org1.cndtcloud.com:8125
              #- CORE_METRICS_PROVIDER=statsd
              #- CORE_METRICS_STATSD_ADDRESS=graphite:8125
              # - CORE_METRICS_STATSD_NETWORK=udp
              # - CORE_METRICS_STATSD_PREFIX=peer1_org1
        depends_on:
            - couchdb.peer1.org1.cndtcloud.com
        working_dir: /opt/gopath/src/github.com/hyperledger/fabric/peer
        command: peer node start
        volumes:
            - /etc/localtime:/etc/localtime
            - /var/run/:/host/var/run/
            - ./crypto-config/peerOrganizations/org1.cndtcloud.com/peers/peer1.org1.cndtcloud.com/msp:/etc/hyperledger/fabric/msp
            - ./crypto-config/peerOrganizations/org1.cndtcloud.com/peers/peer1.org1.cndtcloud.com/tls:/etc/hyperledger/fabric/tls
            - ./hyperledger/peer1.org1:/var/hyperledger/paoauction
        ports:
            - 7151:7151
            - 7251:7251
#        extra_hosts:
#            - "orderer0.xinhe.com:192.168.1.16"
#            - "orderer1.xinhe.com:192.168.1.16"
#            - "orderer2.xinhe.com:192.168.1.16"

            
    cli-org1-peer1:
        container_name: cli-org1-peer1
        image: n.cndtcloud.com/trusted-chain/xinhe/xinhe-tools:2.4.6
        #        networks:
        #            - fabric_net
        tty: true
        stdin_open: true
        environment:
            - GOPATH=/opt/gopath
            - CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
            - FABRIC_LOGGING_SPEC=INFO
            - CORE_PEER_ID=cli
            - CORE_PEER_ADDRESS=peer1.org1.cndtcloud.com:7151
            - CORE_PEER_LOCALMSPID=Org1MSP
            - CORE_PEER_TLS_ENABLED=true
            - CORE_PEER_TLS_CERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.cndtcloud.com/peers/peer1.org1.cndtcloud.com/tls/server.crt
            - CORE_PEER_TLS_KEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.cndtcloud.com/peers/peer1.org1.cndtcloud.com/tls/server.key
            - CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.cndtcloud.com/peers/peer1.org1.cndtcloud.com/tls/ca.crt
            - CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.cndtcloud.com/users/Admin@org1.cndtcloud.com/msp
        working_dir: /opt/gopath/src/github.com/hyperledger/fabric/peer
        command: sh -c "/usr/local/bin/configtxlator start --port=9081"
        volumes:
            - /etc/localtime:/etc/localtime
            - /var/run/:/host/var/run/
            - ./chaincode/go/:/opt/gopath/src/github.com/hyperledger/fabric-cluster/chaincode/go/
            - ./crypto-config:/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/
            - ./channel-artifacts:/opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts
        ports:
            - 9081:9081
#        extra_hosts:
#            - "orderer0.xinhe.com:192.168.1.16"
#            - "orderer1.xinhe.com:192.168.1.16"
#            - "orderer2.xinhe.com:192.168.1.16"

```





