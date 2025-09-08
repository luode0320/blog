# 自动生成时间和更新时间

```sql
CREATE TABLE `exchange_cancel_coins` (
  `id` int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `exchangeName` varchar(200) NOT NULL DEFAULT '' COMMENT '交易所名称(必填)',
  `name` varchar(200) DEFAULT NULL COMMENT '币全名',
  `cType` varchar(100) NOT NULL DEFAULT '' COMMENT '网络类型(必填)',
  `shortName` varchar(200) NOT NULL DEFAULT '' COMMENT '币名简称(必填)',
  `contractAddr` varchar(200) NOT NULL DEFAULT '' COMMENT '合约地址(必填)',
  `status` tinyint(3) DEFAULT 1 COMMENT '状态: 1=启用 不等于1=停用',
  `createTime` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updateTime` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  UNIQUE KEY `idx_exchangeName` (`exchangeName`) USING BTREE COMMENT '交易所唯一索引',
  KEY `idx_name` (`name`) USING BTREE COMMENT '名称索引',
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC COMMENT='交易所下架兑换币种';
```



```sql
CREATE TABLE app_fiat (
    id INT AUTO_INCREMENT PRIMARY KEY,
    currency_code VARCHAR(10) NOT NULL UNIQUE COMMENT '货币代码，如 USD, CNY',
    chinese_name VARCHAR(50) NOT NULL COMMENT '中文名称',
    english_name VARCHAR(100) NOT NULL COMMENT '英文名称',
    sign VARCHAR(10) NOT NULL COMMENT '货币符号，如 $, ¥',
    created_at datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    
    UNIQUE KEY `idx_currency_code` (`currency_code`) USING BTREE COMMENT '唯一索引'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='法币信息表';
```

