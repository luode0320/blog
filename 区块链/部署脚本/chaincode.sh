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