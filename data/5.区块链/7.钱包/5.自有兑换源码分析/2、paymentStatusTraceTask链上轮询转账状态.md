# ellipal

paymentStatusTraceTask定时任务

 * 1. 开始任务日志记录。
 * 2. 查询所有处于等待支付状态的订单。
 - 3. 对于每一个等待支付的订单，获取其交易记录。

   - getTransHistory远程调用 golang api

   - getHistory获取交易历史数据

     - 第一次请求会刷新查询, 需要下一次调用才会获取这次刷新的记录
     - 1. 获取指定币种的节点 API 提供者。

     - 2. 从数据库获取历史记录。

     - 3. 检查是否有可用的历史 API。

     - 4. 如果需要刷新，则触发异步刷新任务。

     - 5. 如果查询结果为空，则等待刷新结果。

     - 6. 返回最终的历史记录。
 * 4. 检查交易记录以确定支付是否到账或超时。
 * 5. 根据检查结果更新订单状态，并记录相关日志。
 - 6. 结束任务日志记录。

   

# paymentStatusTraceTask定时任务

```java
    /**
     * 订单支付到账状态追踪任务, 链上轮询转账状态。
     *
     * 该定时任务定期检查处于等待支付状态(WAITING_PAYMENT)的订单，并更新其支付状态。
     * 如果检测到支付已经到账，则更新订单状态为等待风险对冲，并记录到账金额。
     * 如果订单超过有效期仍未支付，则更新订单状态为支付超时。
     * 
     * 为什么要用定时:
     * 因为获取链上的记录是调用第三方获取的, 查询时间可能会有10s的查询时间
     * 所以会调用golang的查询接口异步查询, 第一次请求会刷新查询, 需要下一次调用才会获取这次刷新的记录
     * 
     * 步骤：
     * 1. 开始任务日志记录。
     * 2. 查询所有处于等待支付状态的订单。
     * 3. 对于每一个等待支付的订单，获取其交易记录。
     * 4. 检查交易记录以确定支付是否到账或超时。
     * 5. 根据检查结果更新订单状态，并记录相关日志。
     * 6. 结束任务日志记录。
     */
    @Scheduled(fixedRate = 60000, initialDelay = 2000)
    public void paymentStatusTraceTask() {
        // 1. 开始任务日志记录。
        log.debug("************************收款入账任务开始*************************");

        // 2: 查询所有处于等待支付状态的订单
        InternalExchangeOrder condition = new InternalExchangeOrder();
        condition.setStatus(EllipalTransactionStatusEnum.WAITING_PAYMENT.getCode());
        List<InternalExchangeOrder> waitPaymentOrderList = exchangeOrderService
            .getTransactionListByConditions(condition);

        // 3: 遍历等待支付的订单列表
        waitPaymentOrderList.forEach(order -> {
            // 获取订单的历史交易记录(远程调用 golang api), 会返回最近多条
            List<TransactionDetailBO> data = ellipalWalletService.getTransHistory(order);

            // 查找符合条件的交易记录:
            // 1. 比较订单的应付款金额与交易记录的交易金额相等
            // 2. 交易记录的状态是否为 2 (链上转账成功)
            // 3. 交易记录的交易哈希（tx）是否与订单的交易哈希（txHashIn）相等
            Optional<TransactionDetailBO> optional = data.stream()
                .filter(item -> order.getFromAmount()
                        .compareTo(BigDecimal.valueOf(Double.parseDouble(item.getValue()))) == 0
                        && item.getStatus() == 2
                        && StringUtils.equalsIgnoreCase(item.getTx(), order.getTxHashIn()))
                .findFirst();

            // 4: 如果找到了匹配的交易记录
            TransactionDetailBO transactionDetailBO = optional.get();
            // 更新订单状态为等待风险对冲
            order.setStatus(EllipalTransactionStatusEnum.WAITING_RISK_HEDGING.getCode());
            // 记录入账金额
            order.setReceiveAmount(BigDecimal.valueOf(Double.parseDouble(transactionDetailBO.getValue())));
            // 更新订单的最后修改时间
            order.setUpdateTime(DateUtil.date());

            // 添加到已支付订单列表
            paidOrders.add(order.getOrderId());
            // 添加到需要更新的订单列表
            updateOrders.add(order);
        });

        // 5: 如果有需要更新的订单，则进行批量更新(状态, 时间, 入账金额)
        if (CollectionUtil.isNotEmpty(updateOrders)) {
            exchangeOrderService.saveOrUpdateTransaction(updateOrders);
        }
    }
```



# getTransHistory远程调用 golang api

```java
    /**
     * 获取交易历史。
     * 
     * 该方法根据提供的交易订单信息，通过远程调用获取指定币种、地址和合约地址的交易历史，并返回交易详情列表。
     *
     * @param order 内部交易订单对象，包含获取交易历史所需的信息。
     * @return 交易详情列表，如果获取失败则返回空列表。
     */
    public List<TransactionDetailBO> getTransHistory(InternalExchangeOrder order) {
        // 初始化参数映射
        Map<String, Object> params = new HashMap<>();

        // 设置请求参数
        params.put("coinName", order.getLNetwork());// 币种名称
        params.put("address", order.getPlatformReceiveAddress()); // 公司接收地址
        params.put("contractAddr", order.getLContractAddress()); // 合约地址
        params.put("direction", "all"); // 方向，获取所有方向的交易记录
        params.put("limit", PAGE_SIZE); // 单次请求的最大返回记录数(50)
        params.put("offset", 0); // 分页偏移量，此处为获取第一页数据

        // 发起远程调用 "/api/getHistory" (golang)，获取交易历史数据
        JSONObject dataJSON = RemoteClient.postForJSON(ellipalTransHistoryUrl, params, null);

        // 检查返回数据的状态
        if (dataJSON != null && dataJSON.getBoolean("status")) {
            // 如果状态为成功，则解析返回的数据为交易详情列表
            return JSONArray.parseArray(dataJSON.getString("data"), TransactionDetailBO.class);
        }
        return new ArrayList<>();
    }
```



# getHistory获取交易历史数据

```go
// GetHistory 方法用于获取指定币种的历史记录。
// 根据请求参数从数据库中获取历史记录，并根据需要触发异步刷新。
//
//	如果历史记录为空并且是第一次查询，则等待刷新结果后再返回。
//	如果是已经有查询缓存, 则本次请求会刷新查询, 但是返回的是之前的缓存, 需要下一次调用才会获取这次刷新的记录
//
// 步骤：
// 1. 获取指定币种的节点 API 提供者。
// 2. 从数据库获取历史记录。
// 3. 检查是否有可用的历史 API。
// 4. 如果需要刷新，则触发异步刷新任务。
// 5. 如果查询结果为空，则等待刷新结果。
// 6. 返回最终的历史记录。
func (s *Coin) GetHistory(req request.ReqGetHistory) ([]mongod_model.History, error) {
	// 步骤 1: 获取指定币种的节点 API 提供者
	nodeAPI, exist := coins.NewNodeProvider().GetNodeAPI(req.CoinName)
	if !exist {
		// 如果不支持该币种，返回错误
		return nil, fmt.Errorf("coinName %s not support", req.CoinName)
	}

	// 创建一个通道，用于等待异步刷新的结果: 查询成功会返回一个 req.WaitCH <- struct{}{}
	req.WaitCH = make(chan struct{})

	// db->是否需要刷新->是否第一次取历史记录->等待结果返回
	var resp []mongod_model.History
	limit := req.Limit

	// 步骤 2: 从MongoDB获取历史记录
	resp = nodeAPI.GetHistoryFromDB(req.ContractAddr, req.Address, req.Direction, req.StartTime, req.EndTime, req.Offset, limit)

	// 记录查询结果的数量
	req.DataCount = len(resp)

	// 检查是否有可用的历史 API(MongoDB实例)
	if len(nodeAPI.GetHistoryAPIs()) == 0 {
		// 如果没有可用的 API，直接返回现有的历史记录
		return resp, nil
	}

	// redis构建查询键
	key := s.rdb.BuildHistoryQueryKey(req.CoinName, req.Address, req.ContractAddr)
	// redis检查查询是否过期
	needRefresh := s.rdb.IsQueryExpire(key, time.Now().Unix())

	// 步骤 4: 如果需要刷新，则触发异步刷新任务
	if needRefresh {
		// 触发异步刷新历史记录的任务, 传递参数, 通过 req.WaitCH 通信
		s.jobEntity.GetHistoryCh() <- req
		// redis更新查询时间戳
		s.rdb.UpdateQueryTimeTsp(key)
	}

	// 步骤 5: 如果查询结果为空，则等待刷新结果
	if len(resp) == 0 {
		// 构建历史记录的键
		historyKey := req.CoinName + "|" + req.Address + "|" + req.ContractAddr
		_, ok := s.historyAddressMap[historyKey]
		if !ok {
			// 如果是第一次查询该地址的历史记录
			s.historyAddressMap[historyKey] = true
			// 在通道上等待
			<-req.WaitCH

			// 再次从数据库获取历史记录
			resp = nodeAPI.GetHistoryFromDB(req.ContractAddr, req.Address, req.Direction, req.StartTime, req.EndTime, req.Offset, limit)
		}
	}

	// 步骤 6: 返回最终的历史记录
	return resp, nil
}

```

