# SQL

## 查询 -> `SELECT`

```sql
SELECT * FROM 表;
SELECT 表.id FROM 表;	//完全限定名 
```

## 去重 -> distinct -> `DISTINCT`

```sql
SELECT DISTINCT * FROM 表;	//去重
```

## 限制 -> limit -> `LIMIT`

```sql
SELECT * FROM 表 LIMIT 5;	//限制 -> 默认是 [0,5)
SELECT * FROM 表 LIMIT 1,5;	//[1,5)
```

## 排序 -> order by  -> `ORDER BY`

```sql
SELECT id FROM 表 ORDER BY id;   //排序,排序的选择项不一定是查询的选择项 -> order升序(a-z,1-9)
SELECT id,name FROM 表 ORDER BY id,name;    //多行排序,先id排序,id相同的用name排序
SELECT id,name FROM 表 ORDER BY id DESC;		//desc: 降序 -> (z-a,9-1)
SELECT id,name FROM 表 ORDER BY id DESC,name;	//先id降序,id相同的用name升序 
SELECT id,name FROM 表 ORDER BY id DESC,name DESC;	//desc必须为每个都指定,asc: 默认升序
SELECT id,name FROM 表 ORDER BY id DESC LIMIT 1;	//选择最大的一个
SELECT id,name FROM 表 ORDER BY id LIMIT 1;	//选择最小的一个
```

## 过滤 -> where -> `WHRER`

- `<>` -> 不等于
- `between 1 and 2` -> BETWEEN  1 AND 2 -> 两个值之间
- `is null` -> IS NULL -> 包含空值(空指与0,空字符串,空格是不同的是指真的没有)

```sql
SELECT id FROM 表 WHERE id = 1;	//相等过滤
SELECT id FROM 表 WHERE id = 1 ORDER BY id;	//相等过滤 + 排序
SELECT id,name FROM 表 WHERE id <> 1;	//过滤id不等于1
SELECT name,id FROM 表 WHERE name != '罗';	//过滤name不等于'罗'的字符串
SELECT id FROM 表 WHERE id BETWEEN 1 AND 2;	//过滤id在[1,2]区间
SELECT id FROM 表 WHERE id IS NULL;	//查询id不存在的数据
```

## 多个过滤操作符 -> and,or,in,not -> `AND,OR,IN,NOT`

- **where * and * ; where * or * ; where * in (1,2) ; where id NOT (1,2)**
- or 组合 and -> 会优先执行and -> 任何时候and和or同时出现,都应该使用圆括号()

```sql
SELECT id,name FROM 表 WHERE id = 1 AND name = '罗';	//and; 和,连接多个where
SELECT id,name FROM 表 WHERE id = 1 OR id = 2;	//or: 或,连接多个where
/* or 组合 and -> 会优先执行and */
SELECT id,name FROM 表 WHERE name = '罗' OR name = '王' AND id = 1;
/* 等价于 */
SELECT id,name FROM 表 WHERE name = '罗' OR (name = '王' AND id = 1);
/* 正确写法 */
SELECT id,name FROM 表 WHERE (name = '罗' OR name = '王') AND id = 1;

SELECT id,name FROM 表 WHERE id IN (1,2,3);	//in: 指定条件,功能与多个or相当,in的执行比or更快
SELECT id,name FROM 表 WHERE id NOT IN (4,5);//not: 排除条件,与不等于相当,not可以和关键字组合取反
```

## 通配符 -> `**% , _**`

- `%` -> 任何字符任何次数
- `_` -> 只匹配单个字符

## 模糊查询 -> like -> `LIKE`

- like会影响效率,能不使用就不使用

```SQL
SELECT name FROM 表 WHERE name LIKE 'lo%';	//匹配lo开头的name
SELECT name FROM 表 WHERE name LIKE '%o%';	//匹配中间有o的name
SELECT name FROM 表 WHERE name LIKE '_o';	//匹配任意头字符,第二个字符是o的name
```

## 正则表达式 -> regexp -> `REGEXP`

- REGEXP不区分大小写 -> 加上BINARY区分大小写
- 正则和like的区别 -> 正则有包含关系
  - `LIKE '_德'` -> 只包含2个字符且第二个是德
  - `REGEXP '.德' `-> 德前面存在一个任意字符的字符串
- `.` -> 匹配任意一个字符,必须有一个                    `?` -> 0个或一个任意字符
-  `+` -> 一个或多个任意字符                                     `*` -> 0个或多个任意字符
-  `{6}` -> 指定6个任意字符          `{6,}` -> 最少6个任意字符      `{6,100}` -> 最少6个最多100个任意字符
- `|` -> 或
- `[12]` -> 匹配中括号中的任意一个  `[1-9]` `[a-z]`: 匹配范围   `[^1,2]` -> 不包括1,2中任何一个
- `^` -> 在[ ]内是取反,在外边表示文本开始位置,^字符串起始位置
  - `^[0-9]` -> 起始位置是一个数字
- `$` -> 表示字符串的结尾
  - `[0-9]$` -> 结尾是一个数字
- 使用`\\`取特殊字符 -> `\\. -> 取.` `\\| -> 取|`
  - `\\f -> 换页` `\\n换行` `\\r -> 回车` `\\t -> 制表符`
  - 使用两个\是因为Mysqsl使用一个,正则表达式使用一个,

```sql
SELECT name FROM 表 WHERE name REGEXP '德';	//正则匹配包含德的name
SELECT name FROM 表 WHERE name REGEXP '.德';	//正则可以用.来匹配单个字符
SELECT name FROM 表 WHERE name REGEXP BINARY 'Ss.';	//binary: 区分大小写
SELECT name FROM 表 WHERE name REGEXP 'soso|dodo';	//|: 或
SELECT name FROM 表 WHERE name REGEXP '[sdf] tom';	//[]: 匹配中括号中任意一个,[12]==[1|2]
SELECT name FROM 表 WHERE name REGEXP '[^12]	tom';	//^: 取反,[^12],不包括1,2中任何一个
SELECT name FROM 表 WHERE name REGEXP `\\.`;	//匹配.
SELECT name FROM 表 WHERE name REGEXP '\\([0-9] tom?\\)';	//结果: xx (9 tomm) xx
SELECT name FROM 表 WHERE name REGEXP '[0-9]{4}';	//匹配包含4个任意数字的字符串
SELECT name FROM 表 WHERE name REGEXP '^[0-9] tom';	//匹配起始位置是数字的tom字符串
SELECT name FROM 表 WHERE name REGEXP '[0-9]$';	//匹配结尾是数字的字符串
```

## 计算 -> 拼接等 -> `concat()  ` `+-*/`

- `concat()` -> 拼接
- `trim` -> 裁剪左右空格     `rtrim` -> 裁剪右边空格     `lrtim` -> 裁剪左边空格
- `AS` -> 别名,计算字段
- `+-*/` -> 都可以使用

```sql
SELECT Concat(id,'(',name,')') FROM 表 ORDER BY name;	//拼接id(name)
SELECT Concat(RTrim(id),'(',Trim(name),')') FROM 表;	//先裁剪再拼接
SELECT Concat(id , '+' , name) AS newName FROM 表;	//新生成的列使用别名
SELECT id,price,number,price * number AS 总价格 FROM 表;	//可以使用+-*/
```

> 数据处理函数 -> 函数的可移植性是很差的,尽量不要使用太特殊化的函数

## 文本处理函数 -> `Trim()` `Upper()` `Length()`

-  `Trim()`:裁剪左右空格     `Upper()`:转换全大写     `Lower()`:转换全小写   `Length()`:返回长度
- `Left('name',2)`:返回最左边的n个字符     `Right('name',2)`:返回最右边的n个字符
- `SubString('name',start,length)`:返回一个子串 
  - SubString('abcdefg',2,4) -> 结果: bcde

```sql
SELECT name,Upper(name) AS newName FROM 表 ORDER BY name;	//name转换全大写
SELECT name,Lower(name) AS newName FROM 表 ORDER BY name;	//name转换全小写
SELECT name,Left(name,2) AS newLeft FROM 表 ORDER BY name;	//name最左边的2个字符
SELECT name,Right(name,2) AS newRight FROM 表 ORDER BY name;	//name最右边的2个字符
SELECT name,SubString(name,2,2) AS newString FROM 表;		//返回一个子串 
```

## 日期处理函数 -> `Date(date)` `Now()`

- 首选`data=2000-01-01 11:30:10`

- `Date(date)` -> 返回日期部分(2000-01-01)   `Time(date)` -> 返回时间部分(11:30:10)
- `Year(date)`:年 `Month(date)` :月 `Day(date)` : 日  `Hour(date)` : 时 `Minute(date)` :分`Second(date)`:秒
- `Now()`:返回当前系统日期和时间  `CurDate()`:当前日期   `CurTime()`:当前时间

```sql
SELECT id,name FROM 表 WHERE Date(date) = '2000-01-01';	//匹配日期为2000-01-01
SELECT id,name FROM 表 WHERE Time(date) = '11:30:10';	//匹配时间
SELECT id,name FROM 表 WHERE Year(date) = 2000;	//匹配年
SELECT id,name FROM 表 WHERE Date(date) BETWEEN '1900-10-10' AND '1999-10-10';//匹配日期范围
SELECT id,name FROM 表 WHERE Year(date) = 2000 AND Month(date) = 1;//匹配年和月
```

## 数据处理函数 -> `Abs(data)`  `Rand()`

- `Abs(data)`:返回数的绝对值 `Sqrt(data)`:返回一个数的平方根
- `Sin(data)`:返回角度正弦   `Cos(data)`:返回角度余弦    `Tan(data)`:返回角度正切
-  `Mod(data/2)`:余数  `Pi()`:圆周率  `Rand()`:随机数 

```sql
SELECT id,name FROM 表 WHERE Abs(date) = 2;		//匹配绝对值=2的
SELECT id,name FROM 表 WHERE Mod(date/2) = 2;	//匹配余数=1的
```

## 聚合函数 -> 汇总 -> `AVG()` `SUN()` `COUNT()`

- 对**多行(表级)的数据**进行汇总,不再是对某一行的数据做**+-*/**,而是多行

- `AVG()`:返回某列的平均值(忽略null)   `COUNT()`:返回某列的行数(忽略null)
- `MAX()`:某列的最大值   `MIIN()`:某列的最小值    `SUN()`:某列值之和

```sql
SELECT AVG(id) AS newData FROM 表;	//id的平均值
SELECT AVG(price) AS newData FROM 表 WHERE id = 1;	//id=1 价格的平均值
SELECT AVG(DISTINCT data) AS newData FROM 表 WHERE id = 1;	//data字段去重后的平均值
SELECT COUNT(*) AS newCount FROM 表 WHERE id = 1;	// *不会忽略null
SELECT COUNT(name) AS newCount FROM 表 WHERE id = 1;	// 单列会忽略null
SELECT COUNT(DISTINCT name) AS newCount FROM 表 WHERE id = 1;	// 去重后的数量
SELECT MAX(price) AS newPrice FROM 表 WHERE id = 1;	// MAX丶MIN都会忽略null
SELECT SUN(price) AS newPrice FROM 表 WHERE id = 1;	// id=1 的price的和
SELECT SUN(price * number) AS newPrice FROM 表 WHERE id = 1;	//id=1且(价格和商品数量相乘)的和
/* 组合聚合函数 */
SELECT COUNT(*) AS newCount,AVG(data) AS newAvg,MAX(price) AS newMax,SUN(price) AS newPrice
FROM 表;
/* 聚合函数和列同时使用必须加上分组 👇 */
SELECT id,COUNT(*) AS newCount FROM 表;//这样是不行的,如果聚合函数有其他检索列,必须加上分组
SELECT id,COUNT(*) AS newCount FROM 表 GROUP BY id;
```

## 分组 -> `group by`  `having`

- 分组的字段必须是检索列,SELECT后面的**每个列都必须出现在GROUP BY 后边**
  - `SELECT id1,id2 FROM 表 GROUP BY id1,id2,id3` -> GROUP BY 子句只能多不能少
  - 队列分组的原理是: id1,id2,id3都相等的分为一组,有一个不同的都算不同的组
- null也会分为一组
- GROUP BY 在 WHERE 之后 ORDER BY 之前
- 使用WITH ROLLUP得到每个聚合函数的汇总
  - `... GROUP BY id WITH ROLLUP;` -> 如下多出来的null一行就是给两个聚合函数汇总的
  - id  COUNT(*)  SUN(price)
  - 1         2                  10
  - 2         5                  20
  - null     7                  30

```sql
SELECT id,COUNT(*) AS newCount FROM 表 GROUP BY id;	//对id进行分组并且统计每个组的行数
SELECT id,name,COUNT(*) AS newCount FROM 表 GROUP BY id,name;//对id和name都相同的分为一组,求行数
SELECT id,COUNT(*) AS newCount FROM 表 GROUP BY id WITH ROLLUP;	//分组聚合再汇总
```

## 过滤分组 -> `having`

- having可以分组后,对这些组做where一样的过滤
- where不能对组进行过滤
- having拥有where所有的功能,甚至可以替换where使用
- where分组前过滤,having分组后过滤

```sql
/* 先将id分组,再匹配函数大于1的数据,不能用别名 */
SELECT id,COUNT(*) AS newCount FROM 表 
GROUP BY id HAVING COUNT(*) > 1;
/* 先where匹配指定日期范围,再根据id分组,再匹配行数大于1的数据 */
SELECT id,COUNT(*) AS newCount FROM 表
WHERE Date(date) BETWEEN '2000-01-01' AND '2020-01-01'
GROUP BY id HAVING COUNT(*) > 1;
/* 聚合函数和列同时使用必须加上分组 👇 */
SELECT id,COUNT(*) AS newCount FROM 表;//这样是不行的,如果聚合函数有其他检索列,必须加上分组
SELECT id,COUNT(*) AS newCount FROM 表 GROUP BY id;
/* GROUP BY是不会排序的,排序依然要加上ORDER BY */
SELECT id,COUNT(*) AS newCount 
FROM 表 
WHERE Date(date) BETWEEN '2000-01-01' AND '2020-01-01'
GROUP BY id 
HAVING COUNT(*) > 1
ORDER BY newCount 
LIMIT 10;
```



## 子查询

- 一个需求中,我们可能需要多次查询数据,第一次查询的结果作为下一次查询的条件,就可以用子查询

```sql
SELECT name FROM 表1 WHERE id < 10;	//拿到id小于10的所有人名name
SELECT age FROM 表2 WHERE name IN (?,?);	//在表2中查询某些name人的年龄age
/*  使用子查询拼接: 利用第一次查询的结果作为条件,查询第二次 */
SELECT age FROM 表2 
WHERE name IN (
    SELECT name FROM 表1 WHERE id < 10
);
/* 
下面稍微难一点: 子查询出现在SELECT后面
表2中id是不重复的,一个id对应一个人
表1中id是重复的,一个id可以对应多条记录,代表一个人做了多种事
目标是查询表2的数据,过程中 需要从表1中 查询表2各个id 在表1中出现的次数
*/
SELECT COUNT(*) FROM 表1 WHERE 表1.id = 表2.id;	//这个表示表2.id,在表1中出现的次数
/* 👇组合子查询 */
SELECT name,(
    SELECT COUNT(*) FROM 表1 WHERE 表1.id = 表2.id) AS count
FROM 表2 
ORDER BY name;
/* 
注意: 这类查询的测试方法是一步一步来
我们可以分步进行,先查询嵌入的SELECT,再用硬编码的方式进行下一次查询
例如: SELECT COUNT(*) FROM 表1 WHERE 表1.id = 表2.id(假设这个是1); 结果就是一个id是1的数量:假如是10
SELECT name,(10) AS count
FROM 表2 
ORDER BY name;
*/
```

## 联结 -> `join`

- **FROM 后面跟多个表** -> 之前都只跟一个表,联结就是FROM后跟多个表查询

- 主键: 一个表中的唯一标识符,不可重复,区分表中的每一行
- 外键: 表1的主键被表2的**某个字段使用**,那么这个字段就是表2的外键,也是表1的主键,不同位置叫法不一样

```sql
/* 
表1的idTwo字段是外键,是表2的主键
如果没有where条件,表1的每一条数据都会匹配表2的所有行,导致出现笛卡尔乘积
					表1有2条数据,表2有100条,结果会是200条数据
应该保证所有联结都要有where条件
*/
SELECT 表1.name,表2.name
FROM 表1,表2
WHERE 表1.idTwo = 表2.id
ORDER BY 表1.name,表2.name;
/* 改写为子查询的模式 */
SELECT 表1.name,(
    SELECT 表2.name FROM 表2 WHERE 表1.idTwo = 表2.id) AS newName
FROM 表1
ORDER BY 表1.name,newName;
```

- 上面的例子改为`inner join`的形式 -> 内部联结

```sql
/* inner join: 联结   ON: 相当于where */
SELECT 表1.name,表2.name
FROM 表1 INNER JOIN 表2 
ON 表1.idTwo = 表2.id
ORDER BY 表1.name,表2.name;
/* 联结多个表 */
SELECT 表1.name,表2.name,表3.name
FROM 表1,表2,表3
WHERE 表1.idTwo = 表2.id
AND 表2.idThree = 表3.id
ORDER BY 表1.name,表2.name,表3.name;
```

> 外部联结 -> `LEFT OUTER JOIN 表 ON` `RIGHT OUTER JOIN 表 ON`

- LEFT : 左边的所有元素都要显示,就算不符合where(on)条件的,也要显示出来,匹配为null
- RIGHT: 右边的所有元素都要显示,就算不符合where(on)条件的,也要显示出来,匹配为null

```sql
SELECT 表1.name,表2.name
FROM 表1 LEFT OUTER JOIN 表2 
ON 表1.idTwo = 表2.id;
----------------------------------
表1.name 表2.name
	1		1
	2		2
	3		null
	4		4
	
SELECT 表1.name,表2.name
FROM 表1 RIGHT OUTER JOIN 表2 
ON 表1.idTwo = 表2.id;
----------------------------------
表1.name 表2.name
	1		1
	2		2
	4		4
	NULL	5
```

- 带聚合的联结

```sql
SELECT 表1.name,表1.id,COUNT(表2.name) AS newCount
FROM 表1 INNER JOIN 表2 
ON 表1.idTwo = 表2.id
GROUP BY 表1.id;
```

## 组合查询 -> `UNION`

- `UNION`和`WHERE`是又相似的效果的,性能会有些许不同
- `UNION`的每条查询必须包含相同的列丶表达式丶聚合函数 -> 顺序无要求
- `UNION`会默认去重,重复的不会显示多次,想要不去重可以使用`UNION ALL`
  - `UNION ALL`是`WHERE`无法实现的,其他时候`UNION`和`WHERE`几乎是一样的
- `UNION`排序只能出现一次在最后

```sql
/* where */
SELECT id,name,price FROM 表 WHERE price < 10;
SELECT id,name,price FROM 表 WHERE id IN (1,2);

SELECT id,name,price FROM 表 
WHERE id IN (1,2)
OR price < 10;
/* union */
SELECT id,name,price FROM 表 WHERE price < 10
UNION
SELECT id,name,price FROM 表 WHERE id IN (1,2);
/* ORDER BY */
SELECT id,name,price FROM 表 WHERE price < 10
UNION
SELECT id,name,price FROM 表 WHERE id IN (1,2)
ORDER BY name;
```

# 插入数据 -> `INSERT`

```sql
INSERT INTO 表(id,name) VALUES(id,name);
/* 插入多条 */
INSERT INTO 表(id,name) VALUES(id,name);
INSERT INTO 表(id,name) VALUES(id,name);

INSERT INTO 表(id,name) VALUES(id,name),(id,name),(id,name),(id,name);

insert into 表 (id,a,b,c) values (5,6,6,6) on duplicate key update a = VALUES(password), b=VALUES(password),c=VALUES(password); 
```

- **insert插入检索select出的数据** -> `INSERT SELECT`

```sql
INSERT INTO 表(id,name) SELECT id,name FROM 表2;	//insert的表列可以不与select的列名称一样
```



# 更新和删除 -> `UPDATE DELETE`

- UPDATE 更新如果发生错误会回滚,如果需要发生错误也继续执行,这需要关键字
  - `ignore` -> `IGNORE`
- 更可能的加上where

```sql
UPDATE 表 SET name = ‘1’,age = 10 WHERE id = 1;
DELETE FROM 表 WHERE id = 1;
/* 删除所有行 */
TRUNCATE TABLE  表;
```



# 创建数据库 -> `CREATE DATABASE`

```sql
CREATE DATABASE dbname;
SHOW DATABASES;
```



# 创建表 -> `CREATE TABLE`

```sql
CREATE TABLE 表               
(                
	id int NOT NULL AUTO_INCREMENT,                
	name char(50) ,                
	PRIMARY KEY (id)                          
) ENGINE=InnoDB; 

DROP TABLE IF EXISTS `t_in_or_union_test`;
CREATE TABLE `t_in_or_union_test` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `text_1` varchar(10) DEFAULT NULL,
  `text_2` varchar(10) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_1` (`text_1`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;
```

# 删除表 -> `DROP TABLE`

```sql
DROP TABLE 表
```

# 重命名表 -> `RENAME TABLE`

```SQL
RENAME TABLE 新表 TO 旧表;

RENAME TABLE 新表1 TO 旧表1,
			 新表2 TO 旧表2,
			 新表3 TO 旧表3;
```



# 表中添加删除列 -> `ALTER TABLE`

```sql
ALTER TABLE 表                
ADD name CHAR(50) 

#table_name -> 在old_column之后
ALTER TABLE table_name 
ADD COLUMN column_name VARCHAR(100) DEFAULT NULL COMMENT '新加字段' AFTER old_column;
```

```sql
ALTER TABLE 表               
DROP COLUMN name
```

# 建立联合索引的语法

- `ALTER TABLE` -> ALTER TABLE用来创建**普通索引、UNIQUE索引或PRIMARY KEY索引**

```sql
/* 索引名index_name可选，缺省时，MySQL将根据第一个索引列赋一个名称 */
ALTER TABLE table_name ADD INDEX index_name (column_list)
ALTER TABLE table_name ADD UNIQUE (column_list)
ALTER TABLE students ADD PRIMARY KEY (sid)
```

- `CREATE INDEX` -> 可对表增加普通索引或UNIQUE索引

```sql
CREATE INDEX index_name ON table_name (column_list)
CREATE UNIQUE INDEX index_name ON table_name (column_list)
```

- 删除索引 ->  可利用`ALTER TABLE`或`DROP INDEX`语句来删除索引

```sql
/* 前两条语句是等价的，删除掉table_name中的索引index_name */
DROP INDEX index_name ON talbe_name
ALTER TABLE table_name DROP INDEX index_name
/* 
只在删除PRIMARY KEY索引时使用，因为一个表只可能有一个PRIMARY KEY索引，因此不需要指定索引名。
如果没有创建PRIMARY KEY索引，但表具有一个或多个UNIQUE索引，则MySQL将删除第一个UNIQUE索引
*/
ALTER TABLE table_name DROP PRIMARY KEY
```

- 注意
  - **只要列中包含有NULL值**都将`不会被包含在索引`中，`复合索引中只要有一列含有NULL值`，那么这一列对于此**复合索引就是无效**的

# 索引常用操作,增删改查

## 查询索引

```sql
show index from tablename;
```

## 增加索引

普通索引

```sql
create table t_dept(
    no int not null primary key,
    name varchar(20) null,
    sex varchar(2) null,
    info varchar(20) null,
    index index_no(no)
  );
create index index_no on t_dept(name);
alter table t_dept add index idx_no(no);
```

唯一索引

```sql
create table t_dept(
       no int not null primary key,
       name varchar(20) null,
       sex varchar(2) null,
       info varchar(20) null,
       unique index index_no(no)
     );
create unique index index_no on t_dept(no);
alter table t_dept add unique index index_no(no);
```

组合索引

```sql
create table t_dept(
       no int not null primary key,
       name varchar(20) null,
       sex varchar(2) null,
       info varchar(20) null,
       key index_no_name(no,name)
     );
create index index_no_name on t_dept(no,name);
alter table t_dept add index index_no_name(no,name);
```



```sql
主键索引： 一般建表的时候通过 PRIMARY KEY(indexName) 添加. 当然也可以通过 ALTER 命令；
```

## 删除索引

```sql
alter table 表名 drop index index_name;
drop index index_name on 表名； 
```

## 不锁表添加字段索引

```sql
ALTER TABLE `member` ADD `user_from` smallint(1) NOT NULL, ALGORITHM=INPLACE, LOCK=NONE

alter table `member` add index index_no_name(no,name), ALGORITHM=INPLACE, LOCK=NONE;
show variables like '%innodb_lock_wait_timeout%';  //20
set innodb_lock_wait_timeout=200;
```

ALGORITHM表示算法：default默认（根据具体操作类型自动选择），inplace（不影响DML），copy创建临时表（锁表），INSTANT只修改元数据（8.0新增，在修改名字等极少数情况可用）

LOCK表示是否锁表：default默认，none，shared共享锁，exclusive



# 表

```sql
-- 创建表
CREATE TABLE ads_sq_three_person_group (
  insert_id varchar(38) ,
  insert_time timestamp(6) NULL DEFAULT null COMMENT '插入时间',
  id varchar(36)  NOT NULL COMMENT '',
  district varchar(50) COMMENT '所属辖区-市-区-街-社区',
  city varchar(10) COMMENT '市',
  area varchar(10) COMMENT '区',
  street varchar(20) COMMENT '街镇',
  community varchar(50) COMMENT '社区',
  group_name varchar(100) COMMENT '组名-30字以内',
  nature_zero int2 COMMENT '小组性质字典值ads_sq_three_person_group_nature
1, 默认3 其他',
  nature_one int2 COMMENT '小组性质字典值ads_sq_three_person_group_nature
1常态 0战时 默认3 其他',
  check_status int2 COMMENT '抽查状态
字典值ads_sq_three_person_group_check_status
2待抽查、1通过、0不通过',
  check_time timestamp(6) NULL DEFAULT null COMMENT '抽查时间',
  work_status int2 COMMENT '工作状态
字典值ads_sq_three_person_group_work_status
1 正在工作',
  creator varchar(36) COMMENT '创建人',
  create_time timestamp(6) NULL DEFAULT null COMMENT '创建时间',
  update_user varchar(36) COMMENT '更新人',
  update_time timestamp(6) NULL DEFAULT null COMMENT '更新时间',
  grid_code varchar(36) COMMENT '网格编码',
  status int2 COMMENT '数据有效状态，1：有效； 0：无效',
  old_system_num int4 COMMENT '旧系统累计数',
	PRIMARY KEY (`insert_id`) USING BTREE
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='社区三人小组表';

alter table student modify s_name varchar(100) comment '姓名-更改';


alter table ads_sq_three_person_group add index idx_group_name(group_name);
alter table ads_sq_three_person_group add index idx_grid_code(grid_code);
alter table ads_sq_three_person_group add index idx_insert_time(insert_time);
alter table ads_sq_three_person_group add index idx_status(status);
alter table ads_sq_three_person_group add index idx_update_time(update_time);
```



# EXPLAIN

![image-20220323150201515](../../../图片保存\image-20220323150201515.png)

![image-20220323150036166](../../../图片保存\image-20220323150036166.png)

## id列

`id列相同`执行顺序由上到下 -> 依次执行

![image-20220323151443499](../../../图片保存\image-20220323151443499.png)

`id 不相同`，越大越优先；

- id=1最后执行 , id越大说明越是内层 , 更内层的子查询

`id相同与不同并存`

- 先优先级(id大小)；然后按照从上往下依次执行；

![image-20220323151724221](../../../图片保存\image-20220323151724221.png)

## select_type列：数据读取操作的操作类型

![image-20220323151845566](../../../图片保存\image-20220323151845566.png)

-  `SIMPLE`:简单的select 查询，SQL中不包含子查询或者UNION。（**不包含子查询和union**）

- `PRIMARY`:查询中包含复杂的子查询部分，最外层查询被标记为PRIMARY（**最外层**）；

- `SUBQUERY`:在select 或者WHERE 列表中包含了子查询；（**非最外层**）

- `DERIVED`:在FROM列表中包含的子查询会被标记为DERIVED(**衍生表**)，MYSQL会递归执行这些子查询，把结果集放到**零时表**中。
  - 在from 子查询中，只有一张表，临时表：例如：

    ```sql
    select cr.name  from (select * from course where tid in(1,2)) cr;
    ```

  - 如果from中，table1 union table2 ;其中，**table1 就是DERIVED**  、 **table2就是 union**;

    ```sql
    select cr.cname from 
    (select * from course where tid=1 
     union 
     select * from course where tid=2
    ) cr;
    ```

- `UNION`:如果第二个SELECT 出现在UNION之后，则被标记位UNION；

  - 如果UNION包含在FROM子句的子查询中，则外层SELECT 将被标记为DERIVED；

  ```sql
  select cr.cname from 
  (select * from course where tid=1 
   union
   select * from course where tid=2 
  ) cr;
  ```

- `UNION RESULT`:从UNION表获取结果的select；

## table列：该行数据是关于哪张表

## type列: 重要

> 访问类型（查询类型，索引类型 ）  

- 由好到差
- `system > const > eq_ref > ref > range > index > ALL`
-  其中，system const  是理想情况，实际可以达到的：`ref > range` 
- 出现`index > ALL`就是最差的,要优化

![image-20220323152918301](../../../图片保存\image-20220323152918301.png)

**注意： 要对type优化的前提：有索引；**

- 各个类型含义：

- `system`:表只有一条记录(等于系统表),这是const类型的特例，平时业务中不会出现。

- `const`:通过**索引一次查到数据**，该类型主要用于比较primary key 或者unique 索引

  - 因为只匹配一行数据，所以很快;
  - 如果将主键置于WHERE语句后面，Mysql就能将该查询转换为一个常量

- `eq_ref`:**唯一索引扫描**，对于每个索引键，表中只有一条记录与之匹配（唯一行数据）。

  - 常见于主键或者唯一索引扫描。

    ```sql
    select t.tcid from teacher t,teacherCard tc where t.tcid = tc.tcid;
    t.tcid = tc.tcid; 分别是主键索引和唯一索引；
    eq_ref：要求主查询出来的数据只有一条！！ 并且不能为0；
    ```

- `ref`（普通索引）:**非唯一索引扫描**，返回匹配某个单独值得所有行

  - 本质上是一种索引访问，它返回所有匹配某个单独值的行
  - 就是说它可能会找到**多条符合条件的数据**，所以他是查找与扫描的混合体。
  - **详解：**
  - 这种类型表示mysql会根据**特定的算法**快速查找到某个符合条件的索引
  - 而`不是`会对索引中每一个数据都进行一 一的扫描判断
  - 也就是所谓你平常理解的**使用索引查询会更快的取出数据**。
  - 而要**想实现这种查找，索引却是有要求的**
  - 要实现这种能快速查找的算法，索引就要**满足特定的数据结构**
  - 简单说，也就是索引字段的数据`必须是有序的`，才能实现这种类型的查找，才能利用到索引。

  - 根据索引查询，返回数据不唯一；    0或者多；

- `range`：**只检索给定范围的行**，使用一个索引来选择行。
  - 一般在你的WHERE 语句中出现`between 、< 、> 、in `等查询，这种给定范围扫描比全表扫描要好。
  - 因为他只需要开始于索引的某一点，而结束于另一点，不用扫描全部索引。

  - 根据索引，范围查询；
- `index`：`FUll Index Scan 扫描遍历索引树`
  - index：这种类型表示是**mysql会对整个该索引进行扫描**
  - 要想用到这种类型的索引，对这个索引并无特别要求，只要是索引，或者某个复合索引的一部分
  - mysql都可能会采用index类型的方式扫描。
  - 但是呢，**缺点是效率不高**，mysql会从索引中的`第一个数据一个个的查找到最后一个数据`
  - 直到找到符合判断条件的某个索引

  - **index：查询所有索引列查询一遍；**
- `ALL` **全表扫描** 从磁盘中获取数据 百万级别的数据ALL类型的数据尽量优化。
  
  - 把整个表查询了一遍；

## key列: 显示使用了哪个索引

## ken_len列

- 表示**索引**中使用的**字节数**，可通过该列计算**查询中使用的索引长度**
- 在不损失精确性的情况下，**长度越短越好**
- key_len 显示的值为索引字段的**最大可能长度**，**并非实际使用长度**
- 即key_len是根据表定义计算而得，不是通过表内检索出来的。

## ref列

- 显示索引的**哪一列被使用了**，如果可能的话，是一个常数。
- 哪些**列或常量**被用于查找索引列上的值。

## rows列: 每张表有多少行被优化器查询

- 根据表统计信息及索引选用的情况，大致估算找到所需记录需要读取的行数。

## Extra列

- 扩展属性，但是很重要的信息。

 1. `using temporary`;  性能损耗大,尽量避免采用临时表 ，一般出现在group by 语句中；

- 避免using temporary;
   `from ----  where ----- group by -----  having ---- select ---- order by ----limit `
- 这里在group by 中；**查询哪些列，就group by 那些列**；
   `select a1 from test02 where a1 in (1,2,4) group by a1;` -> 一张表
   `select a1 from test02 where a1 in(1,2,3) group by a2;` -> 不是一张表；using temporary;

 2. using index;性能提升；索引覆盖；
 原因：不需要读取源文件，只要从索引文件中就可以查询；(不需要回表查询)
 比如：索引是age ;

# 存储过程

```sql
CREATE DEFINER=`gz_zhongda`@`%` PROCEDURE `stat_EX_XINXIZHONGXIN_243_XGB_REPORT_POINT`()
BEGIN
	-- 变量定义 -> DECLARE 变量名 变量类型 默认值
	-- EX_XINXIZHONGXIN_243_XGB_REPORT_POINT 表的统计日期
	DECLARE TJRQ_TABLE VARCHAR(32) DEFAULT '';	
	-- 当前日期
	DECLARE TJRQ_POINT VARCHAR(20) DEFAULT '';
	-- 定义一个数量的临时变量
	DECLARE CNT INT DEFAULT 0;
	-- 采样次数
	DECLARE P_JCCS INT DEFAULT 0;
	DECLARE P_YIN INT DEFAULT 0; -- 阴的次数
	DECLARE P_YAN INT DEFAULT 0; -- 阳的次数　
	DECLARE P_POINTID VARCHAR(200) DEFAULT ''; -- 检测地点
	-- 采样点编码
	DECLARE P_POINTCODE VARCHAR(100);
	-- 采样点描述
	DECLARE P_POINT_ADDR VARCHAR(500);
	-- 区域
	DECLARE P_POINT_AREA VARCHAR(200);

	-- 循环控制变量，其值为false时循环结束
	DECLARE DONE INT DEFAULT 1;
	
	-- 检测时长(秒)
	DECLARE P_SC BIGINT(20) DEFAULT 0; 
		
	-- 声明游标(https://www.cnblogs.com/BlueSkyyj/p/10438449.html) -> CURSOR FOR (游标必须始终与SELECT语句相关联)
	-- 接下来使用OPEN语句打开游标-OPEN cursor_name;
	-- 使用FETCH语句来检索光标指向的下一行，并将光标移动到结果集中的下一行-FETCH cursor_name INTO variables list;
	-- 调用CLOSE语句来停用光标并释放与之关联的内存-CLOSE cursor_name;
	
	-- 统计当天的地点数据游标
	DECLARE CUR_LIST CURSOR FOR 
		SELECT SUM(JCCS1) AS JCCS,
					 SUM(CASE WHEN RESULT1 = 0 THEN 1 ELSE 0 END) AS yin,
					 SUM(CASE WHEN RESULT1 = 1 THEN 1 ELSE 0 END) AS yan,
					 POINT1 AS POINTID
		FROM EX_XINXIZHONGXIN_243_XGB_REPORT 
		WHERE POINT1 IS NOT NULL
		GROUP BY POINT1;

    
	-- 统计时长 -> 采样-检测完成的时间
	DECLARE CUR_SC CURSOR FOR
			SELECT AVG(UNIX_TIMESTAMP(jcsj1)-UNIX_TIMESTAMP(cysj1)) AS SC,POINT1 AS POINTID
			FROM EX_XINXIZHONGXIN_243_XGB_REPORT 
			WHERE POINT1 IS NOT NULL AND jcsj1 IS NOT NULL AND cysj1 IS NOT NULL
			GROUP BY POINT1;	

	DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET done=0;  -- 声明异常处理程序

	-- SELECT INTO 语句从一个表中选取数据，然后把数据插入另一个表中。 常用于创建表的备份复件或者用于对记录进行存档。
	-- 获得统计日期
	SELECT TJRQ INTO TJRQ_TABLE FROM `ex_xinxizhongxin_243_xgb_report` LIMIT 1;
	SELECT TJRQ INTO TJRQ_POINT FROM `EX_XINXIZHONGXIN_243_XGB_REPORT_POINT` LIMIT 1;

	-- 如果当前日期不等于表的统计日期，逻动数据
	IF TJRQ_TABLE <> TJRQ_POINT THEN
UPDATE EX_XINXIZHONGXIN_243_XGB_REPORT_POINT 
SET JCCS14=JCCS13,YAN14=YAN13,YIN14=YIN13,JCSC14=JCSC13,
		JCCS13=JCCS12,YAN13=YAN12,YIN13=YIN12,JCSC13=JCSC12,
		JCCS12=JCCS11,YAN12=YAN11,YIN12=YIN11,JCSC12=JCSC11,
		JCCS11=JCCS10,YAN11=YAN10,YIN11=YIN10,JCSC11=JCSC10,
		JCCS10=JCCS9,YAN10=YAN9,YIN10=YIN9,JCSC10=JCSC9,
		JCCS9=JCCS8,YAN9=YAN8,YIN9=YIN8,JCSC9=JCSC8,
		JCCS8=JCCS7,YAN8=YAN7,YIN8=YIN7,JCSC8=JCSC7,
		JCCS7=JCCS6,YAN7=YAN6,YIN7=YIN6,JCSC7=JCSC6,
		JCCS6=JCCS5,YAN6=YAN5,YIN6=YIN5,JCSC6=JCSC5,
		JCCS5=JCCS4,YAN5=YAN4,YIN5=YIN4,JCSC5=JCSC4,
		JCCS4=JCCS3,YAN4=YAN3,YIN4=YIN3,JCSC4=JCSC3,
		JCCS3=JCCS2,YAN3=YAN2,YIN3=YIN2,JCSC3=JCSC2,
		JCCS2=JCCS1,YAN2=YAN1,YIN2=YIN1,JCSC2=JCSC1,
		JCCS1=0,YAN1=0,YIN1=0,JCSC1=NULL,
		TJRQ = TJRQ_TABLE;
	END IF;
	
	-- 更新当天的数据
	SET done=1;
	OPEN CUR_LIST;
	loop_sum:loop-- 循环开始
		-- 处理业务逻辑
		FETCH CUR_LIST INTO P_JCCS,P_YIN,P_YAN,P_POINTID;
		
		if done=0 then
		leave loop_sum;
		end if;
		
		-- 查询地点存不存在，不存在，就新增
		SELECT COUNT(*) INTO cnt FROM EX_XINXIZHONGXIN_243_XGB_REPORT_POINT WHERE POINTID=P_POINTID;
		SET done=1;
		IF cnt > 0 THEN
				-- 更新
				UPDATE EX_XINXIZHONGXIN_243_XGB_REPORT_POINT 
				SET    JCCS1=P_JCCS,YIN1=P_YIN,YAN1=P_YAN,CHANGE_TIME=NOW()
				WHERE  POINTID=P_POINTID;
		ELSE
				-- 新增
				-- 1. 翻译地点信息
				SELECT id,area_name,address INTO P_POINTCODE,P_POINT_AREA,P_POINT_ADDR
				FROM ads_epidemic_data 
				WHERE org_name=P_POINTID LIMIT 1;
				SET done=1;
				INSERT INTO EX_XINXIZHONGXIN_243_XGB_REPORT_POINT(
					TJRQ,CHANGE_TIME,POINTID,YIN1,YAN1,JCCS1,POINTCODE,POINTADRR,DISTRICT
				) VALUES(
					TJRQ_TABLE,NOW(),P_POINTID,P_YIN,P_YAN,P_JCCS,P_POINTCODE,P_POINT_ADDR,P_POINT_AREA
				);
		END IF;
	end loop loop_sum; -- 循环结束
  --  关闭游标
  CLOSE CUR_LIST;
	-- ------------------------------------------------------------------------------

	-- 更新时长
	SET done=1;
	OPEN CUR_SC;
	loop_sum:loop-- 循环开始
		-- 处理业务逻辑
		FETCH CUR_SC INTO P_SC,P_POINTID;
		
		if done=0 then
		leave loop_sum;
		end if;
		
		UPDATE EX_XINXIZHONGXIN_243_XGB_REPORT_POINT 
		SET    JCSC1 = p_SC
		WHERE  POINTID = P_POINTID;
	end loop loop_sum; -- 循环结束
	--  关闭游标
	CLOSE CUR_SC;

END
```

