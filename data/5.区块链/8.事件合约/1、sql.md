```sql
# 统计星期n的胜率
SELECT 
    CASE 
        WHEN day_of_week = 1 THEN '星期日'
        WHEN day_of_week = 2 THEN '星期一'
        WHEN day_of_week = 3 THEN '星期二'
        WHEN day_of_week = 4 THEN '星期三'
        WHEN day_of_week = 5 THEN '星期四'
        WHEN day_of_week = 6 THEN '星期五'
        WHEN day_of_week = 7 THEN '星期六'
    END AS weekday,
    total_orders,
    AVG(win_rate) * 100 AS avg_win_rate
FROM (
    SELECT 
        DAYOFWEEK(create_time) AS day_of_week,
				COUNT(*) AS total_orders,
        SUM(CASE WHEN order_result = '赢' THEN 1 ELSE 0 END) / COUNT(*) AS win_rate
    FROM 
        orders
    WHERE 
        time_type = '30m'
    GROUP BY 
        DAYOFWEEK(create_time)
) AS daily_win_rates
GROUP BY 
    day_of_week
ORDER BY 
    day_of_week;
    
    
# 每个星期的胜率
SELECT 
    DATE(create_time) AS order_date,
    CASE 
        WHEN DAYOFWEEK(create_time) = 1 THEN '星期日'
        WHEN DAYOFWEEK(create_time) = 2 THEN '星期一'
        WHEN DAYOFWEEK(create_time) = 3 THEN '星期二'
        WHEN DAYOFWEEK(create_time) = 4 THEN '星期三'
        WHEN DAYOFWEEK(create_time) = 5 THEN '星期四'
        WHEN DAYOFWEEK(create_time) = 6 THEN '星期五'
        WHEN DAYOFWEEK(create_time) = 7 THEN '星期六'
    END AS weekday,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN order_result = '赢' THEN 1 ELSE 0 END) / COUNT(*) * 100 AS win_rate_percentage
FROM 
    orders
WHERE 
    time_type = '30m'
GROUP BY 
    DATE(create_time), 
    DAYOFWEEK(create_time)
ORDER BY 
    weekday;
```



```sql
# 时间段胜率
SELECT 
    CASE 
        WHEN HOUR(create_time) BETWEEN 0 AND 7 THEN '0-8点'
        WHEN HOUR(create_time) BETWEEN 8 AND 15 THEN '8-16点'
        WHEN HOUR(create_time) BETWEEN 16 AND 23 THEN '16-24点'
    END AS time_period,
    COUNT(*) AS total_orders,
    ROUND(AVG(CASE WHEN order_result = '赢' THEN 1 ELSE 0 END) * 100, 2) AS avg_win_rate_percentage
FROM 
    orders
WHERE 
    time_type = '30m'
GROUP BY 
    time_period
ORDER BY 
    CASE 
        WHEN time_period = '0-8点' THEN 1
        WHEN time_period = '8-16点' THEN 2
        WHEN time_period = '16-24点' THEN 3
    END;
    
# 
SELECT 
    CASE 
        WHEN HOUR(create_time) BETWEEN 0 AND 3 THEN '0-4点'
        WHEN HOUR(create_time) BETWEEN 4 AND 7 THEN '4-8点'
        WHEN HOUR(create_time) BETWEEN 8 AND 11 THEN '8-12点'
        WHEN HOUR(create_time) BETWEEN 12 AND 15 THEN '12-16点'
        WHEN HOUR(create_time) BETWEEN 16 AND 19 THEN '16-20点'
        WHEN HOUR(create_time) BETWEEN 20 AND 23 THEN '20-24点'
    END AS time_period,
    COUNT(*) AS total_orders,
    ROUND(AVG(CASE WHEN order_result = '赢' THEN 1 ELSE 0 END) * 100, 2) AS avg_win_rate_percentage
FROM 
    orders
WHERE 
    time_type = '30m'
GROUP BY 
    time_period
ORDER BY 
    CASE 
        WHEN time_period = '0-4点' THEN 1
        WHEN time_period = '4-8点' THEN 2
        WHEN time_period = '8-12点' THEN 3
        WHEN time_period = '12-16点' THEN 4
        WHEN time_period = '16-20点' THEN 5
        WHEN time_period = '20-24点' THEN 6
    END;


SELECT 
    HOUR(create_time) AS hour_of_day,
    CONCAT(HOUR(create_time), ':00-', HOUR(create_time)+1, ':00') AS time_period,
    COUNT(*) AS '下单数',
    ROUND(AVG(CASE WHEN order_result = '赢' THEN 1 ELSE 0 END) * 100, 2) AS '平均胜率'
FROM 
    orders
WHERE 
    time_type = '30m'
GROUP BY 
    hour_of_day
ORDER BY 
    hour_of_day;
    
# 10分钟30分钟间隔
SELECT 
    CONCAT(
        LPAD(HOUR(create_time), 2, '0'), 
        ':', 
        IF(MINUTE(create_time) < 30, '00', '30'), 
        '-', 
        LPAD(
            CASE 
                WHEN MINUTE(create_time) < 30 THEN HOUR(create_time)
                ELSE HOUR(create_time) + 1
            END, 2, '0'
        ), 
        ':', 
        IF(MINUTE(create_time) < 30, '30', '00')
    ) AS '时间段',
    COUNT(*) AS '下单数',
    ROUND(AVG(CASE WHEN order_result = '赢' THEN 1 ELSE 0 END) * 100, 2) AS '平均胜率(%)'
FROM 
    orders
WHERE 
    time_type = '30m'
GROUP BY 
    HOUR(create_time),
    CASE WHEN MINUTE(create_time) < 30 THEN 0 ELSE 1 END
ORDER BY 
    AVG(CASE WHEN order_result = '赢' THEN 1 ELSE 0 END) DESC,  -- 按实际数值排序
    HOUR(create_time),
    CASE WHEN MINUTE(create_time) < 30 THEN 0 ELSE 1 END;
    
    
SELECT 
    CONCAT(
        LPAD(HOUR(create_time), 2, '0'), 
        ':00-', 
        LPAD(MOD(HOUR(create_time) + 1, 24), 2, '0'), 
        ':00'
    ) AS '时间段',
    COUNT(*) AS '下单数',
    ROUND(AVG(CASE WHEN order_result = '赢' THEN 1 ELSE 0 END) * 100, 2) AS '平均胜率(%)'
FROM 
    orders
WHERE 
    time_type = '30m'
GROUP BY 
    HOUR(create_time)
ORDER BY 
    `平均胜率(%)` DESC,  -- 按胜率降序排列
    HOUR(create_time);
18:00-19:00	32	71.88
02:00-03:00	26	69.23
01:00-02:00	27	66.67
08:00-09:00	30	66.67
04:00-05:00	25	64.00
10:00-11:00	33	63.64
09:00-10:00	31	61.29

06:00-07:00	21	42.86
07:00-08:00	28	39.29
21:00-22:00	51	35.29
    
```

```
# 胜率
SELECT 
    COUNT(*) AS total_orders,
    SUM(CASE WHEN order_result = '赢' THEN 1 ELSE 0 END) AS winning_orders,
    ROUND(
        (SUM(CASE WHEN order_result = '赢' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)),
        2
    ) AS win_rate_percentage
FROM 
    orders
WHERE 
    time_type = '1h' 
    AND order_type = '多';
```

