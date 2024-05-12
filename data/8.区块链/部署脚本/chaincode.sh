#!/bin/bash
# author 罗德

#########################################################################
########################### ↓ 配置 ↓ #####################################
##################### cicd一键部署配置 ##################################
########################### ↓ 配置 ↓ #####################################
#########################################################################
# 链码包名称
ChainCodePath="chaincode.tar.gz"
# 链码启动配置
chainYaml="chaincode.yaml"

# 通道名称
channel="mychannel"
# 链码名称
chainName="mycc"
# 链码版本
chainVersion="1.0"
# 链码序列号(每次升级都手动加1)
chainSequence="1"

# peer配置(安装链码的节点) -> cli容器名称|peer容器名称
peers=(
  "cli-org-peer0|peer0.org.dns.com:7150|orderer0.dns.com:7051"
  "cli-org-peer1|peer1.org.dns.com:7152|orderer0.dns.com:7051"
)

#########################################################################
########################### ↓ 配置 ↓ #####################################
##################### 请不要修改下面的配置 ##################################
########################### ↓ 配置 ↓ #####################################
#########################################################################

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

help() {
      echo "帮助: "
      echo ""
      echo "可用参数: cicd, install, invoke, query, info"
      echo ""
      echo "一键安装/升级链码 ./chaincode.sh cicd"
      echo "安装/升级链码 ./chaincode.sh install mychannel mycc 1.0 1"
      echo "查询链码 ./chaincode.sh query mychannel mycc '[\"get\",\"tom\"]'"
      echo "调用链码 ./chaincode.sh invoke mychannel mycc set '[\"tom\",\"大懒猫\"]'"
      echo "链码信息 ./chaincode.sh info mychannel"
}

cicd(){

    if [ -z "$channel" ]; then
        echo "检查通道名称"
        help
        exit 1
    fi

    channelChainCode=$channel
    nameChainCode=$chainName
    versionChainCode=$chainVersion
    sequenceChainCode=$chainSequence
    index=0
    for key in "${peers[@]}"; do
      # 使用冒号分隔符将域名和主机名拆分为变量
      IFS="|" read -r cli peer orderer <<< "$key"
      echo "----------------"
      echo "cli客户端: $cli"
      echo "peer节点: $peer"
      container_name=$cli
      peer_names=$peer
      orderer_address=$orderer
      installChainCode
      index=1
    done

}

# 安装/升级链码
installChainCode() {
    current_directory=$PWD
############################  安装/升级链码 -> 参数校验  ############################################################
	  # 检查链码通道是否为空
    if [ -z "$channelChainCode" ]; then
        echo "检查链码通道"
        help
        exit 1
    fi
	  # 检查链码名称是否为空
    if [ -z "$nameChainCode" ]; then
        echo "检查链码名称"
        help
        exit 1
    fi
    # 检查链码版本是否为空
    if [ -z "$versionChainCode" ]; then
        echo "注意: 默认链码版本(1.0), 对已经存在的链码安装/升级尽量不使用默认版本..."
		    versionChainCode="1.0"
    fi
    # 检查链码版本号是否为空
    if [ -z "$sequenceChainCode" ]; then
        echo "注意: 默认链码版本号(1), 版本号唯一, 对已经存在的链码安装/升级不能使用默认版本号, 指定递增的版本号..."
		    sequenceChainCode="1"
    fi

############################  安装/升级链码 -> 选择cli客户端工具 ###################
  	if [ -z "$container_name" ]; then
  	    # 执行 docker 命令并输出容器名称
        echo ""
      	echo "运行中的客户端工具容器："
      	docker ps --format "table {{.Names}}" | grep -E "^cli-*"

      	# 读取用户输入的容器名称
      	read  -e -p "请选择peer客户端工具(cli-org-peer):" input_container_names
      	container_name=${input_container_names:-$container_name}
  	fi
############################ 选择orderer节点  #########################################
  if [ -z "$orderer_address" ]; then
    # 列出所有正在运行的 Docker 容器
    echo ""
    echo "正在运行的 orderer 排序节点："
    docker ps --format "{{.Names}} {{.Ports}}" | grep order | while read -r name ports; do
      node_address=$(echo "$name" | awk '{print $1}')
      node_port=$(echo "$ports" | sed 's/.*->\([0-9]*\).*/\1/g')
      echo "$node_address:$node_port"
    done

    # 读取用户输入的容器名称
    read -e -p "请选择通道内可执行交易的orderer节点(ip:port), 如果需要提交交易到其他服务器的排序节点, 请手动调整
  (orderer0.luode.com:7051)：" input_node_address
    orderer_address=${input_node_address}
  fi
############################  安装/升级链码 -> docker安装/升级链码  ###################
  # 打包安装链码
  if [ -f "./chaincode/go/${ChainCodePath}" ]; then
		gojava="golang"
		echo "go语言环境..."
	else
		ChainCodePath="chaincode/go"
		gojava="java"
		echo "java语言环境..."
	fi

	# 获取 ":" 之前的第二个点部分(orderer0.xinhe.com -> xinhe.com)
	dnsPath=$(echo $orderer_address | awk -F ':' '{print $1}' | cut -d'.' -f2- )

	# 同步时间
	hwclock --hctosys
	clock -w
  if [ ${gojava} == "golang" ]; then
      	docker exec -it $container_name bash -c "\
      		# 安装链码
      		echo \"$container_name安装链码... \"
      		peer lifecycle chaincode install /opt/gopath/src/github.com/hyperledger/fabric-cluster/chaincode/go/${ChainCodePath} > /var/log/package_id.log 2>&1
      		grep -oE ":[a-f0-9]{64}" /var/log/package_id.log | head -n 1 > /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/package_id.log
        "
  else
     	docker exec -it $container_name bash -c "\
     		# 打包java链码
     		echo \"$container_name打包链码... \"
     		peer lifecycle chaincode package $nameChainCode.tar.gz --path /opt/gopath/src/github.com/hyperledger/fabric-cluster/${ChainCodePath} --lang ${gojava} --label $nameChainCode
     		# 安装链码
     		echo \"$container_name安装链码... \"
     		peer lifecycle chaincode install $nameChainCode.tar.gz > /var/log/package_id.log 2>&1
     		grep -oE ":[a-f0-9]{64}" /var/log/package_id.log | head -n 1 > /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/package_id.log
       "
  fi

  ############################ 选择链码  ################################################
    # 读取用户输入的容器名称
  #	echo ""
  #	echo "批准链码(如果该链码已经在组织其他节点批准, 则不需要再次批准, 安装后可直接使用)..."
  #	read -p "请选择安装好的链码(mycc:xxxxxx)：" package_id

  ############################ 批准链码  ############################################################
  sleep 1
  # 获取链码包
  chmod 777 $current_directory/channel-artifacts/package_id.log
  package_id=$(<$current_directory/channel-artifacts/package_id.log)

  if [ ${gojava} == "golang" ]; then
    string=$ChainCodePath
    oldChainCode="${string%%.*}"
  fi

	# 批准链码
	docker exec -it $container_name bash -c "\
    # 批准链码定义
    echo \"$container_name批准链码... \"
    peer lifecycle chaincode approveformyorg --channelID $channelChainCode --name $nameChainCode --version $versionChainCode --init-required --package-id '${oldChainCode}${package_id}' --sequence $sequenceChainCode --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/$dnsPath/msp/tlscacerts/* --orderer $orderer_address

#    echo \"\"
#    echo \"$container_name检测就绪状态(如果该链码在其他组织检测完成提交, 可忽略检测信息): \"
#    peer lifecycle chaincode checkcommitreadiness --channelID $channelChainCode --name $nameChainCode --version $versionChainCode --init-required --sequence $sequenceChainCode --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/$dnsPath/msp/tlscacerts/* --orderer $orderer_address --output json
	"
			commitChainCode
}

# 提交链码
commitChainCode() {
############################  提交链码 -> 参数校验 ######################################
	  # 检查链码通道是否为空
    if [ -z "$channelChainCode" ]; then
        echo "检查链码通道"
        help
        exit 1
    fi
	  # 检查链码名称是否为空
    if [ -z "$nameChainCode" ]; then
        echo "检查链码名称"
        help
        exit 1
    fi
    # 检查链码版本是否为空
    if [ -z "$versionChainCode" ]; then
        echo "注意: 默认链码版本(1.0), 对已经存在的链码安装/升级尽量不使用默认版本..."
		    versionChainCode="1.0"
    fi
    # 检查链码版本号是否为空
    if [ -z "$sequenceChainCode" ]; then
        echo "注意: 默认链码版本号(1), 版本号唯一, 对已经存在的链码安装/升级不能使用默认版本号, 指定递增的版本号..."
		    sequenceChainCode="1"
    fi

############################  提交链码 -> 选择cli客户端工具  ############################################################
	if [ -z "$container_name" ]; then
		echo "运行中的客户端工具容器："
		docker ps --filter "name=cli*" --format "table {{.Names}}" | grep -E "^cli-*"
		# 读取用户输入的容器名称
		read  -e -p "请选择peer客户端工具(cli-org-peer):" input_container_name
		container_name=${input_container_name}
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

		# 读取用户输入的容器名称，默认第一个
		read -e -p "请选择通道内可执行交易的orderer节点(ip:port), 如果需要提交交易到其他服务器的排序节点, 请手动调整
(orderer0.luode.com:7051)：" input_orderer_address
		orderer_address=${input_orderer_address}
	fi

############################  提交链码 -> docker提交链码  #######################
	# 获取 ":" 之前的第二个点部分(orderer0.xinhe.com -> xinhe.com)
	dnsPath=$(echo $orderer_address | awk -F ':' '{print $1}' | cut -d'.' -f2- )

	peer=$(echo "$peer_names" | sed 's/:.*//')
	order=$(echo "$orderer_address" | sed 's/:.*//')
	org=$(echo "$peer" | sed 's/^[^.]*\.//')

	# 提交链码
  if [ "${gojava}" == "java" ]; then
		gojava="'{\"function\":\"createCat\",\"Args\":[\"cat\" , \"tom\" ,  \"3\" , \"蓝色\" , \"我是初始记录\"]}'"
		echo "java语言环境..."
    docker exec -it $container_name bash -c "\
      echo \"\"
      echo \"$container_name提交链码... \"
      peer lifecycle chaincode commit -o $orderer_address --channelID $channelChainCode --name $nameChainCode --version $versionChainCode --sequence $sequenceChainCode \
      --init-required --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/$dnsPath/msp/tlscacerts/* \
      --peerAddresses $peer_names --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/$org/peers/$peer/tls/ca.crt \

      if [ \"$sequenceChainCode\" = \"1\" ]; then
        echo \"\"
        echo \"$container_name初始化... \"
        peer chaincode invoke -o $orderer_address --isInit --ordererTLSHostnameOverride $order --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/$dnsPath/msp/tlscacerts/* -C $channelChainCode -n $nameChainCode --peerAddresses $peer_names --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/$org/peers/$peer/tls/ca.crt -c ${gojava}
      fi
      sleep 2
      echo \"\"
      echo \"$container_name查询初始记录: \"
      peer chaincode query -C $channelChainCode -n $nameChainCode -c '{\"Args\":[\"get\",\"cat\"]}'
    "
    exit 1
	fi

  gojava="'{\"Args\":[\"cat\",\"我是初始记录\"]}'"
  echo "go语言环境..."
  if [ "${index}" == "0" ]; then
    docker exec -it $container_name bash -c "\
      echo \"\"
      echo \"$container_name提交链码... \"
      peer lifecycle chaincode commit -o $orderer_address --channelID $channelChainCode --name $nameChainCode --version $versionChainCode --sequence $sequenceChainCode \
      --init-required --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/$dnsPath/msp/tlscacerts/* \
      --peerAddresses $peer_names --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/$org/peers/$peer/tls/ca.crt \
    "
  fi

  # 启动外部链码
  docker-compose -f ${chainYaml} down
  CHAINCODE_ID=${oldChainCode}${package_id} docker-compose -f ${chainYaml} up -d

  if [ "${index}" == "0" ]; then
      docker exec -it $container_name bash -c "\
        if [ \"$sequenceChainCode\" = \"1\" ]; then
          echo \"\"
          echo \"$container_name初始化... \"
          peer chaincode invoke -o $orderer_address --isInit --ordererTLSHostnameOverride $order --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/$dnsPath/msp/tlscacerts/* -C $channelChainCode -n $nameChainCode --peerAddresses $peer_names --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/$org/peers/$peer/tls/ca.crt -c ${gojava}
        fi
      "
  fi

  docker exec -it $container_name bash -c "\
    sleep 2
    echo \"\"
    echo \"$container_name查询初始记录: \"
    peer chaincode query -C $channelChainCode -n $nameChainCode -c '{\"Args\":[\"get\",\"cat\"]}'
  "
}

# 调用链码
invokeChainCode() {
############################  调用链码 -> 参数校验  ############################################################
	# 检查链码通道是否为空
    if [ -z "$channelChainCode" ]; then
        echo "检查链码通道"
        help
        exit 1
    fi
	  # 检查链码名称是否为空
    if [ -z "$nameChainCode" ]; then
        echo "检查链码名称"
        help
        exit 1
    fi
    # 检查链码方法是否为空
    if [ -z "$functionChainCode" ]; then
        echo "检查链码方法"
        help
        exit 1
    fi
    # 检查链码方法参数是否为空
    if [ -z "$ArgsChainCode" ]; then
        echo "检查链码方法参数"
        help
        exit 1
    fi

############################  调用链码 -> 选择cli客户端工具  ############################################################
	echo "运行中的客户端工具容器："
	docker ps --filter "name=cli*" --format "table {{.Names}}" | grep -E "^cli-*"

	# 读取用户输入的容器名称，如果用户没有输入，则使用第一个容器名称
	read  -e -p "请选择peer客户端工具(cli-org-peer):" input_container_name
	container_name=${input_container_name}
	
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
		node_port=$(echo "$ports" | awk -F "->|/" '{for(i=1; i<=NF; i++) if($i ~ /^[0-9]+$/) {print $i; break}}')
		echo "$node_address:$node_port"
	done

	# 读取用户输入的容器名称，默认第一个
	read -e -p "请选择通道内可执行交易的orderer节点(ip:port), 如果需要提交交易到其他服务器的排序节点, 请手动调整
(orderer0.dns.com:7051)：" input_orderer_address
	orderer_address=${input_orderer_address}

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
############################  查询链码 -> 参数校验  ############################################################
	# 检查链码通道是否为空
    if [ -z "$channelChainCode" ]; then
        help
        exit 1
    fi
	# 检查链码名称是否为空
    if [ -z "$nameChainCode" ]; then
        help
        exit 1
    fi
    # 检查链码方法是否为空
    if [ -z "$functionChainCode" ]; then
        help
        exit 1
    fi

	ArgsChainCode=$functionChainCode
############################  查询链码 -> 选择cli客户端工具  ############################################################
	echo "运行中的客户端工具容器："
	docker ps --filter "name=cli*" --format "table {{.Names}}" | grep -E "^cli-*"

	# 读取用户输入的容器名称，如果用户没有输入，则使用第一个容器名称
	read  -e -p "请选择peer客户端工具(cli-org-peer):" input_container_name
	container_name=${input_container_name}

############################  查询链码 -> 调用查询链码  ############################################################
	docker exec -it $container_name bash -c "\
		echo \"查询$channelChainCode通道已完成提交的链码信息: \"
		peer chaincode query -C $channelChainCode -n $nameChainCode -c '{\"Args\":$ArgsChainCode}'
	"
}

# 链码信息
infoChainCode() {
############################  链码信息 -> 参数校验  ############################################################
	# 检查链码通道是否为空
    if [ -z "$channelChainCode" ]; then
        echo "检查链码通道"
        help
        exit 1
    fi

############################  链码信息 -> 选择cli客户端工具  ############################################################
	echo "运行中的客户端工具容器："
	docker ps --filter "name=cli*" --format "table {{.Names}}" | grep -E "^cli-*"

	# 读取用户输入的容器名称，如果用户没有输入，则使用第一个容器名称
	read  -e -p "请选择peer客户端工具(cli-org-peer):" input_container_name
	container_name=${input_container_name}

############################  链码信息 -> docker查询链码  ############################################################
	docker exec -it $container_name bash -c "\
		echo \"\"
		if [ -z \"$nameChainCode\" ]; then
			echo \"$channelChainCode通道查询所有链码: \"
			peer lifecycle chaincode querycommitted -C $channelChainCode
		else
			peer lifecycle chaincode querycommitted -C $channelChainCode -n $nameChainCode
		fi
	"
}

if [ -z "$process" ]; then
    help
elif [ $process == "help" ]; then
    help
elif [ $process == "cicd" ]; then
    # 安装/升级链码
    cicd
elif [ $process == "install" ]; then
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
    help
fi