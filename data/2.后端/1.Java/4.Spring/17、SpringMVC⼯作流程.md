# Spring MVC ⼯作流程 

- ⽤户发送请求到Tomcat，Tomcat映射到具体的servlet -> 前端控制器 **DispatcherServlet**。 
- 经过servlet的**init初始化丶service()方法**调用，**子类HttpServlet判断请求类型**(get，post)
- initStrategies初始化策略方法中注册需要的核心组件
  - **上传文件解析器丶语言解析器(国际化)丶处理器映射器丶处理器适配器丶视图解析器**等
  - 设置到请求对象的属性中
  - 在**DispatcherServlet**的`doDispatch`方法内执行**MVC的所有流程**
- DispatcherServlet 收到请求调⽤ **HandlerMapping** 处理器映射器。 
- 处理器映射器找到具体的处理器(注解进⾏查找)，⽣成处理器及处理器拦截器⼀并返回给 DispatcherServlet。 
  - 在MVC这个子容器中找到跟请求对应的Controller
  - **controller层**是SpringMVC容器(IOC的子容器)中加载的
  - Spring的IOC容器启动是不读取**controller层**的,只扫描了@service丶@component这些
- DispatcherServlet 调⽤ **HandlerAdapter** 处理器适配器。 
  - 核心实现类 -> `RequestMappingHandlerAdapter`
  - 参数解析器丶返回类型解析器
  - 参数解析器`RequestParamMethodArgumentResolver` -> `RequestMappingHandlerAdapter`
    - 判断是否支持类型方法丶解析方法
    - 初始化解析器获取可以解析的参数类型 -> 所有的可以使用的参数类型都在这里`@RequestParam`
    - 解析名字丶赋值请求的参数丶类型转换
  - 返回类型解析器`HandlerMethodReturnValueHandler` -> `ViewNameMethodReturnValueHandler`
    - 初始化解析器获取可以返回的类型 -> ModelAndView丶Model丶View丶ResponseBody
    - 具体解析,解析为什么类型啊,是否解析为一个视图类型等
- HandlerAdapter 经过适配调⽤具体的处理器(Controller，也叫后端控制器) 
  - 开始执行Controller的方法
- Controller 执⾏完成返回 **ModelAndView**。 
- HandlerAdapter 将 controller 执⾏结果 ModelAndView 返回给 DispatcherServlet。
- DispatcherServlet 将 ModelAndView 传给 **ViewReslover** 视图解析器。 
- ViewReslover 解析后返回具体 **View**。 
- DispatcherServlet 根据 View 进⾏渲染视图。 
  - 解析成jsp丶HTML丶json丶xml等
- DispatcherServlet **响应⽤户**。 

![2021022601-05-springmvc流程图-详细](../../../picture\2021022601-05-springmvc流程图-详细.png)