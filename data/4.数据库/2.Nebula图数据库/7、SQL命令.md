# 收集一些常用的命令

## space空间

```sh
# 创建一个空间
CREATE SPACE IF NOT EXISTS spaceName(vid_type=FIXED_STRING(64));
```

## vertex点

```sh
# 创建一个点
CREATE TAG IF NOT EXISTS SDK_STRUCT(
    client_id string,
    chain_key string,
    parent_key string,
    channel_name string,
    chain_name string,
    data_type_name string,
    tx_id string,
    create_time string,
    chain_code string,
    content_json string,
    value_hash string,
    is_status string
);

# 查询所有点
SHOW TAGS;

# 查询一个点的属性
DESCRIBE TAG SDK_STRUCT;

# 插入一个点 
# insert vertex {{.Name}}({{.Keys}}) values {{.Vid}}:({{.Values}})
insert vertex sdk_vertex(data_type_name,tx_id,create_time,client_id,chain_key,parent_key,channel_name,chain_name) values 'F4AB3E1CC840B86DB172EDFAD2F6946FC6609BF19864ABBB22C1DD869515818F':('测试','dc360f48e8baefc552a165ec1b15b77afd288d7476858696d2999851e9b301a3','2024-04-11 11:54:22','666','F4AB3E1CC840B86DB172EDFAD2F6946FC6609BF19864ABBB22C1DD869515818F','0','luodechannel','luodecc')

# 查询所有顶点
MATCH(v) RETURN v limit 10;

# 执行计划 PROFILE SQL
PROFILE MATCH(v) RETURN v limit 10;

# MATCH 查询路径
MATCH p=(v)<-[:connect*1..3]-(n) 
WHERE id(n)=='FAA158F8E1AC55919FFCB409D1B495CBE7DD99EEA804AE4EA2A155F648579E65' 
return v.sdk_struct.client_id as client_id,v.sdk_struct.chain_key as chain_key,v.sdk_struct.parent_key as parent_key,v.sdk_struct.channel_name as channel_name,v.sdk_struct.chain_name as chain_name,v.sdk_struct.data_type_name as data_type_name,v.sdk_struct.tx_id as tx_id,v.sdk_struct.create_time as create_time,v.sdk_struct.chain_code as chain_code,v.sdk_struct.content_json as content_json,v.sdk_struct.value_hash as value_hash,v.sdk_struct.is_status as is_status

# FIND 查询路径
FIND ALL PATH FROM "FAA158F8E1AC55919FFCB409D1B495CBE7DD1EB1B939E15AC1CD22819938B924" TO "FAA158F8E1AC55919FFCB409D1B495CBE7DD5F81A864691EB1FD068A542F0AAF" 
OVER * 
YIELD path AS p;

# GET SUBGRAPH 查询路径(默认双向) : YIELD $^(起点) YIELD $$(终点)
GET SUBGRAPH 1 STEPS FROM "FAA158F8EC14A3359D12173DCE2A11EB989D2D3DEF8B34F52BE2A12ACB54A0E5" 
YIELD VERTICES AS nodes, 
EDGES AS relationships;

```

## edge边

```sh
# 创建一个边
CREATE EDGE IF NOT EXISTS connect(likeness String);

# 查询所有边
SHOW EDGES;

# 查询一个边的类型属性
DESCRIBE EDGE connect;

# 插入一条边
# insert edge {{.Name}}({{.Keys}}) values {{.Src}} -> {{.Dst}}:({{.Values}})
insert edge connect(likeness) values 'F4AB3E1CC840B86DB172EDFAD2F6946FC6609BF19864ABBB22C1DD869515818F' -> 'AF4AB3E1CC840B86DB172EDFAD2F6946FC6609BF19864ABBB22C1DD869515818':('AF4AB3E1CC840B86DB172E
DFAD2F6946FC6609BF19864ABBB22C1DD869515818')

# 查询所有边
MATCH ()-[e]->() RETURN e LIMIT 10;

# 查询某条边
FETCH PROP ON json_edge '0' -> '测试节点1' YIELD properties(edge)
```



