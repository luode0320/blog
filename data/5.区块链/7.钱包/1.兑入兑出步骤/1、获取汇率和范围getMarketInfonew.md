# 获取汇率和范围getMarketInfonew

```java
    @GetMapping(value = "getMarketInfonew")
    public String getMarketInfoNew(@RequestParam(value = "pair") String pair,
                                   @RequestParam(value = "amountFrom", required = false) BigDecimal amountFrom,
                                   @RequestParam(value = "amountTo", required = false) BigDecimal amountTo,
                                   @RequestParam(value = "lastRate", required = false) BigDecimal lastRate) {
```



# getPairInfo

```java
    @PostMapping(value = "getPairInfo", consumes = "application/json")
    // @HystrixCommand(groupKey = "data", fallbackMethod = "getPairInfoFB")
    public EPairInfo getPairInfo(@RequestBody EPairRequest pairRequest) {
        log.info("获取汇率和范围:{} 入口参数: {}", composePair(pairRequest.getFrom(), pairRequest.getTo()), pairRequest);
        return buildPairInfo(pairRequest);
    }
```

