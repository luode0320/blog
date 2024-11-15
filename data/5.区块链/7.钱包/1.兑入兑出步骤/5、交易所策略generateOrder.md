# generateOrder

```java
    /**
     * 处理生成订单的POST请求。
     *
     * @param request 包含订单请求信息的对象。
     * @return 返回订单处理的结果。
     */
    @PostMapping(value = "generateOrder")
    public ETransactionResult generateOrder(@RequestBody ETransactionRequest request) {
//        if (null != request) {
//            ExecutionStrategy strategy = ExecutionStrategy.valueOf(currentStrategy);
//            request.setStrategy(strategy.name());
////            dispatcher.dispatch(request.getRequestId(), () -> brainMap.getBrain(strategy).processOrder(request));
//            log.info("user order queue: session={}, request={}", request.getSessionId(), request);
//            return brainMap.getBrain(strategy).processOrder(request);
//        } else {
//            log.warn("no available data: {}", record.value());
//        }
        // 记录新的订单请求信息
        log.info("new order request: {}", request);
        // 根据当前策略配置获取执行策略:中间汇率/最高汇率
        ExecutionStrategy strategy = ExecutionStrategy.valueOf(strategyConfig.getCurrentStrategy());
        // 设置请求中的策略字段
        request.setStrategy(strategy.name());
        // 根据汇率策略获取相应的处理对象，并处理订单请求
        return brainFactory.getBrain(strategy).processOrder(request);
    }
```

