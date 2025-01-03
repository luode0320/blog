# 查询

```sh
redis-cli -p 6379 GET "income_info_week:2022-28" | jq
redis-cli -p 6379 GET "EllipalNodeSync:ContractList" > ContractList.txt | jq
redis-cli -p 6379 GET "allcurrencyInfobuy" | jq
```



# 删除

```sh
redis-cli -p 6379 DEL "income_info_week:2022-28"
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

