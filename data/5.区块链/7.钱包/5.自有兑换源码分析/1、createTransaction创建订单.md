# ellipal

1. `exchangenew`请求入口

   - 创建交易订单

2. `generateOrder`策略分配交易所

   - 根据汇率策略获取相应的处理对象，并处理订单请求
   - 发送请求到交易所下单(公司实现的自有兑换)

3. `createTransaction`创建交易请求

   - 自有兑换创建交易

4. `createTransaction`创建交易的具体实现

    - 1. 创建交易结果数据传输对象

    - 2. `checkOrder`检查交易请求是否满足交易条件

       - (验证交易订单的金额是否符合步长要求，是否存在待处理的订单以及资产池是否有足够的余额)

       - 1. 验证交易金额是否符合步长要求 -> 比如步长是0.01, 不能出现0.009、0.015这种转账金额

       - 2. 获取支持的币对详细配置 -> 币的名称、网络、合约等

       - 3. 检查交易金额是否在允许的范围内

       - 4. 查询符合条件的待处理订单列表 -> 检查是否已经存在待处理的订单(已经收到钱, 还没有换)

       - 5. 获取钱包余额信息 -> 返回指定网络的所有币种余额的映射表。

       - 6. 检查资产池是否不足，并在不足时触发资产补充任务。

          - `HedgingRechargeTask`将币充值到交易所

             * 1. 获取币种当前的余额
             * 2. 获取未完成的对冲订单
             * 3. 计算所有未完成对冲订单的总交易量
             * 4. 根据提供的网络类型来确定应使用的自有兑换转账处理器名称
             * 5. 从 Spring 容器中获取转账处理器实例
             - 6. 构建转账信息请求并执行转账操作

               - `doExecute`构建转账信息请求并 执行转账
                 - 1.发送转账请求
                  * 2.签名交易。
                  * 3.转账
             * 7. 批量更新对冲订单的状态为已对冲充值

    - 3. 将请求数据传输对象转换为内部交易订单实体, 设置交易订单的其他属性

    - 4. 保存交易订单

    - 5. 填充交易结果数据响应对象



# exchangenew请求入口

```java

    /**
     * 创建兑换订单的处理方法。
     */
    // @Resubmit(ttl = 30)
    @GetMapping(value = "exchangenew")
    public String createOrder(HttpServletRequest httpRequest, @RequestParam Map<String, Object> params) {
        // 创建交易订单
        ETransactionResult result = exchangeClient.createOrder(request);
    }
```

# generateOrder策略分配交易所

```java
    /**
     * 处理生成订单的POST请求。
     *
     * @param request 包含订单请求信息的对象。
     * @return 返回订单处理的结果。
     */
    @PostMapping(value = "generateOrder")
    public ETransactionResult generateOrder(@RequestBody ETransactionRequest request) {
        // 根据汇率策略获取相应的处理对象，并处理订单请求
        return brainFactory.getBrain(strategy).processOrder(request);
    }

    /**
     * 处理数字资产交易请求。
     *
     * @param request 数字资产交易请求对象。
     * @return 交易结果对象。
     */
    @Override
    public ETransactionResult processOrder(ETransactionRequest request) {
        // 向交易所发送交易请求
        result = sendTransaction(request);
    }

    /**
     * 发送请求到交易所下单
     * 
     * @param request 请求信息包含需要发送的交易所
     * @return 下单结果
     */
    protected ETransactionResult sendTransaction(ETransactionRequest request) {
        // 构建完整的URL地址(通过eureka远程调用), 使用restTemplate发送POST请求，并获取响应结果
        ETransactionResult res = restTemplate.postForObject(
                StringUtil.buildString("http://", 
                                       exchange.getExchangeUri(),
                                       "/cp/createTransaction"),
                entity,
                ETransactionResult.class);

    }
```



# 1. createTransaction创建交易请求

- 处理创建交易请求的POST请求

```java
    /**
     * 处理创建交易请求的POST请求。
     * 
     * 该方法接收一个交易请求对象，然后通过内部服务创建交易，并返回交易结果。
     *
     * @param request 交易请求对象。
     * @return 交易结果对象。
     */
    @PostMapping(value = "/createTransaction")
    public ETransactionResult createTransaction(@RequestBody ETransactionRequest request) {
        	...
            // 自有兑换创建交易
            TransactionResDTO response = dataCenterService.createTransaction(reqDTO);
        	...
            // 返回交易成功的结果
            return result;
    }
```

- 自有兑换创建交易

```java
    /**
     * 创建交易
     * 
     * @param reqDTO
     * @return
     */
    public TransactionResDTO createTransaction(CreateTransactionReqDTO reqDTO) {
        log.info("EllipalDataCenterService.createTransaction reqDTO = {}", JSON.toJSONString(reqDTO));

        if (!SystemStatusUtil.systemAvailable()) {
            log.warn("当前ellipal兑换服务不可用");
            return null;
        }
        // 创建交易的具体实现
        return exchangeOrderService.createTransaction(reqDTO);
    }
```



# 2. createTransaction创建交易的具体实现

```java

    /**
     * 创建交易的具体实现。
     * 
     * 该方法接收一个创建交易请求的数据传输对象，并返回交易结果数据传输对象。
     * 1. 创建交易结果数据传输对象
     * 2. 检查交易请求是否满足交易条件(验证交易订单的金额是否符合步长要求，是否存在待处理的订单以及资产池是否有足够的余额)
     * 3. 将请求数据传输对象转换为内部交易订单实体, 设置交易订单的其他属性
     * 4. 保存交易订单
     * 5. 填充交易结果数据响应对象
     *
     * @param reqDTO 创建交易请求的数据传输对象。
     * @return 交易结果数据传输对象。
     */
    @Override
    public TransactionResDTO createTransaction(CreateTransactionReqDTO reqDTO) {
        // 1. 创建交易结果数据传输对象
        TransactionResDTO resDTO = new TransactionResDTO();

        // 2. 检查交易请求是否满足交易条件
        // 验证交易订单的金额是否符合步长要求，是否存在待处理的订单以及资产池是否有足够的余额
        // 如果交易所对冲的资金不足,需要转账补充资金到交易所
        if (!checkOrder(reqDTO, networkConfigIn.getFutureAmountStep(), networkConfigIn.getAmountStep())) {
            // 如果不满足条件，则设置交易状态为 NOT_ACCEPT=未接受，并返回
            resDTO.setTxStatus(EllipalTransactionStatusEnum.NOT_ACCEPT.getCode());
            return resDTO;
        }

        // 3. 将请求数据传输对象转换为内部交易订单实体, 设置交易订单的其他属性
        InternalExchangeOrder entity = InternalExchangeOrderConverter.convertDTOToEntity(reqDTO);
        // 设置交易订单的创建时间
        entity.setCreateTime(DateUtil.date());
        // 生成交易订单ID
        entity.setOrderId(generateOrderId());
        entity.setUsualLPrice(symbolPrice); // 兑出价格（USDT）
        entity.setUsualRPrice(currencyTaskScheduler.getCurrencyUSDInfo(reqDTO.getRName())); // 兑入价格（USDT）
        entity.setProfitRate(strategyConfig.getValue()); // 公司收费比例
        entity.setPlatformReceiveAddress(networkConfigIn.getWalletAddress()); // 公司兑出钱包地址
        entity.setToUserAddress(reqDTO.getToUserAddress()); // 设置交易订单的接收用户地址
        // 设置交易订单的状态为等待付款 -> WAITING_PAYMENT:最开始的状态(收到交易待付款)
        entity.setStatus(EllipalTransactionStatusEnum.WAITING_PAYMENT.getCode());
        // 设置交易订单的过期时间
        entity.setExpireTime(DateUtil.offsetHour(new Date(), networkConfigIn.getExpireTime()));
        entity.setPlatformOutAddress(networkConfigOut.getWalletAddress()); // 公司兑入钱包地址

        // 4. 保存交易订单
        save(entity);

        // 5. 填充交易结果数据响应对象
        resDTO.setCreateTime(entity.getCreateTime()); // 时间
        resDTO.setOrderId(entity.getOrderId()); // 交易订单ID

        return resDTO;
    }

```



# 2.1 checkOrder检查交易请求是否满足交易条件

1. **验证交易金额是否符合步长要求**

2. **获取支持的币对详细配置**

3. **检查交易金额是否在允许的范围内**

4. **查询待处理的订单**

5. **获取钱包余额信息并计算待处理订单总量**

6. **检查资产池余额是否足够**

   

```java
    /**
     * 检查交易订单是否符合交易条件。
     * 
     * 此方法用于验证交易订单的金额是否符合步长要求，并且检查是否存在待处理的订单以及资产池是否有足够的余额。
     * 1. 验证交易金额是否符合步长要求 -> 比如步长是0.01, 不能出现0.009、0.015这种转账金额
     * 2. 获取支持的币对详细配置 -> 币的名称、网络、合约等
     * 3. 检查交易金额是否在允许的范围内
     * 4. 查询符合条件的待处理订单列表 -> 检查是否已经存在待处理的订单(已经收到钱, 还没有开始换)
     * 5. 获取钱包余额信息 -> 返回指定网络的所有币种余额的映射表。
     * 6. 检查资产池是否不足，并在不足时触发资产补充任务。
     *
     * @param reqDTO         创建交易请求的数据传输对象。
     * @param futureStepSize 未来步长大小。
     * @param spotStepSize   现货步长大小。
     * @return 如果订单符合条件返回true，否则返回false。
     */
    private Boolean checkOrder(CreateTransactionReqDTO reqDTO, Integer futureStepSize, Integer spotStepSize) {
            // 1. 验证交易金额是否符合步长要求 -> 比如步长是0.01, 不能出现0.009、0.015这种转账金额
            if (!MathUtils.checkAmount(reqDTO.getFromAmount(), futureStepSize) ||
                    !MathUtils.checkAmount(reqDTO.getFromAmount(), spotStepSize)) {
                return Boolean.FALSE;
            }

            // 2. 获取支持的币对详细配置 -> 币的名称、网络、合约等
            PairInfoResDTO pairDetailConfig = pairConfigService.getSupportPairDetailConfig(configReqDTO);

            // 3. 检查交易金额是否在允许的范围内
            if (pairDetailConfig.getMaxAmount().compareTo(new BigDecimal(-1)) == 0) {
                // 如果 maxAmount 设置为 -1，则表示没有设置最大金额限制
                // 那么只需要检查 fromAmount 交易金额是否大于或等于 minAmount 最小金额限制
                if (pairDetailConfig.getMinAmount().compareTo(reqDTO.getFromAmount()) > 0) {
                    return Boolean.FALSE;
                }
            } 

            // 4. 查询符合条件的待处理订单列表 -> 检查是否已经存在待处理的订单(已经收到钱, 还没有开始换)
            List<InternalExchangeOrder> pendingOrderList = getTransactionListByConditions(condition);

            // 5. 获取钱包余额信息 -> 返回指定网络的所有币种余额的映射表。
            Map<String, BigDecimal> walletBalanceMap = ellipalWalletService.getWalletBalance(
                    reqDTO.getRName(),
                    reqDTO.getRNetwork(),
                    reqDTO.getRContractAddress());

            // 计算获取 -> 兑入数量(扣除费用后)
            BigDecimal transferAmount = currencyTaskScheduler.getExchangePairAmount(pairInfoReqDTO, true);

            // 计算待处理订单总量
            // 如果存在已经收到钱, 但还没有开始换, 可以汇总所有未处理的, 一次性打给交易所, 省gas费
            BigDecimal pendingVolume = BigDecimal.ZERO;
            Optional<BigDecimal> pendingVolumeOptional = pendingOrderList.stream()
                    .map(InternalExchangeOrder::getActualToAmount) // 实际转出数量
                    .reduce(BigDecimal::add); // 汇总

            // 6. 检查资产池是否不足，并在不足时触发资产补充任务。
            // 此方法用于检查资产池的余额是否低于 初始数量与预警线（比例）的乘积。
            // 如果余额不足，则记录警告日志，并在系统允许对冲的情况下，执行资产补充任务。
            if (assetVolume.compareTo(networkConfig.getInitVolume().multiply(networkConfig.getWarningLevel())) < 0) {
                // 如果系统允许对冲操作
                if (SystemStatusUtil.isAllowHedging()) {
                    // 更新对冲的时间戳
                    SystemStatusUtil.updateHedgeTimestamp();
                    // 执行资产补充任务
                    taskPoolExecutor.executeRunnableTask(new HedgingRechargeTask(
                            ellipalHedgingConfig,
                            TransferTriggerTypeEnum.COIN_POOL_LACK.getCode(),
                            networkConfigService.getFullNetworkConfigs(),
                            hedgeOrderService));
                }
                // 返回 false 表示资产池不足, 返回等待下一次调用
                return Boolean.FALSE;
            }

            // 如果所有检查都通过，则返回true
            return Boolean.TRUE;
    }
```

# 2.1.1 HedgingRechargeTask将币充值到交易所

1. **获取币种当前的余额**
2. **获取未完成的对冲订单**
3. **计算所有未完成对冲订单的总交易量**
4. **根据提供的网络类型来确定应使用的自有兑换转账处理器名称**
5. **从 Spring 容器中获取转账处理器实例**
6. **构建转账信息请求并执行转账操作**
7. **批量更新对冲订单的状态为已对冲充值**
```java
    /**
     * 执行对冲平衡任务。
     * 此方法用于实现对冲平衡的第一步，即将资金池中多余的币充值到交易所。
     *
     * 1. 获取币种当前的余额
     * 2. 获取未完成的对冲订单
     * 3. 计算所有未完成对冲订单的总交易量
     * 4. 根据提供的网络类型来确定应使用的自有兑换转账处理器名称
     * 5. 从 Spring 容器中获取转账处理器实例
     * 6. 构建转账信息请求并执行转账操作
     * 7. 批量更新对冲订单的状态为已对冲充值
     */
    @Override
    public void run() {
        // 1. 获取币种当前的余额
        BigDecimal curBalance = balanceMap.get(balanceKey);
        
        // 2.获取未完成的对冲订单
        List<InternalHedgeOrder> hedgeOrders = hedgeOrderService.getOpenHedgeOrders(
            currentConfig.getName(), // 名称
            currentConfig.getNetwork(), // 网络
            currentConfig.getContractAddress(), // 合约
            HedgeOrderStatusEnum.OPENED.getCode(), // 状态 = "OPENED"(已开单)
            HedgeOrderTypeEnum.FUTURE.getCode()); // 订单类型 = "FUTURE"(期货)

        // 3. 计算所有未完成对冲订单的总交易量
        for (InternalHedgeOrder order : hedgeOrders) {
            totalVolume = totalVolume.add(order.getActualTradeVolume());
        }

        // 4. 此方法根据提供的网络类型来确定应使用的转账处理器名称。
        String processorName = TransferProcessorEnum.getProcessorName(
            currentConfig.getName(),
            currentConfig.getNetwork(),
            currentConfig.getContractAddress());

        // 5. 从 Spring 容器中获取转账处理器实例
        TransferExecutor transferExecutor = (TransferExecutor) ApplicationContextHolder
            .getBeanByName(processorName);

        // 6. 构建转账信息请求并 执行转账
        TransferInfoResDTO response = transferExecutor.doExecute(buildTransferInfoReq(
            totalVolume, // 所有未完成对冲订单的总交易量
            currentConfig, // 币池配置
            triggerType)); // 定期、币池缺币、到达保证金预警状态

        // 7. 批量更新对冲订单的状态
        hedgeOrderService.updateBatchById(hedgeOrders);
    }
```

# 2.1.2 doExecute构建转账信息请求并 执行转账



```java
   /**
     * 执行转账操作。
     *
     * 此方法负责执行转账流程，包括构建转账记录、查询签名结果、发送请求、签名交易以及最终发送交易。
     * 1.发送转账请求
     * 2.签名交易。
     * 3.转账
     *
     * @param req 转账信息请求对象
     * @return 转账信息响应对象
     */
    public TransferInfoResDTO doExecute(TransferInfoReqDTO req) {
        // 构建转账请求参数: 这是一个多态的方法, 由自己的实例重新实现(例如: ETHTransferProcessor)
        reqDTO = buildTransferReqParam(req, AbstractTransferProcessor.TransferHttpType.REQ, null, null, null);

        // 1.发送转账请求
        reqRespDTO = sendTransaction(reqDTO, transferConstantConfig.getReqURL());

        // 构建签名请求对象。
        SignTransactionReqDTO signTransactionReq = buildSignReq(req, reqRespDTO.getData());
        // 2.签名交易。
        BaseRespDTO<TransferSignRespDTO> signResponse = signTransaction(signTransactionReq);

        // 签名结果
        signResult = signResponse.getData();

        // 将签名结果存储到 MongoDB 中
        eSigResult = new ESigResult();
        mongoTemplate.insert(eSigResult);

        // 构建转账请求参数: 这是一个多态的方法, 由自己的实例重新实现(例如: ETHTransferProcessor)
        TransferReqDTO sendDTO = buildTransferReqParam(req, AbstractTransferProcessor.TransferHttpType.SEND,signResult, reqDTO.getAgency(),reqRespDTO.getData());
        // 3.转账
        BaseRespDTO<TransferRespDTO> sendRespDTO = sendTransaction(sendDTO, transferConstantConfig.getSendURL());

        TransferRespDTO sendTransaction = sendRespDTO.getData();
        String hash = getHash(sendTransaction); // 转账 hash -> 就是TxId
        transferRecord.setTxHash(hash); // 记录转账 hash

        response.setStatus(Boolean.TRUE); // 转账成功
        response.setTxHash(hash); // 返回转账 hash

        transferRecord.setCreateTime(DateUtil.date()); // 设置创建时间
        saveTransRecord(transferRecord); // 保存/更新转账记录
    }
```





# 2.2.2 sendTransaction发送转账请求

```java
    /**
     * 发送转账请求（req 或 send）。
     *
     * 该方法用于向指定的 URL 发送转账请求，并解析返回的 JSON 字符串为 `BaseRespDTO<TransferRespDTO>` 对象。
     *
     * @param reqDTO 转账请求参数对象。
     * @param reqURL 发送请求的目标 URL。
     * @return 包含转账响应信息的 `BaseRespDTO<TransferRespDTO>` 对象。
     */
    default BaseRespDTO<TransferRespDTO> sendTransaction(TransferReqDTO reqDTO, String reqURL) {
        // 将 TransferReqDTO 对象转换为 Map 对象
        Map<String, Object> paramMap = JSON.parseObject(JSON.toJSONString(reqDTO), Map.class);
        // 使用 RemoteClient 发起 POST 请求，并获取返回的 JSON 字符串
        String jsonStr = RemoteClient.postForString(reqURL, paramMap, null);

        // 返回解析后的响应对象
        return respDTO;
    }
```



# 2.2.3 signTransaction签名

```java

    /**
     * 签名交易。
     *
     * 该方法用于处理交易签名请求，并返回签名结果。
     *
     * @param request 签名请求对象，包含签名所需的全部信息。
     * @return 包含签名结果的响应对象。
     */
    @Override
    public BaseRespDTO<TransferSignRespDTO> signTransaction(SignTransactionReqDTO request) {
        // 初始化签名状态为失败
        signResponse.setStatus(Boolean.FALSE);
        // 方法用于处理与签名相关的事件，通过WebSocket会话发送签名请求，并等待签名结果。
        SignTransactionResDTO signTransactionResDTO = WSEventProcessor.processSignEvent(
            EventTopicEnum.SIGN_TOPIC,
            request);

        // 如果签名成功，更新签名状态为成功
        signResponse.setStatus(Boolean.TRUE);
        // 将签名结果转换为 TransferSignRespDTO 对象并设置到响应中
        signResponse.setData(CoinSystemUtils.signDataConvert(signTransactionResDTO));

        // 返回最终的签名响应对象
        return signResponse;
    }
```

- 处理与签名相关的事件

```java
    /**
     * 处理签名事件。
     *
     * 该方法用于处理与签名相关的事件，通过WebSocket会话发送签名请求，并等待签名结果。
     *
     * @param event   事件主题枚举，此处应为 SIGN_TOPIC。
     * @param request 签名请求对象，包含签名所需的全部信息。
     * @return 包含签名结果的响应对象。
     * @throws IOException 如果发生IO错误。
     */
    public static SignTransactionResDTO processSignEvent(EventTopicEnum event, SignTransactionReqDTO request)
            throws IOException {
        // 1. 检查事件是否为签名事件
        if (event == EventTopicEnum.SIGN_TOPIC) {
            // 2. 选择一个WebSocket会话通道
            ChannelHolder channelHolder = selectSignChannelHolder();
            try {
                // 3. 获取特定主题的WebSocket会话缓存
                ConcurrentHashMap<String, WebSocketSession> sessionCacheMap = topicSessionCache
                        .get(EventTopicEnum.SIGN_TOPIC);
                // 4. 根据通道持有者的通道ID获取WebSocket会话
                WebSocketSession webSocketSession = sessionCacheMap.get(channelHolder.channelID);

                // 5. 检查WebSocket会话是否有效
                if (webSocketSession == null || webSocketSession.getRemoteAddress() == null) {
                    log.info("==processSignEvent throw channelHolder:{},webSocketSession:{}==", channelHolder,
                            webSocketSession);
                    throw new RuntimeException("webSocketSession is null");
                }

                // 6. 记录选定的通道地址
                log.info("selected channel addr : {}", webSocketSession.getRemoteAddress().getHostString());

                // 7. 在发送签名请求之前转换网络信息
                request.setNetwork(CoinSystemUtils.signNetworkConvert(request.getNetwork()));
                // 8. 发送签名请求到WebSocket会话
                webSocketSession.sendMessage(new TextMessage(JSON.toJSONString(request)));

                // 9. 短暂挂起当前线程以等待响应
                LockSupport.parkNanos(1000000000L * 2);

                log.info("==wss attributes:{}==", JSON.toJSONString(webSocketSession.getAttributes()));

                // 10. 获取WebSocket会话属性中的响应数据
                String data = (String) webSocketSession.getAttributes().get(EventTopicEnum.SIGN_TOPIC.getTopic());
                // 11. 清除WebSocket会话属性中的响应数据
                webSocketSession.getAttributes().remove(EventTopicEnum.SIGN_TOPIC.getTopic());

                log.info("==wss sign response:{}==", data);

                // 12. 解析签名响应数据为SignTransactionResDTO对象
                resp = JSON.parseObject(data, SignTransactionResDTO.class);

                // 返回签名结果
                return resp;
            } catch (Exception e) {
                log.error("sign meet err : ", e);
            } finally {
                if (channelHolder != null) {
                    channelHolderQueue.add(channelHolder);
                }
            }
        }

        // 如果不是签名事件，则返回默认的签名响应对象
        return resp;
    }
```



# 2.2.4 sendTransaction转账

```java
    /**
     * 发送转账请求（req 或 send）。
     *
     * 该方法用于向指定的 URL 发送转账请求，并解析返回的 JSON 字符串为 `BaseRespDTO<TransferRespDTO>` 对象。
     *
     * @param reqDTO 转账请求参数对象。
     * @param reqURL 发送请求的目标 URL。
     * @return 包含转账响应信息的 `BaseRespDTO<TransferRespDTO>` 对象。
     */
    default BaseRespDTO<TransferRespDTO> sendTransaction(TransferReqDTO reqDTO, String reqURL) {
        // 将 TransferReqDTO 对象转换为 Map 对象
        Map<String, Object> paramMap = JSON.parseObject(JSON.toJSONString(reqDTO), Map.class);
        // 使用 RemoteClient 发起 POST 请求，并获取返回的 JSON 字符串
        String jsonStr = RemoteClient.postForString(reqURL, paramMap, null);

        // 将返回的 JSON 字符串解析为 BaseRespDTO<TransferRespDTO> 对象
        BaseRespDTO<TransferRespDTO> respDTO = JSONObject.parseObject(jsonStr,
                new TypeReference<BaseRespDTO<TransferRespDTO>>() {
                });

        // 返回解析后的响应对象
        return respDTO;
    }
```



# 3. 设置交易订单的其他属性并保存

```java
        // 3. 将请求数据传输对象转换为内部交易订单实体, 设置交易订单的其他属性

        // 获取交易货币的美元价格
        BigDecimal symbolPrice = currencyTaskScheduler.getCurrencyUSDInfo(reqDTO.getLName());

        entity.setUsualLPrice(symbolPrice); // 兑出价格（USDT）
        entity.setUsualRPrice(currencyTaskScheduler.getCurrencyUSDInfo(reqDTO.getRName())); // 兑入价格（USDT）

        entity.setProfitRate(strategyConfig.getValue()); // 公司收费比例
        entity.setPlatformReceiveAddress(networkConfigIn.getWalletAddress()); // 接收地址(公司)
        entity.setToUserAddress(reqDTO.getToUserAddress()); // 设置交易订单的接收用户地址

        // 设置交易订单的状态为等待付款 -> WAITING_PAYMENT:最开始的状态(收到交易待付款)
        entity.setStatus(EllipalTransactionStatusEnum.WAITING_PAYMENT.getCode());
        // 设置交易订单的过期时间
        entity.setExpireTime(DateUtil.offsetHour(new Date(), networkConfigIn.getExpireTime()));

        entity.setPlatformOutAddress(networkConfigOut.getWalletAddress()); // 转出地址(公司)

        // 4. 保存交易订单
        save(entity);
```

# 4. 填充交易结果数据响应对象

```java
        // 5. 填充交易结果数据响应对象
        resDTO.setTag(networkConfigIn.getTag() == null ? "" : String.valueOf(networkConfigIn.getTag()));
        resDTO.setCreateTime(entity.getCreateTime()); // 时间
        resDTO.setOrderId(entity.getOrderId()); // 交易订单ID
        resDTO.setPlatformReceiveAddress(entity.getPlatformReceiveAddress()); // 接收地址(公司)
        resDTO.setProfitRate(entity.getProfitRate()); // 公司收费比例

        // 设置交易订单的状态为等待付款 -> WAITING_PAYMENT:最开始的状态(收到交易待付款)
        resDTO.setTxStatus(entity.getStatus());

```

