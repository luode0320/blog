# SQL优化

## 索引最左匹配原则

**最左匹配原则**

在mysql建立联合索引时会遵循最左前缀匹配的原则，即最左优先，在检索数据时从联合索引的最左边开始匹配，示例：对列col1、列col2和列col3建一个联合索引，实际建立了(col1)、(col1,col2)、(col,col2,col3)三个索引，

查询的时候，

1、包含条件 col1；col1,col2；col1,col2,col3 走索引

2、不包含条件 col1，则不走索引

**测试表数据**

```sql
CREATE TABLE `test` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `col1` varchar(50) DEFAULT NULL,
  `col2` varchar(50) DEFAULT NULL,
  `col3` varchar(50) DEFAULT NULL,
  `col4` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `test_Idx` (`col1`,`col2`,`col3`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
 
INSERT INTO test(col1,col2,col3,col4)
VALUES('a1','b1','c1','d1'),
('a2','b2','c2','d2'),
('a3','b3','c3','d3'),
('a4','b4','c4','d4'),
('a5','b5','c5','d5'),
('a6','b6','c6','d6');
```

**索引类型**

type：联接类型。下面给出各种联接类型,按照从最佳类型到最坏类型进行排序:（重点看ref,rang,index）

1.  system：表只有一行记录（等于系统表），这是const类型的特例，平时不会出现，可以忽略不计
2.  const：表示通过索引一次就找到了，const用于比较primary key 或者 unique索引。因为只需匹配一行数据，所有很快。如果将主键置于where列表中，mysql就能将该查询转换为一个const
3. eq_ref：唯一性索引扫描，对于每个索引键，表中只有一条记录与之匹配。常见于主键 或 唯一索引扫描。注意：ALL全表扫描的表记录最少的表如t1表
4. ref：非唯一性索引扫描，返回匹配某个单独值的所有行。本质是也是一种索引访问，它返回所有匹配某个单独值的行，然而他可能会找到多个符合条件的行，所以它应该属于查找和扫描的混合体。
5. range：只检索给定范围的行，使用一个索引来选择行。key列显示使用了那个索引。一般就是在where语句中出现了bettween、<、>、in等的查询。这种索引列上的范围扫描比全索引扫描要好。只需要开始于某个点，结束于另一个点，不用扫描全部索引。
6. index：Full Index Scan，index与ALL区别为index类型只遍历索引树。这通常为ALL块，应为索引文件通常比数据文件小。（Index与ALL虽然都是读全表，但index是从索引中读取，而ALL是从硬盘读取）
7. ALL：Full Table Scan，遍历全表以找到匹配的

**示例1，走索引**

```sql
EXPLAIN SELECT * FROM test WHERE col1 LIKE 'b2%' ;
    id  select_type  table   partitions  type    possible_keys  key       key_len  ref       rows  filtered  Extra                 
------  -----------  ------  ----------  ------  -------------  --------  -------  ------  ------  --------  -----------------------
     1  SIMPLE       test    (NULL)      range   test_Idx       test_Idx  153      (NULL)       1    100.00  Using index condition 
 
 
EXPLAIN SELECT * FROM test WHERE col1 = 'a2' ;
    id  select_type  table   partitions  type    possible_keys  key       key_len  ref       rows  filtered  Extra  
------  -----------  ------  ----------  ------  -------------  --------  -------  ------  ------  --------  --------
     1  SIMPLE       test    (NULL)      ref     test_Idx       test_Idx  153      const        1    100.00  (NULL) 
 
 
EXPLAIN SELECT * FROM test WHERE col1 = 'a2' AND col2 = 'b2';
    id  select_type  table   partitions  type    possible_keys  key       key_len  ref            rows  filtered  Extra  
------  -----------  ------  ----------  ------  -------------  --------  -------  -----------  ------  --------  --------
     1  SIMPLE       test    (NULL)      ref     test_Idx       test_Idx  306      const,const       1    100.00  (NULL) 
                                                                                                                              
 
EXPLAIN SELECT * FROM test WHERE col1 = 'a2' AND col2 = 'b2' AND col3='c2';
    id  select_type  table   partitions  type    possible_keys  key       key_len  ref                  rows  filtered  Extra  
------  -----------  ------  ----------  ------  -------------  --------  -------  -----------------  ------  --------  --------
     1  SIMPLE       test    (NULL)      ref     test_Idx       test_Idx  459      const,const,const       1    100.00  (NULL) 
 
 
-- 这个也走索引了哟
EXPLAIN SELECT * FROM test WHERE col1 = 'a2' AND col3='c2';  
    id  select_type  table   partitions  type    possible_keys  key       key_len  ref       rows  filtered  Extra                 
------  -----------  ------  ----------  ------  -------------  --------  -------  ------  ------  --------  -----------------------
     1  SIMPLE       test    (NULL)      ref     test_Idx       test_Idx  153      const        1     16.67  Using index condition   
 
 
EXPLAIN SELECT * FROM test WHERE col1 LIKE 'a2%' AND col3='c2';
    id  select_type  table   partitions  type    possible_keys  key       key_len  ref       rows  filtered  Extra                 
------  -----------  ------  ----------  ------  -------------  --------  -------  ------  ------  --------  -----------------------
     1  SIMPLE       test    (NULL)      range   test_Idx       test_Idx  153      (NULL)       1     16.67  Using index condition

```

**示例2，未走索引**

```sql
EXPLAIN SELECT * FROM test WHERE col2 = 'b2' ;
    id  select_type  table   partitions  type    possible_keys  key     key_len  ref       rows  filtered  Extra       
------  -----------  ------  ----------  ------  -------------  ------  -------  ------  ------  --------  -------------
     1  SIMPLE       test    (NULL)      ALL     (NULL)         (NULL)  (NULL)   (NULL)       6     16.67  Using where 
 
 
EXPLAIN SELECT * FROM test WHERE col2 = 'b2' AND col3='c2';
    id  select_type  table   partitions  type    possible_keys  key     key_len  ref       rows  filtered  Extra       
------  -----------  ------  ----------  ------  -------------  ------  -------  ------  ------  --------  -------------
     1  SIMPLE       test    (NULL)      ALL     (NULL)         (NULL)  (NULL)   (NULL)       6     16.67  Using where 
 
 
EXPLAIN SELECT * FROM test WHERE col1 LIKE '%a2%';
    id  select_type  table   partitions  type    possible_keys  key     key_len  ref       rows  filtered  Extra       
------  -----------  ------  ----------  ------  -------------  ------  -------  ------  ------  --------  -------------
     1  SIMPLE       test    (NULL)      ALL     (NULL)         (NULL)  (NULL)   (NULL)       6     16.67  Using where
```

# SQL关键字执行顺序

```sql
SELECT 
DISTINCT <select_list>
FROM <left_table>
<join_type> JOIN <right_table>
ON <join_condition>
WHERE <where_condition>
GROUP BY <group_by_list>
HAVING <having_condition>
ORDER BY <order_by_condition>
LIMIT <limit_number>
```

- 执行顺序

```SQL
FROM
<表名> # 笛卡尔积
ON
<筛选条件> # 对笛卡尔积的虚表进行筛选
JOIN <join, left join, right join...> 
<join表> # 指定join，用于添加数据到on之后的虚表中，例如left join会将左表的剩余数据添加到虚表中
WHERE
<where条件> # 对上述虚表进行筛选
GROUP BY
<分组条件> # 分组
<SUM()等聚合函数> # 用于having子句进行判断，在书写上这类聚合函数是写在having判断里面的
HAVING
<分组筛选> # 对分组后的结果进行聚合筛选
SELECT
<返回数据列表> # 返回的单列必须在group by子句中，聚合函数除外
DISTINCT
# 数据除重
ORDER BY
<排序条件> # 排序
LIMIT
<行数限制>
```

# 排序

```sql
 order by 
 FIELD(qmc,'越秀区','海珠区','荔湾区','天河区','白云区','黄埔区','花都区','番禺区','南沙区','从化区','增城区','其他')
```

# 拿到表所有字段

```sql
select group_concat(COLUMN_NAME) from (
select COLUMN_NAME from information_schema.COLUMNS where table_name = 'ex_zhengwu_115_jkzcsbsj'
) t
```

# sql截逗号,

```sql
-- ads_zhengwu_12385_hsjczdrqmd_base 一个从1开始的自增顺序的表
SELECT  SUBSTRING_INDEX(SUBSTRING_INDEX('7654,7698,7782,7788,8899',',',id),',',-1) AS num 
FROM  ads_zhengwu_12385_hsjczdrqmd_base
WHERE  id < LENGTH('7654,7698,7782,7788,8899')-LENGTH(REPLACE('7654,7698,7782,7788,8899',',',''))+2
ORDER BY id


SELECT  SUBSTRING_INDEX(SUBSTRING_INDEX(b.division_street,',',a.id),',',-1) AS num 
FROM  ads_zhengwu_12385_hsjczdrqmd_base a ,(
select division_street from ads_map_lasso 
where is_valid = '0' and is_delete = '1'
) b
WHERE  a.id < LENGTH(b.division_street)-LENGTH(REPLACE(b.division_street,',',''))+2
```

# 逗号拼接一个字段的数据

```sql
SELECT GROUP_CONCAT(distinct AREANAME SEPARATOR ",") FROM ads_sqperson_report WHERE sf_valid = 0 and qx_id = '1656922884770' GROUP BY qx_id
```

# MySQL线程、慢查询

```sql
-- 首先查看对应的线程
show processlist;
#记住对应的id
select * from `performance_schema`.events_statements_current where THREAD_ID=刚才的id
#也可以范围查找
select * from `performance_schema`.events_statements_current where THREAD_ID>=刚才的id
#查出来后，字段SQL_TEXT就是该线程对应的sql语句
-- 慢查询
https://segmentfault.com/a/1190000041688760?utm_source=sf-similar-article
#是否启用了慢查询日志，ON 为启用，OFF 为未启用
SHOW VARIABLES LIKE '%slow_query_log%';
#查看慢查询日志记录数：
SHOW GLOBAL STATUS LIKE '%Slow_queries%';
-- Show Profile 分析慢 SQL
-- 开启
SET profiling = ON;
-- 查看
SHOW VARIABLES LIKE 'profiling%';
-- 命令查看结果
SHOW full profiles

-- sql查询慢查询 时间time秒
select id,info from information_schema.processlist where command='query'and time>20 and info like '%ex_xinxizhongxin_243_xgb_report%';
-- 批量kill 复制所有查询结果,执行
select concat('kill ',id,';') from information_schema.processlist where command='query'and time>20 and info like '%ex_xinxizhongxin_243_xgb_report%';
```

- Query_ID 可以得到具体 SQL 从连接——服务——引擎——存储四层结构完整生命周期的耗时
  `SHOW profile CPU, BLOCK IO FOR QUERY 4(id);`

- 可用参数 type:
  `ALL` # 显示所有的开销信息
  `BLOCK IO` # 显示块IO相关开销
  `CONTEXT SWITCHES` # 上下文切换相关开销
  `CPU` # 显示CPU相关开销信息
  `IPC` # 显示发送和接收相关开销信息
  `MEMORY` # 显示内存相关开销信息
  `PAGE FAULTS` # 显示页面错误相关开销信息
  `SOURCE` # 显示和 Source_function，Source_file，Source_line 相关的开销信息
  `SWAPS` # 显示交换次数相关开销的信息

- #### 危险状态

![在这里插入图片描述](E:\Typora\图片保存\1460000041688769)

- `converting HEAP to MyISAM` # 查询结果太大，内存不够用了，在往磁盘上搬。
- `Creating tmp table` # 创建了临时表，回先把数据拷贝到临时表，用完后再删除临时表。
- `Copying to tmp table on disk` # 把内存中临时表复制到磁盘
- `locked` # 记录被锁了

# 分组取最大

```sql
select person_name xm,insert(mobile_no,4,4,'****') sjhm,idcard_no zjhm,inject_times jzzc,inject_date jzsj
FROM ads_weijian_116_xgymjzxxgxb a
group by idcard_no,inject_times
having inject_times = (SELECT max(inject_times) FROM ads_weijian_116_xgymjzxxgxb WHERE idcard_no = a.idcard_no) 
LIMIT 10
```

# MySQL 插入更新子查询

```sql
INSERT INTO table (id,a,b,c) select id,a,b,c from xxx ON DUPLICATE KEY UPDATE a=VALUES(a),b=VALUES(b),c=VALUES(c)
```

