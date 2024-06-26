> 在一个图空间中，一个点由点的 ID 唯一标识，即 VID 或 Vertex ID。

## VID 的特点

- VID 数据类型只可以为定长字符串`FIXED_STRING(<N>)`或`INT64`。一个图空间只能选用其中一种 VID 类型。

- VID 在一个图空间中必须唯一，其作用类似于关系型数据库中的主键（索引+唯一约束）。但不同图空间中的 VID 是完全独立无关的。

- 点 VID 的生成方式必须由用户自行指定，系统不提供自增 ID 或者 UUID。

- VID 相同的点，会被认为是同一个点。例如：

    - VID 相当于一个实体的唯一标号，
    - 例如一个人的身份证号。
        - Tag 相当于实体所拥有的类型，例如"滴滴司机"和"老板"。
        - 不同的 Tag 又相应定义了两组不同的属性，例如"驾照号、驾龄、接单量、接单小号"和"工号、薪水、债务额度、商务电话"。

    - 同时操作相同 VID 并且相同 Tag 的两条`INSERT`语句（均无`IF NOT EXISTS`参数），晚写入的`INSERT`会覆盖先写入的。

    - 同时操作包含相同 VID 但是两个不同`TAG A`和`TAG B`的两条`INSERT`语句，对`TAG A`的操作不会影响`TAG B`。

- VID 通常会被（LSM-tree 方式）索引并缓存在内存中，因此直接访问 VID 的性能最高。

## VID 使用建议

- NebulaGraph 1.x 只支持 VID 类型为`INT64`，从 2.x 开始支持`INT64`和`FIXED_STRING(<N>)`。在`CREATE SPACE`
  中通过参数`vid_type`可以指定 VID 类型。

- 可以使用`id()`函数，指定或引用该点的 VID。

- 可以使用`LOOKUP`或者`MATCH`语句，来通过属性索引查找对应的 VID(搜索会影响效率)。

- 性能上，直接通过 VID 找到点的语句性能最高
    - 例如`DELETE xxx WHERE id(xxx) == "player100"`，或者`GO FROM "player100"`等语句。
- 通过属性先查找 VID，再进行图操作的性能会变差
    - 例如`LOOKUP | GO FROM $-.ids`等语句，相比前者多了一次内存或硬盘的随机读（`LOOKUP`）以及一次序列化（`|`）。

## VID 生成建议

VID 的生成工作完全交给应用端，有一些通用的建议：

- （最优）通过有唯一性的主键或者属性来直接作为 VID；属性访问依赖于 VID;

- 通过有唯一性的属性组合来生成 VID，属性访问依赖于属性索引。

- 通过 snowflake 等算法生成 VID，属性访问依赖于属性索引。

- 如果个别记录的主键特别长，但绝大多数记录的主键都很短的情况，不要将`FIXED_STRING(<N>)`的`N`设置成超大，这会浪费大量内存和硬盘，也会降低性能。此时可通过
  BASE64，MD5，hash 编码加拼接的方式来生成。

- 如果用 hash 方式生成 int64 VID：在有 10 亿个点的情况下，发生 hash 冲突的概率大约是 1/10。边的数量与碰撞的概率无关。

## 定义和修改 VID 与其数据类型

VID 的数据类型必须在[创建图空间](https://docs.nebula-graph.com.cn/3.8.0/3.ngql-guide/9.space-statements/1.create-space/)
时定义，且一旦定义无法修改。

VID 必须在[插入点](https://docs.nebula-graph.com.cn/3.8.0/3.ngql-guide/12.vertex-statements/1.insert-vertex/)
时设置，且一旦设置无法修改。

## 查询起始点"(`start vid`) 与全局扫描

绝大多数情况下，NebulaGraph 的查询语句（`MATCH`、`GO`、`LOOKUP`）的执行计划，必须要通过一定方式找到查询起始点的
VID（`start vid`）。

定位 `start vid` 只有两种方式：

- 例如 `GO FROM "player100" OVER` 是在语句中显式的指明 `start vid` 是 "player100"；

- 例如 `LOOKUP ON player WHERE player.name == "Tony Parker"` 或者 `MATCH (v:player {name:"Tony Parker"})`
    - 通过属性 `player.name` 的索引来定位到 `start vid`(影响效率)；

