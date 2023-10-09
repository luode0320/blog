#!/bin/bash
# author pxz

###########           脚本配置开始 ↓            ################
#############通用配置###################
# ca节点挂载目录|节点自签根证书(中间ca使用证书链)|tls自签证书|证书生成目录
CaHome=/data/hyperledger/tls-ca
CaCert=/data/hyperledger/tls-ca/crypto/ca-cert.pem #自签根证书
#CaCert=/data/hyperledger/tls-ca/crypto/ca-chain.pem #自签证书链
TlsCaCert=/data/hyperledger/tls-ca/crypto/tls-cert.pem #tls证书
OutputConfig=/data/hyperledger/crypto-config
#######################################

################本地ca###################
# ca用户名|密码|ca主机|端口
CaUserName="admin"
CaPassWord="adminpw"
CaHostname="0.0.0.0"
CaPort="7054"
#######################################

################peer###################
# 定义 PeerOrgs 数组 "组织名称|域名|主机名(子域)|ca节点|组织普通用户数量(取最大值)"
PeerOrgs=(
  "com.luode.org13|org13.luode.com|peer0|0.0.0.0:7054|1"
  "com.luode.org13|org13.luode.com|peer1|0.0.0.0:7054|1"
 )
# 注: 一个域名下只能有一个peer组织
#  -> org3.xinhe.com域名下存在com.xinhe.org3组织, 再次定义com.xinhe.org4会覆盖之前的com.xinhe.org3
#######################################

################order##################
# 定义 OrdererOrgs 数组 "组织名称|域名|主机名(子域)|ca节点(本机节点使用0.0.0.0,外部ca需要配置Other)|组织普通用户数量(取最大值)"
OrdererOrgs=(
  "com.luode.OrdererOrg|luode.com|orderer0|0.0.0.0:7054|0"
  "com.luode.OrdererOrg|luode.com|orderer1|0.0.0.0:7054|0"
  "com.luode.OrdererOrg|luode.com|orderer2|0.0.0.0:7054|0"
)
# 注: 一个域名下只能有一个orderer组织
#  -> xinhe.com域名下存在com.xinhe.OrdererOrg1组织, 再次定义com.xinhe.OrdererOrg2会覆盖之前的com.xinhe.OrdererOrg1
#######################################

################ Other 外部ca###########
# 当且仅当 orderer 配置ca节点不为 0.0.0.0 时生效, 配置连接外部ca节点ip地址
OtherCaCert=/data/hyperledger/tls-ca/root-ca-cert.pem # 外部ca节点ca证书
OtherKey=/data/hyperledger/tls-ca/root-priv-sk # 外部ca节点ca证书私钥
OtherTlsCaCert=/data/hyperledger/tls-ca/root-tls-cert.pem # 外部ca节点tls证书私钥
OtherTlsKey=/data/hyperledger/tls-ca/root-tls-priv-sk # 外部ca节点tls证书私钥
OtherUserName="admin.OrdererOrg" # 用户名通过ca服务器数据表users获取管理员id
OtherPassWord="adminPW" # 密码统一为adminPw
#######################################

###########           脚本配置结束 ↑            ################


#########################################################################
########################### ↓ 配置 ↓ #####################################
##################### 请不要修改下面的配置 ##################################
########################### ↓ 配置 ↓ #####################################
#########################################################################

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
