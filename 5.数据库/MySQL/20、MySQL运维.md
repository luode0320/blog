# MySQL运维

**MySQL启停**

```shell
# 启动
[root@localhost ~]# /etc/init.d/mysqld start
 
# 重启
[root@localhost ~]# /etc/init.d/mysqld restart
```

**全量备份**

```shell
D:\>mysqldump -u platform -h 192.168.14.252 -p123 orcl > d:\orcl.sql
```

**全量恢复**

```shell
D:\>mysql -h 192.168.88.246 -uplatform -p123 orcl < D:\orcl.sql
mysql: [Warning] Using a password on the ``command` `line interface can be insecure.
```

**慢SQL**

```shell

mysql> show variables  like '%slow_query_log%';
+---------------------+----------------------------------+
| Variable_name       | Value                            |
+---------------------+----------------------------------+
| slow_query_log      | OFF                              |
| slow_query_log_file | /data/mysql/data/i--001-slow.log |
+---------------------+----------------------------------+
2 rows in set (0.00 sec)
 
mysql> -- 开启慢SQL记录
mysql> set global slow_query_log=1;
Query OK, 0 rows affected (0.09 sec)
```

