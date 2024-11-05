# 获取gas费getGasFee

```java
    /**
     * 获取指定网络的Gas费用。
     *
     * 此方法用于根据请求参数计算并返回Gas费用。
     * 支持不同的网络类型，并考虑了特殊情况下Gas费用的转换。
     *
     * 参数：
     * 
     * @param network      网络类型（如：ETH、BTC等）。
     * @param fromAddr     发起交易的地址。
     * @param toAddr       接受交易的地址。
     * @param amount       交易金额。
     * @param isRealGas    是否使用真实Gas费用，默认为0（不使用）。
     * @param contractAddr 合约地址，默认为空。
     * @param shortName    短名，默认可选。
     *
     *                     步骤：
     *                     1. 日志记录请求参数中的网络类型。
     *                     2. 处理短名参数，确保其非空。
     *                     3. 通过REST模板获取Gas费用。
     *                     4. 调整Gas费用，根据网络类型转换其数值大小。
     *                     5. 计算保留金（reserve），根据不同的网络类型。
     *                     6. 将计算结果封装进响应对象并返回。
     *
     * @return 包含Gas费用和保留金信息的JSON字符串。
     */
    @LoadBalanced
    @GetMapping(value = "getGasFee")
    public String getGasFee(@RequestParam(value = "cType") String network,
            @RequestParam(value = "fromAddr") String fromAddr,
            @RequestParam(value = "shortName", required = false) String shortName,
            @RequestParam(value = "toAddr") String toAddr,
            @RequestParam(value = "amount") String amount,
            @RequestParam(value = "realGas", defaultValue = "0") int isRealGas,
            @RequestParam(value = "contractAddr", defaultValue = "") String contractAddr) {
        log.info("getGasFee: network={}", network);

        // 步骤 2: 处理短名参数，确保其非空
        if (StringUtil.isNullOrEmpty(shortName)) {
            shortName = "";
        }

        // 步骤 3: 通过REST模板获取Gas费用
        BigDecimal gasFee = restTemplate.getForObject(
                MODULE_URL_DATA + "getGasFee" + "?network={network}"
                        + "&fromAddr={fromAddr}" + "&toAddr={toAddr}"
                        + "&amount={amount}&contractAddr={contractAddr}&realGas=1",
                BigDecimal.class,
                shortName.equalsIgnoreCase("USDT") && network.equalsIgnoreCase("BTC") ? "USDT" : network,
                fromAddr,
                toAddr,
                amount,
                contractAddr);

        assert gasFee != null;

        // 步骤 4: 调整Gas费用，根据网络类型转换其数值大小
        // 这个列表包含了不需要进行数值转换的网络名称。意味着对于VeChain网络，Gas费用将不会被转换
        List<String> bigArray = Arrays.asList("VET");
        // 检查获取到的Gas费用是否大于1
        // 当前处理的网络是否不在bigArray列表中
        if (gasFee.compareTo(BigDecimal.ONE) > 0 && !bigArray.contains(network)) {
            // Math.pow(10d,WeiUtil.getWeiPow(network))：该方法返回一个整数，代表了需要除以的10的幂次数。
            // 例如，在以太坊（ETH）网络中，1ETH = 10^18 Wei
            // 因此如果 WeiUtil.getWeiPow("ETH") 返回18，那么 gasFee 费用将被除以10的18次方。
            gasFee = BigDecimal.valueOf(gasFee.doubleValue() / Math.pow(10d, WeiUtil.getWeiPow(network)))
                    .setScale(6, RoundingMode.UP); // 6位小数的精度,向上舍入
        }

        // 步骤 5: 计算保留金（reserve），根据不同的网络类型, 写死保留金额
        BigDecimal reserve = new BigDecimal("0");
        switch (network) {
            case "XRP" -> reserve = new BigDecimal("14");
            case "XLM" -> reserve = new BigDecimal("1");
            case "SOL" -> reserve = new BigDecimal("0.00089");
            case "ALGO" -> reserve = new BigDecimal("0.3");
        }

        // 创建返回值Map
        Map<String, String> returnval = new HashMap<>();
        BigDecimal unitFee;
        unitFee = gasFee.multiply(new BigDecimal("2")); // gas费翻倍
        returnval.put("unitFee", unitFee.toPlainString());

        // 设置保留金
        if (reserve.compareTo(BigDecimal.ZERO) > 0) {
            returnval.put("reserve", reserve.toPlainString());
        }

        // 步骤 6: 将计算结果封装进响应对象并返回
        LResponse<?> response = new LResponse<>("success", true, returnval);
        return gson.toJson(response);
    }
```



```
2024-10-24 14:05:52.187  INFO 875837 [http-nio-5011-exec-6] c.e.c.portal.interceptor.JwtInterceptor  : ===new request: [119.8.185.250] -> http://cloudtest.ellipal.com/api/getGasFee
2024-10-24 14:05:52.187  INFO 875837 [http-nio-5011-exec-6] c.e.c.portal.interceptor.JwtInterceptor  : new request accept? false, token verify failed
2024-10-24 14:05:52.187  INFO 875837 [http-nio-5011-exec-6] c.e.crypto.portal.exchange.LegacyClient  : getGasFee: network=SOL
```



# 通过data模块getGasFee获取gas

```java
    /**
     * 获取指定网络的Gas费用。
     *
     * 此方法用于根据请求参数计算并返回Gas费用。
     * 支持不同的网络类型，并根据网络类型选择合适的计算方法。
     *
     * 参数：
     * 
     * @param network      网络类型（如：ETH、BTC等）。
     * @param fromAddr     发起交易的地址。
     * @param toAddr       接受交易的地址。
     * @param amount       交易金额。
     * @param isRealGas    是否使用真实Gas费用，默认为0（不使用）。
     * @param contractAddr 合约地址，默认为空。
     *
     *                     步骤：
     *                     1. 日志记录请求参数中的网络类型。
     *                     2. 根据网络类型转换为大写形式，并初始化Gas费用为0。
     *                     3. 判断网络类型并调用相应的Gas费用计算方法。
     *
     * @return 计算得到的Gas费用。
     */
    @LoadBalanced
    @GetMapping(value = "getGasFee")
    public BigDecimal getGasFee(@RequestParam(value = "network") String network,
            @RequestParam(value = "fromAddr") String fromAddr,
            @RequestParam(value = "toAddr") String toAddr,
            @RequestParam(value = "amount") String amount,
            @RequestParam(value = "realGas", defaultValue = "0") int isRealGas,
            @RequestParam(value = "contractAddr", defaultValue = "") String contractAddr) {
        log.info("getGasFee: network={}", network);

        // 初始化Gas费用为0
        BigDecimal gas = BigDecimal.ZERO;
        try {
            // 步骤 2: 根据网络类型转换为大写形式
            network = network.toUpperCase();
            // 步骤 3: 判断网络类型并调用相应的Gas费用计算方法
            if (ETH_SYSTEM_COINS.contains(network)) {
                gas = isRealGas == 1 ? getEthRelatedGasFeeRealFee(network, contractAddr) : getEthRelatedGasFee(network);
            } else if (NEW_ETH_SYSTEM_COINS.contains(network)) {
                gas = getNewEthGasFee(network, contractAddr, isRealGas);
            } else if (BTC_SYSTEM_COINS.contains(network)) {
                gas = getBtcRelatedGasFee(network, fromAddr, amount);
            } else if (DOT_SYSTEM_COINS.contains(network)) {
                gas = getDotRelatedGasFee(network);
            } else if (realDefaultGas.containsKey(network) && isRealGas == 1) {
                gas = realDefaultGas.get(network);
            } else {
                gas = defaultGas.get(network) == null ? defaultGasLast.get(network) : defaultGas.get(network);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        log.info("  {} gas: {}", network, gas);
        return gas;
    }
```



