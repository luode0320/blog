# ApplicationContext和BeanFactory有什么区别 

> **BeanFactory：**
>
> 是Spring里面最低层的接口，提供了`最简单的容器的功能`，只提供了**⽣成Bean，维护Bean**的功能；

> **ApplicationContext：**
>
> 继承BeanFactory接口，它是Spring的一各`更高级的容器`，提供了更多的有用的功能；

- `获取系统环境变量`、`国际化`、`AOP`等功能，这是BeanFactory所不具备的

**区别:** 

- 我觉得最主要的区别应该是
- BeanFactory每次获取对象时才会创建对象,**不会立即创建**
- ApplicationContext是**启动就将所有Bean对象创建完成**
- 所以ApplicationContext实现的IOC容器`启动慢一点但是系统运行时会更快`

- ApplicationContext像是BeanFactory的**升级版**
- 随着时间推移需要更多的扩展的功能
- 由ApplicationContext接口实现的IOC容器就替换掉了以前实现BeanFactory的IOC容器