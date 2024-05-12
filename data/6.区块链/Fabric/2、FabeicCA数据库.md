# 数据库

Fabric-CA 是 Hyperledger Fabric 中的一个组件，用于管理证书和身份验证。它使用数据库来存储和管理证书和身份验证相关的数据。以下是 Fabric-CA 中的七个表格及其含义：

1. affiliations：该表格存储了组织和子组织之间的从属关系。每个组织都有一个唯一的名称和一个可选的父组织名称。该表格用于管理组织和子组织之间的关系。
2. certificates：该表格存储了证书相关的信息，包括证书的序列号、颁发者、主题、公钥、有效期等。该表格用于管理证书的颁发和撤销。
3. credentials：该表格存储了用户的凭证信息，包括用户名、密码、角色等。该表格用于管理用户的身份验证。
4. nonces：该表格存储了用于防止重放攻击的随机数。每个随机数只能使用一次，用于验证请求的唯一性。该表格用于管理随机数。
5. properties：该表格存储了 Fabric-CA 的配置信息，包括证书颁发策略、证书撤销策略、证书有效期等。该表格用于管理 Fabric-CA 的配置。
6. revocation_authority_info：该表格存储了证书撤销机构的信息，包括名称、公钥、私钥等。该表格用于管理证书撤销机构的信息。
7. users：该表格存储了用户的信息，包括用户名、密码、角色、证书等。该表格用于管理用户的身份验证和证书。

这些表格共同构成了 Fabric-CA 的数据库，用于存储和管理证书和身份验证相关的数据。

```sql
CREATE TABLE `certificates` (
  `id` varchar(255) COLLATE utf8_bin DEFAULT NULL, -- 证书的唯一标识符，通常是证书的 SHA256 哈希值。
  `serial_number` varbinary(128) NOT NULL, -- 证书的序列号，用于唯一标识证书。
  `authority_key_identifier` varbinary(128) NOT NULL, -- 证书颁发者的公钥标识符，用于唯一标识证书颁发者。
  `ca_label` varbinary(128) DEFAULT NULL, -- 证书颁发者的标签，用于标识证书颁发者所属的 CA。
  `status` varbinary(128) NOT NULL, -- 证书的状态，可以是 `good`（有效）、`revoked`（已撤销）或 `expired`（已过期）。
  `reason` int(11) DEFAULT NULL, -- 证书被撤销的原因代码，可以是 `unspecified`（未指定）、`keyCompromise`（密钥泄露）、`CACompromise`（CA 泄露）、`affiliationChanged`（从属关系变更）、`superseded`（被替代）、`cessationOfOperation`（停止运营）或 `certificateHold`（暂停证书）。
  `expiry` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00', -- 证书的过期时间，用于判断证书是否过期。
  `revoked_at` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00', -- 证书被撤销的时间，用于记录证书的撤销时间。
  `pem` varbinary(4096) NOT NULL, -- 证书的 PEM 编码格式，用于存储证书的内容。
  `level` int(11) DEFAULT '0', -- 证书的级别，用于标识证书的类型，可以是 `0`（根证书）、`1`（中间证书）或 `2`（终端证书）。
  PRIMARY KEY (`serial_number`,`authority_key_identifier`) -- 将 `serial_number` 和 `authority_key_identifier` 两个字段作为主键。
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin; -- 使用 InnoDB 引擎，字符集为 utf8，排序规则为 utf8_bin。

```

```sql
CREATE TABLE `credentials` (
  `id` varchar(255) COLLATE utf8_bin DEFAULT NULL, -- 凭证的唯一标识符，通常是凭证的 SHA256 哈希值。
  `revocation_handle` varbinary(128) NOT NULL, -- 凭证的撤销句柄，用于唯一标识凭证的撤销状态。
  `cred` varbinary(4096) NOT NULL, -- 凭证的内容，通常是一个 JSON 格式的字符串。
  `ca_label` varbinary(128) DEFAULT NULL, -- 凭证颁发者的标签，用于标识凭证颁发者所属的 CA。
  `status` varbinary(128) NOT NULL, -- 凭证的状态，可以是 `active`（有效）或 `revoked`（已撤销）。
  `reason` int(11) DEFAULT NULL, -- 凭证被撤销的原因代码，可以是 `unspecified`（未指定）、`keyCompromise`（密钥泄露）、`CACompromise`（CA 泄露）、`affiliationChanged`（从属关系变更）、`superseded`（被替代）、`cessationOfOperation`（停止运营）或 `certificateHold`（暂停凭证）。
  `expiry` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00', -- 凭证的过期时间，用于判断凭证是否过期。
  `revoked_at` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00', -- 凭证被撤销的时间，用于记录凭证的撤销时间。
  `level` int(11) DEFAULT '0', -- 凭证的级别，用于标识凭证的类型，可以是 `0`（根凭证）、`1`（中间凭证）或 `2`（终端凭证）。
  PRIMARY KEY (`revocation_handle`) -- 将 `revocation_handle` 字段作为主键。
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin; -- 使用 InnoDB 引擎，字符集为 utf8，排序规则为 utf8_bin。

```

```sql
CREATE TABLE `properties` (
  `property` varchar(255) COLLATE utf8_bin NOT NULL, -- 属性的名称，用于标识属性。
  `value` varchar(256) COLLATE utf8_bin DEFAULT NULL, -- 属性的值，用于存储属性的内容。
  PRIMARY KEY (`property`) -- 将 `property` 字段作为主键。
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin; -- 使用 InnoDB 引擎，字符集为 utf8，排序规则为 utf8_bin。
```

```sql
CREATE TABLE `users` (
  `id` varchar(255) COLLATE utf8_bin NOT NULL, -- 用户的唯一标识符，通常是用户的用户名。
  `token` blob, -- 用户的令牌，用于身份验证。
  `type` varchar(256) COLLATE utf8_bin DEFAULT NULL, -- 用户的类型，可以是 `client`（客户端用户）或 `peer`（节点用户）。
  `affiliation` varchar(1024) COLLATE utf8_bin DEFAULT NULL, -- 用户所属的从属关系，用于管理用户的组织关系。
  `attributes` text COLLATE utf8_bin, -- 用户的属性，通常是一个 JSON 格式的字符串。
  `state` int(11) DEFAULT NULL, -- 用户的状态，可以是 `0`（正常）或 `1`（已禁用）。
  `max_enrollments` int(11) DEFAULT NULL, -- 用户的最大注册次数，用于限制用户的注册次数。
  `level` int(11) DEFAULT '0', -- 用户的级别，用于标识用户的类型，可以是 `0`（根用户）、`1`（中间用户）或 `2`（终端用户）。
  `incorrect_password_attempts` int(11) DEFAULT '0', -- 用户的密码错误次数，用于限制用户的登录次数。
  PRIMARY KEY (`id`) -- 将 `id` 字段作为主键。
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin; -- 使用 InnoDB 引擎，字符集为 utf8，排序规则为 utf8_bin。
```

```sql
CREATE TABLE `revocation_authority_info` (
  `epoch` int(11) NOT NULL, -- 撤销机构的时期，用于标识撤销机构的版本。
  `next_handle` int(11) DEFAULT NULL, -- 下一个可用的撤销句柄，用于唯一标识撤销状态。
  `lasthandle_in_pool` int(11) DEFAULT NULL, -- 撤销池中最后一个撤销句柄，用于管理撤销池的大小。
  `level` int(11) DEFAULT '0', -- 撤销机构的级别，用于标识撤销机构的类型，可以是 `0`（根撤销机构）、`1`（中间撤销机构）或 `2`（终端撤销机构）。
  PRIMARY KEY (`epoch`) -- 将 `epoch` 字段作为主键。
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin; -- 使用 InnoDB 引擎，字符集为 utf8，排序规则为 utf8_bin。
```
