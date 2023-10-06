## SQL优化策略

- **写完sql -> 直接explain分析执行信息**

```sh
system > const > eq_ref > ref > fulltext > ref_or_null > index_merge > unique_subquery > index_subquery > range > index > ALL

all:全表扫描
index:另一种形式的全表扫描，只不过他的扫描方式是按照索引的顺序
range：有范围的索引扫描，相对于index的全表扫描，他有范围限制，因此要优于index
ref: 查找条件列使用了索引而且不为主键和unique。虽然使用了索引，但该索引列的值并不唯一，有重复。
const:将一个主键放置到where后面作为条件查询，mysql优化器就能把这次查询优化转化为一个常量。

一般来说，得保证查询至少达到range级别，最好能达到ref，type出现index和all时，表示走的是全表扫描没有走索引，效率低下，这时需要对sql进行调优。
```

## 避免不走索引的场景

- 尽量在字段后面使用模糊查询。

```sql
SELECT * FROM t WHERE username LIKE '陈%';//对
SELECT * FROM t WHERE username LIKE '%陈%';//错
```

## 尽量避免使用in 和not in，选择项太多会导致引擎走全表扫描

```sql
SELECT * FROM t WHERE id IN (2,3);
```

- 优化方式：如果是连续数值，可以用between代替。如下：

```sql
SELECT * FROM 表 WHERE id BETWEEN 10 AND 20;
```

- 如果是子查询，可以用exists(存在)代替。

```sql
-- 不走索引
select * from emp where deptno in (select deptno from dept where deptno <30);
-- 走索引
select * from emp e where exists (
	select * from dept d where  deptno <30 and d.deptno = e.deptno ；
);
```

- 首先执行外查询`select * from emp e` ，然后取出第一行数据
- 将数据中的部门编号传给内查询
- 内查询执行`select * from dept d where deptno <30 and d.deptno = e.deptno ；`
- 看是否查询到结果
  - 查询到，则返回true
  - 否则返回false；
- 比如传来的是30，则不满足`deptno <30 and d.deptno = 30`，返回false
- 内查询返回true，则该行**数据保留**，作为结果显示；
- 反之，返回false，则**不作结果显示**
- 逐行查询，看内查询是否查到数据，是否保留作结果显示

## **尽量避免使用 or，会导致数据库引擎放弃索引进行全表扫描**

如果条件中有or，只要其中一个条件没有[索引](https://so.csdn.net/so/search?q=索引&spm=1001.2101.3001.7020)，其他字段有索引也不会使用。

```sql
SELECT * FROM t WHERE id = 1 OR name = '3'
```

优化方式：可以用**union代替or**。如下

```sql
SELECT * FROM t WHERE id = 1
UNION
SELECT * FROM t WHERE name = '3'
```

## 尽量避免进行null值的判断，会导致数据库引擎放弃索引进行全表扫描

- score是索引,但是使用IS NULL就不会走索引了

```sql
SELECT * FROM t WHERE score IS NULL
```

- 优化方式：可以给字段添加默认值0，对0值进行判断。如下：

```sql
SELECT * FROM t WHERE score = 0
```

## 尽量避免在where条件中`等号的左侧`进行表达式、函数操作，会导致数据库引擎放弃索引进行全表扫描

可以将表达式、函数操作移动到等号右侧。如下：

```sql
-- 全表扫描
SELECT * FROM T WHERE score/10 = 9
-- 走索引
SELECT * FROM T WHERE score = 10*9
```

## 查询条件不能用 <> 或者 !=

- 使用索引列作为条件进行查询时，需要避免使用<>或者!=等判断条件。
- 如确实业务需要，使用到不等于符号，需要在重新评估索引建立，避免在此字段上建立索引，改由查询条件中其他索引字段代替。
- 尽量使用>=这样索引可以**直接命中地址的判断**

## 满足最左前缀的原则

- 如下：复合（联合）索引包含key_part1，key_part2，key_part3三列，但SQL语句没有包含索引前置列"key_part1"，按照MySQL联合索引的最左匹配原则，不会走联合索引。

```sql
select col1 from table where key_part2=1 and key_part3=2
```

## **隐式类型转换造成不使用索引**

- 如下SQL语句由于索引**对列类型为`varchar`，但给定的值为`数值`**，涉及隐式类型转换，造成不能正确走索引。

```sql
select col1 from table where col_varchar=123; 
```

## **order by 条件要与where中条件一致，否则order by不会利用索引进行排序**

- order by字段是索引,并且一定要跟一个where条件

```sql
-- 不走age索引
SELECT * FROM t order by age;

-- 走age索引
SELECT * FROM t where age > 0 order by age;
```