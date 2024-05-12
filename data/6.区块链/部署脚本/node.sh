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
    checkConfigFiles
	for configPath in "${configPaths[@]}"; do
		docker-compose -f "$configPath" up -d 2>&1 | grep -v -E "^WARNING: " | grep -v -E "^Found orphan containers"
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
		docker-compose -f "$configPath" stop 2>&1 | grep -v -E "^WARNING: "
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
      docker-compose -f "$configPath" restart 2>&1 | grep -v -E "^WARNING: "
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
   docker ps --format "table {{.Names}}\t{{.Ports}}"
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
				rm -rf ./hyperledger
				rm -rf ./channel-artifacts
				rm -rf ./tls-ca
		else
			exit 1
		fi
	else
		exit 1
	fi
    listNode
    echo "重置网络完成, 你可以通过 ./xx.sh start 命令重新部署节点, 重新配置通道、链码等信息"
}

# 打开容器
openNode() {
    if [ ${#configPaths[@]} -eq 0 ]; then
      echo ""
      echo "运行中的客户端工具容器："
      docker ps --filter "name=cli*" --format "table {{.Names}}" | grep -E "^cli-*"
      # 读取用户输入的容器名称，如果用户没有输入，则使用第一个容器名称
      echo ""
      read  -e -p "请选择peer客户端工具(cli-org-peer)：" input_container_name
      container_name=${input_container_name:-$container_name}

      docker exec -it $container_name bash
    else
        for configPath in "${configPaths[@]}"; do
          docker exec -it $configPath bash
          exit 1
        done
    fi
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

help() {
      echo "帮助: "
      echo ""
      echo "可用参数: start, stop, restart, down, resetting, log, open, list"
      echo ""
      echo "启动节点 ./node.sh start orderer1.yaml orderer2.yaml"
      echo "停止节点 ./node.sh stop orderer1.yaml orderer2.yaml"
      echo "重启节点 ./node.sh restart orderer1.yaml orderer2.yaml"
      echo "卸载节点 ./node.sh down orderer1.yaml orderer2.yaml"
      echo "重置网络 ./node.sh resetting"
      echo "打印日志 ./node.sh log orderer1.yaml"
      echo "进入容器 ./node.sh open orderer1.yaml"
      echo "打印信息 ./node.sh list"
}


if [ -z "$process" ]; then
    help
elif [ $process == "help" ]; then
    help
elif [ $process == "" ]; then
    help
elif [ $process == "start" ]; then
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
  help
fi