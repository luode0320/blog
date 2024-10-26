# Spring Boot、Spring MVC 和 Spring 有什么区别

Spring 实际上是一个框架，它包括很多东西

- Spring AOP
- Spring JDBC
- Spring MVC
- Spring ORM

> Spring 如果单独拿出来说的话是⼀个IOC容器，⽤来管理Bean

- 使⽤**依赖注⼊实现控制反转**，可以很⽅便的整合各种框架
- **提供AOP机制**更⽅便将不同类不同⽅法中的做增强

> Spring MVC是Spring 对web框架的⼀个解决⽅案

- 提供了⼀个总的前端控制器Servlet，⽤来接收请求丶分析请求，将URL适配丶映射到到我们写的Controller接口上，将处理结果使用`视图解析技术`什么的展示给前端 

> Spring Boot算是Spring 提供的⼀个整合了Spring 和Spring MVC的快速开发⼯具包

- 所谓的开箱即⽤ 
- 简化了配置，整合了⼀系列的解决⽅案，能更⽅便、更快速的去开发