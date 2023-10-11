#!/bin/bash
# author 罗德

#########################################################################
########################### ↓ 配置 ↓ #####################################
##################### cicd一键部署配置 ##################################
########################### ↓ 配置 ↓ #####################################
#########################################################################

# 通道名称
channel="channel"

# peer配置 -> cli容器名称|peer容器名称
peers=(
  "cli-org-peer0|peer0.org.dns.com"
  "cli-org-peer1|peer1.org.dns.com"
)

# orderer配置 -> cli容器名称(任意一个可用的即可)|orderer容器名称
orderers=(
  "cli-org-peer0|orderer0.dns.com"
  "cli-org-peer0|orderer1.dns.com"
  "cli-org-peer0|orderer2.dns.com"
)

#########################################################################
########################### ↓ 配置 ↓ #####################################
##################### 请不要修改下面的配置 ##################################
########################### ↓ 配置 ↓ #####################################
#########################################################################

# 流程控制 init=初始化通道 join=加入通道 list=查询通道
# json=获取通道最新配置块(1) addorg=通道添加组织(2) sign=组织签名(3) update=提交更新(4)
process=$1

# 通道名称
nameChannel=$2

# [可选]通道模板: one、two / 签名json: ./channel-artifacts/mychannel-addorg-Org3-update.json
templateChannel=$3
updateChannel=$3

help() {
      echo "帮助: "
      echo ""
      echo "可用参数: cicd, init, join, list, json, addorg, sign, config, update"
      echo ""
      echo "一键部署新通道 ./channel.sh cicd"
      echo "初始化通道 ./channel.sh init onechannel"
      echo "加入通道 ./channel.sh join onechannel"
      echo "打印通道信息 ./channel.sh list onechannel"
      echo "获取通道运行配置 ./channel.sh json onechannel"
      echo "提交新配置 ./channel.sh config onechannel"
      echo "添加新组织 ./channel.sh addorg onechannel"
      echo "背书签名 ./channel.sh sign onechannel"
      echo "更新签名 ./channel.sh update onechannel"
}

# 初始化通道: 创建 通道初始区块、通道配置
initChannel() {
############################  参数校验  ##############################
	checkConfigFiles

	# 检查通道名称参数是否为空
    if [ -z "$nameChannel" ]; then
        echo "检查通道名称"
        help
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
		echo ""
		echo ""
		echo "通道初始区块"$nameChannel"初始化完成, 目录: ./channel-artifacts/"$nameChannel".block"
	else
	  echo ""
	  echo ""
		echo "通道初始区块"$nameChannel"初始化失败"
	fi
    
	if configtxgen -profile $templateChannel -outputCreateChannelTx ./channel-artifacts/$nameChannel.tx -channelID $nameChannel; then
	  echo ""
	  echo ""
		echo "通道配置"$nameChannel"初始化完成, 目录: ./channel-artifacts/"$nameChannel".tx"
	else
	  echo ""
	  echo ""
		echo "通道配置"$nameChannel"初始化失败"
	fi
	# 授予通道配置权限
	chmod -R 777 channel-artifacts
}

# 加入通道
joinChannel() {
############################  参数校验 #######################################
	checkConfigFiles
    if [ -z "$nameChannel" ]; then
        echo "检查通道名称"
        help
        exit 1
    fi
    
############################  选择cli客户端工具 ################################
	# 执行 docker 命令并输出容器名称
	if [ -z "$docker_exec" ]; then
    echo "运行中的客户端工具容器："
    docker ps --format "{{.Names}}" | grep -E "^cli-"

    # 读取用户输入的容器名称，如果用户没有输入，则使用第一个容器名称
    read -e -p "请选择peer客户端工具(cli-org-peer)：" input_cli_address
    docker_exec=${input_cli_address}
  fi
############################  选择peer/orderer节点 ##########################
	# 截取容器名称中的组织和 Peer 名称
	org=$(echo $docker_exec | cut -d'-' -f2)
	peer=$(echo $docker_exec | cut -d'-' -f3)

  if [ -z "$node_address" ]; then
    	# 列出所有正在运行的 Docker 容器
    	docker ps --format '{{.Names}}' | grep -E "^${peer}.*${org}|^orderer"

    	# 读取用户输入的容器名称
    	read -e -p "请选择输入加入的节点名称, 排序节点可在任意一个容器执行加入通道
    (多个节点名称用空格分隔):" input_node_address
    	node_address=${input_node_address}
  fi


############################  docker加入通道 ###############################

	# 重启刷新挂载的文件
	docker restart $docker_exec
	sleep 1
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

cicd(){
    if [ -z "$channel" ]; then
        echo "检查通道名称"
        help
        exit 1
    fi

    nameChannel=$channel
    if [ -f "./channel-artifacts/${nameChannel}.tx" ]; then
      echo "通道存在, 节点加入通道"
    else
      # 初始化通道
      initChannel
    fi

    # 是否有peer节点加入
    for key in "${peers[@]}"; do
      # 使用冒号分隔符将域名和主机名拆分为变量
      IFS="|" read -r cli peer <<< "$key"
      echo "----------------"
      echo "cli客户端: $cli"
      echo "peer节点: $peer"
      docker_exec=$cli
      node_address=$peer
      joinChannel
    done

    # 是否有orderer节点加入
    for key in "${orderers[@]}"; do
      # 使用冒号分隔符将域名和主机名拆分为变量
      IFS="|" read -r cli orderer <<< "$key"
      echo "----------------"
      echo "cli客户端: $cli"
      echo "orderer节点: $orderer"
      docker_exec=$cli
      node_address=$orderer
      joinChannel
    done

    listChannel
}

# 获取通道最新配置块
jsonChannel() {
############################  参数校验 #####################################
	checkConfigFiles
	# 检查通道名称参数是否为空
    if [ -z "$nameChannel" ]; then
        echo "检查通道名称"
        help
        exit 1
    fi

############################  选择cli客户端工具 #############################
	echo "运行中的客户端工具容器："
	docker ps --format "{{.Names}}" | grep -E "^cli-"

	# 读取用户输入的容器名称，如果用户没有输入，则使用第一个容器名称
	read  -e -p "请选择peer客户端工具(cli-org-peer)：" input_peer_address
	docker_exec=${input_peer_address}
	
############################  选择orderer节点 ############################
	# 列出所有正在运行的 Docker 容器 
	echo "正在运行的 orderer 节点："
	docker ps --format "{{.Names}} {{.Ports}}" | grep order | while read -r name ports; do
		node_dns=$(echo "$name" | awk '{print $1}')
		node_port=$(echo "$ports" | sed 's/.*->\([0-9]*\).*/\1/g')
		echo "$node_dns:$node_port"
	done

	# 读取用户输入的容器名称，默认第一个
	read -e -p "请选择通道内可执行交易的orderer节点(ip:port), 如果需要提交交易到其他服务器的排序节点, 请手动调整
(orderer0.luode.com:7051)：" input_orderer_address
	orderer_address=${input_orderer_address}

############################  docker #################################
	# 获取 ":" 之前的第二个点部分(orderer0.xinhe.com -> xinhe.com)
	dnsPath=$(echo $orderer_address | awk -F ':' '{print $1}' | cut -d'.' -f2- )

	docker exec -it $docker_exec bash -c "\
		# 获取初始区块, 等同于获取init初始化通道配置
		peer channel fetch 0 /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/${nameChannel}.block -o $orderer_address -c $nameChannel --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/$dnsPath/msp/tlscacerts/*
		echo \"\"
		echo \"初始区块:  ./channel-artifacts/${nameChannel}.block \"
		
		# 获取最新的配置区块 -> onechannel.pb
		peer channel fetch config /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/${nameChannel}.pb -o $orderer_address -c $nameChannel --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/$dnsPath/msp/tlscacerts/*
		echo \"\"
		echo \"最新的配置区块:  ./channel-artifacts/${nameChannel}.pb \"

		# 转为json, 取其中config部分的数据
		configtxlator proto_decode --input /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/${nameChannel}.pb --type common.Block | jq .data.data[0].payload.data.config > /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/${nameChannel}.json
		echo \"\"
		echo \"最新的配置区块json:  ./channel-artifacts/${nameChannel}.json \"
	"
}

# 通道添加组织
addorgChannel() {
############################  参数校验 ######################
	checkConfigFiles
	# 检查通道名称参数是否为空
    if [ -z "$nameChannel" ]; then
        echo "检查通道名称"
        help
        exit 1
    fi
    # 检查通道模板名称参数是否为空
    if [ -z "$templateChannel" ]; then
        templateChannel="TwoOrgsChannel" 
        echo "通道模板默认使用TwoOrgsChannel"
    fi
    # 组织name名称
	read  -e -i "Org"  -p "指定要添加的组织name, 该name必须在configtx中配置
(例: Org16)：" input_org
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
        echo "检查通道名称"
        help
        exit 1
    fi
############################  选择cli客户端工具 ############################
  if [ -z "$docker_exec" ]; then
      echo "运行中的客户端工具容器："
    	docker ps --filter "name=cli*" --format "table {{.Names}}"

    	# 读取用户输入的容器名称，如果用户没有输入，则使用第一个容器名称
    	read -e -p "请选择peer客户端工具(cli-org-peer)：" input_peer_address
    	docker_exec=${input_peer_address}
  fi
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
		echo \"加入通道$nameChannel的peer节点：\"
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

if [ -z "$process" ]; then
    help
elif [ $process == "help" ]; then
    help
elif [ $process == "" ]; then
    help
elif [ $process == "init" ]; then
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
elif [ $process == "cicd" ]; then
    #一键部署新通道
    cicd
else
    help
fi