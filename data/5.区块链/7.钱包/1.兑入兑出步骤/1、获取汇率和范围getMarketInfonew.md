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



# range

```java
    @PostMapping(value = "/range")
    public EAmountRange getRangeAmount(@RequestBody EPairRequest request) {
```



# 获取币价

```java
    @GetMapping(value = "getCoinUsdVal")
    public String getCoinUsdVal(@RequestParam(name = "name") String name,
                                @RequestParam(name = "fullName") String fullName,
                                @RequestParam(name = "contractAddr") String contractAddr) {
        try {
            log.info("获取币种usd价格: name = {}, fullName = {}, contractAddr: {}", name, fullName, contractAddr);
            return getCoinsValue(name, fullName, contractAddr);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return "0";
    }
```

