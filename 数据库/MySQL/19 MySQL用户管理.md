# MySQL用户管理

**创建用户并授权**

```shell
mysql> CREATE USER 'platform'@'%' IDENTIFIED BY '123';
Query OK, 0 rows affected (0.01 sec)
 
mysql> grant ALL PRIVILEGES  ON orcl.* to 'platform'@'%';
Query OK, 0 rows affected, 1 warning (0.02 sec)
 
mysql> flush privileges;
Query OK, 0 rows affected (0.00 sec)
 
 
mysql> show grants for 'platform'@'%';
+------------------------------------------------------------+
| Grants for platform@localhost                              |
+------------------------------------------------------------+
| GRANT USAGE ON *.* TO 'platform'@'%'                       |
| GRANT ALL PRIVILEGES ON `orcl`.* TO 'platform'@'%'         |
+------------------------------------------------------------+
2 rows in set (0.00 sec)
```

**删除用户**

```shell
mysql> drop user platform@%;
Query OK, 0 rows affected (0.00 sec)
```

**查询用户**

```shell
mysql> use mysql
Database changed
mysql> select host, user from user;
+-----------+-----------+
| host      | user      |
+-----------+-----------+
| %         | platform  |
| %         | root      |
| localhost | mysql.sys |
+-----------+-----------+
3 rows in set (0.00 sec)
```

**修改用户密码**

```shell
mysql> use mysql
Database changed
mysql>update user set password=PASSWORD('123456') where User='root';
Query OK, 1 row affected (0.06 sec)
Rows matched: 1  Changed: 1  Warnings: 0
```

