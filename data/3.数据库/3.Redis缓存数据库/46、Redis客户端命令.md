# 查询

```sh
redis-cli -p 6379 GET "income_info_week:2022-28" | jq
redis-cli -p 6379 GET "EllipalNodeSync:ContractList" > ContractList.txt | jq
redis-cli -p 6379 GET "allcurrencyInfobuy" | jq
redis-cli -p 6379 GET "income_info_date:2024-12-25" | jq
redis-cli -p 6379 GET "income_info_week:2022-28" 
redis-cli -p 6379 GET "income_info_date" 
redis-cli -p 6379 GET "EllipalNodeSync:ContractList" > ContractList.txt  
redis-cli -p 6379 GET "token_prices_redis_key"  > prices.txt 
redis-cli -p 6379 GET "CoinsAllowOrderCYnewChangenowOnly" # 获取swif兑换支持的币种 单向支持
```



# 删除

```sh
redis-cli -p 6379 DEL "income_info_week:2022-28"
redis-cli -p 6379 DEL "income_info_date:2024-12-25"
```



# 删除多个

```sh
# 查询多个
redis-cli -p 6379 KEYS "income_info_week:*"

# 使用 xargs 或循环逐一删除这些键
redis-cli -p 6379 KEYS "income_info_week:*" | xargs redis-cli -p 6379 DEL

# 再次查询
redis-cli -p 6379 KEYS "income_info_week:*"
```



# 新增

```sh
redis-cli -p 6379 SET allcurrencyInfobuy "<modified JSON>"
```



# 检测redis是否启动

```sh
# 1
service redis status
# 2
systemctl status redis
# 3
ps aux | grep redis-server
[root@ecs-wallet-test ~]# ps aux | grep redis-server
root      9115  0.0  0.0  69756  8320 ?        Sl   11:10   0:00 redis-server 127.0.0.1:6379
```

