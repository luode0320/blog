# 汇率接口getMarketInfonew

```
2024-10-24 14:00:26.603  INFO 875837 [http-nio-5011-exec-32] c.e.c.portal.interceptor.JwtInterceptor  : ===new request: [119.8.185.250] -> http://cloudtest.ellipal.com/api/getMarketInfonew
2024-10-24 14:00:26.603  INFO 875837 [http-nio-5011-exec-32] c.e.c.portal.interceptor.JwtInterceptor  : new request accept? false, token verify failed
2024-10-24 14:00:26.603  INFO 875837 [http-nio-5011-exec-32] c.e.crypto.portal.exchange.LegacyClient  : getMarketInfoNew pair = SOL_DOGE
2024-10-24 14:00:26.603  INFO 875837 [http-nio-5011-exec-32] c.e.c.portal.exchange.ExchangeClient     : findBaseCurrency request = {"name":"SOL"}
2024-10-24 14:00:26.603  INFO 875837 [http-nio-5011-exec-32] c.e.c.portal.exchange.ExchangeClient     : findBaseCurrency request = {"name":"DOGE"}
2024-10-24 14:00:26.603  INFO 875837 [http-nio-5011-exec-32] c.e.crypto.portal.exchange.LegacyClient  : getMarketInfoNew from = {"contractAddress":"","enabled":true,"fullName":"Solana","gWei":9,"gasLimit":"0","group":"","image":"https://s2.coinmarketcap.com/static/img/coins/64x64/5426.png","name":"SOL","network":"SOL","recently":false},to = {"contractAddress":"","enabled":true,"fullName":"Dogecoin","gWei":8,"gasLimit":"0","group":"","image":"https://s2.coinmarketcap.com/static/img/coins/64x64/74.png","name":"DOGE","network":"DOGE","recently":false}
2024-10-24 14:00:26.603  INFO 875837 [http-nio-5011-exec-32] c.e.c.portal.exchange.ExchangeClient     : user req pair by from=ECurrency{network='SOL', contractAddress='', name='SOL'}, to=ECurrency{network='DOGE', contractAddress='', name='DOGE'}
2024-10-24 14:00:27.094  INFO 875837 [http-nio-5011-exec-32] c.e.c.portal.exchange.ExchangeClient     :   -- pair info: EPairInfo(from=ECurrency{network='SOL', contractAddress='', name='SOL'}, to=ECurrency{network='DOGE', contractAddress='', name='DOGE'}, rate=1213.69098556, gas=0, minAmount=0.17353200, maxAmount=1205.9253, usdPrice=165.84775520854114, exchangeList=[Changelly, EllipalExchange], timeMs=1729749627091)
```

