# 下单exchangenew

```java
    /**
     * 创建兑换订单的处理方法。
     */
    // @Resubmit(ttl = 30)
    @GetMapping(value = "exchangenew")
    public String createOrder(HttpServletRequest httpRequest, @RequestParam Map<String, Object> params) {
```



```
2024-10-24 14:05:52.469  INFO 875837 [http-nio-5011-exec-26] c.e.c.portal.interceptor.JwtInterceptor  : ===new request: [119.8.185.250] -> http://cloudtest.ellipal.com/api/exchangenew
2024-10-24 14:05:52.469  INFO 875837 [http-nio-5011-exec-26] c.e.c.portal.interceptor.JwtInterceptor  : new request accept? false, token verify failed
2024-10-24 14:05:52.469  INFO 875837 [http-nio-5011-exec-26] c.e.crypto.portal.exchange.LegacyClient  : params:{pair=SOL_DOGE, amount=0.18, fromAddr=Ey4cy88yzRbNU5ebjG4fFvEJ9EgbZYgjsQs6jdM2HbW6, receiptAddr=DSqUjtHooVdf3yXeEFcq1wiX5SVmm1wZts, volumeUser=218.473590, rateUser=1213.74216794, fromType=SOL, toType=DOGE, refundType=1, pubkey=cf848c741d1989c0f779851b9ecbd6fdf9084d1382ed4da19163185dfc4fe46f, gplatform=iOS, balance=0.429185616}
2024-10-24 14:05:52.469  INFO 875837 [http-nio-5011-exec-26] c.e.c.portal.exchange.ExchangeClient     : findBaseCurrency request = {"name":"SOL","network":"SOL"}
2024-10-24 14:05:52.469  INFO 875837 [http-nio-5011-exec-26] c.e.c.portal.exchange.ExchangeClient     : findBaseCurrency request = {"name":"DOGE","network":"DOGE"}
2024-10-24 14:05:52.572  INFO 875837 [http-nio-5011-exec-26] c.e.crypto.portal.exchange.LegacyClient  : gasFee 0.000001
2024-10-24 14:05:52.572  INFO 875837 [http-nio-5011-exec-26] c.e.crypto.portal.exchange.LegacyClient  : isMain true
2024-10-24 14:05:52.572  INFO 875837 [http-nio-5011-exec-26] c.e.crypto.portal.exchange.LegacyClient  : totalcost   0.180001
2024-10-24 14:05:52.572  INFO 875837 [http-nio-5011-exec-26] c.e.crypto.portal.exchange.LegacyClient  : unitFee 0.000001
2024-10-24 14:05:52.572  INFO 875837 [http-nio-5011-exec-26] c.e.crypto.portal.exchange.LegacyClient  : createOrder originAmount = 0.18, totalgas = 0.180001,unitFee = 0.000001 ,actualAmount = 0.18,reserve = 0.00089
2024-10-24 14:05:52.572  INFO 875837 [http-nio-5011-exec-26] c.e.c.portal.exchange.ExchangeClient     : new order request: ETransactionRequest(requestId=null, from=ECurrency{network='SOL', contractAddress='', name='SOL'}, to=ECurrency{network='DOGE', contractAddress='', name='DOGE'}, gasFee=null, fromAmount=0.18, originalFromAmount=null, toAmount=218.473590, toAddress=DSqUjtHooVdf3yXeEFcq1wiX5SVmm1wZts, extraId=null, fromAddress=Ey4cy88yzRbNU5ebjG4fFvEJ9EgbZYgjsQs6jdM2HbW6, refundExtraId=null, userId=null, payload=null, sessionId=119.8.185.250, deviceId=null, exchange=null, commission=null, exRate=1213.74216794, usdVal=null, strategy=null, pubKey=cf848c741d1989c0f779851b9ecbd6fdf9084d1382ed4da19163185dfc4fe46f, timeTs=1729749952469, gplatForm=iOS)
2024-10-24 14:05:52.573  INFO 875837 [http-nio-5011-exec-26] c.e.c.portal.exchange.ExchangeClient     : user req pair by from=ECurrency{network='SOL', contractAddress='', name='SOL'}, to=ECurrency{network='DOGE', contractAddress='', name='DOGE'}
2024-10-24 14:05:53.191  INFO 875837 [http-nio-5011-exec-26] c.e.c.portal.exchange.ExchangeClient     :   -- pair info: EPairInfo(from=ECurrency{network='SOL', contractAddress='', name='SOL'}, to=ECurrency{network='DOGE', contractAddress='', name='DOGE'}, rate=1213.70441444, gas=0, minAmount=0.17353200, maxAmount=1205.9253, usdPrice=165.84775520854114, exchangeList=[Changelly, EllipalExchange], timeMs=1729749953188)
2024-10-24 14:05:53.364  INFO 875837 [http-nio-5011-exec-26] c.e.c.portal.exchange.ExchangeClient     : new order result: ETransactionResult(exchange=EllipalExchange, status=ACCEPTED, message=, requestId=ewtncabed6b992b24901adcec319e3fa889a, orderChannel=1, exchangeFlag=1, details=EllipalExchange:; , pair=SOL_DOGE, transaction=ETransaction(orderId=EPLA1FF55C26DAE4184B6888AB03B38F37E, fromAddress=Ey4cy88yzRbNU5ebjG4fFvEJ9EgbZYgjsQs6jdM2HbW6, toAddress=DSqUjtHooVdf3yXeEFcq1wiX5SVmm1wZts, amount=0.18, volume=null, gasFee=10000.0, exchangeFee=0.0450, payInAddress=8KqVjppirTCfqmztoYg12oxLMZcwUHFwaY62FeeZq3Rg, payInExtraId=, note=null, timeMs=1729749953338), timeMs=1729749953338, createTime=1729749953363, successTimeSpan=0)
2024-10-24 14:05:53.364  INFO 875837 [http-nio-5011-exec-26] c.e.crypto.portal.exchange.LegacyClient  : legacy order result: {"msg":"success","status":true,"data":{"realGasFee":"0.000001","toAddr":"8KqVjppirTCfqmztoYg12oxLMZcwUHFwaY62FeeZq3Rg","amount":"0.18","orderID":"ewtncabed6b992b24901adcec319e3fa889a","gas":"10000.0","payInExtraId":""}}
```

