# 自动生成时间和更新时间

```sql
CREATE TABLE `exchange_cancel_coins` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `exchangeName` varchar(200) NOT NULL DEFAULT '' COMMENT '交易所名称(必填)',
  `name` varchar(200) DEFAULT NULL COMMENT '币全名',
  `cType` varchar(100) NOT NULL DEFAULT '' COMMENT '网络类型(必填)',
  `shortName` varchar(200) NOT NULL DEFAULT '' COMMENT '币名简称(必填)',
  `contractAddr` varchar(200) NOT NULL DEFAULT '' COMMENT '合约地址(必填)',
  `status` tinyint(3) DEFAULT '0' COMMENT '状态: 0=双向禁止 1=正常兑换 2=只允许兑出 3=只允许兑入',
  `createTime` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updateTime` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_exchangeName` (`exchangeName`) USING BTREE COMMENT '交易所名称索引'
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC COMMENT='交易所下架兑换币种';
```

