# Spring⽤到了哪些设计模式 

- Bean的生命周期有几个
  - `BeanFactory` `FactoryBean` -> 工厂模式丶装饰者模式
  - `BeanPostProcessor` -> 责任链模式
  - `AOP` -> 代理模式
  - `事件相关的` -> 观察者模式(发布订阅模式)
- `jdbcTamplate` -> 模板方法模式