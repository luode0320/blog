![image-20241024150302335](../../../picture/image-20241024151910227.png)


# 配置

![image-20241024150302335](../../../picture/image-20241024150302335.png)



**补充新增主链TON流程实例**

1. loadAvailableCoinsList:从文件csv,txt加载币种信息
2. getPair:获取货币对信息
3. getNewEthGasFee:获取新的Gas费用
4. loadCurrencies:定时任务，定期加载货币信息
5. findBaseCurrency:在货币映射中查找基础货币信息
6. getCoinsAllowNew:获取允许的新币种信息
7. createOrder:创建兑换订单的处理方法



## default_coins.csv

excel表格添加币种, 这里是详细信息

![image-20241024150721404](../../../picture/image-20241024150721404.png)

## available_coins.txt

文本是代币可以使用的币种, 最终是从csv中获取所有数据, 然后txt配置的才会允许使用。

![image-20241024150942540](../../../picture/image-20241024150942540.png)



# 代码添加

**![image-20241024151028001](../../../picture/image-20241024151028001.png)**

# 前端显示

![image-20241025103941928](../../../picture/image-20241025103941928.png)

# gas费获取配置

这里配置表示使用最新的go语言写的后台接口调用。

![image-20241024151126041](../../../picture/image-20241024151126041.png)