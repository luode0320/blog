# Spring MVC的主要组件？ 

> DispatcherServlet：前端控制器

- 主要负责捕获来自**客户端的请求和调度各个组件**。
- DispatcherServlet其实不是组件,只是调度的,核心的组件在这个类的init方法里面

```java
//初始化此servlet使用的策略对象。
protected void initStrategies(ApplicationContext context) {
    //初始化上传文件解析器
    initMultipartResolver(context);
    //初始化语言环境解析器 -> 国际化相关
    initLocaleResolver(context);
    //初始化主题解析器 -> css这类的类似样式的东西解析
    initThemeResolver(context);
    //初始化处理程序映射
    initHandlerMappings(context);
    //初始化处理程序适配器
    initHandlerAdapters(context);
    //初始化处理程序异常解析器
    initHandlerExceptionResolvers(context);
    //初始化请求视图名称转换器
    initRequestToViewNameTranslator(context);
    //初始化视图解析器
    initViewResolvers(context);
    //初始化 Flash 管理器
    initFlashMapManager(context);
}
```

- 一共9个

**几个比较重要的概念**

> HandlerMapping 

- `initHandlerMappings`，处理器映射器，根据⽤户请求的资源uri来查找Handler的。
- 在 SpringMVC中会有很多请求，**每个请求都需要⼀个Handler处理**
- 具体接收到⼀个请求之后使⽤哪个Handler进⾏，这就是HandlerMapping需要做的事。

> HandlerAdapter 

- `initHandlerAdapters`，适配器。
- 因为SpringMVC中的Handler可以是任意的形式，**只要能处理请求就ok**，但是Servlet需要的处理⽅法的结构却是固定的，都是以`request和response`为参数的⽅法。 

- 如何让固定的Servlet处理⽅法调⽤灵活的Handler来进⾏处理呢？
- 这就是HandlerAdapter要做的事情。 

> Handler：也就是处理器。

- 它直接应对着MVC中的C也就是**Controller层**，它的具体表现形式有很多，`可以是类，也可以是⽅法`。
- 在Controller层中`@RequestMapping`标注的**所有⽅法都可以看成是⼀个Handler**，只要可以实际处理请求就可以是Handler 

> HandlerExceptionResolver 

- `initHandlerExceptionResolvers`， 其它组件都是⽤来⼲活的。
- 在⼲活的过程中难免会出现问题，出问题后怎么办呢？
- 这就需要有⼀个专⻔的⻆⾊对**异常情况进⾏处理**
- 在SpringMVC中就是HandlerExceptionResolver。
- 具体来说，此组件的作⽤是**根据异常设置ModelAndView**，之后再交给 render⽅法进⾏渲染。
  - 出错404

> ViewResolver 

- `initViewResolvers`，ViewResolver⽤来将String类型的视图名和Locale解析为View类型的视 

图

- View是⽤来渲染⻚⾯的，也就是将程序返回的参数填⼊模板⾥，⽣成html（也可能是其它类型）⽂ 

件。

- 这⾥就有两个关键问题：**使⽤哪个模板？**
  - ⽤什么技术（规则）填⼊参数？这其实是ViewResolver主要要做的⼯作
  - ViewResolver需要找到**渲染所⽤的模板和所⽤的技术**（也就是视图的类型）进⾏渲染， 

- 具体的渲染过程则交由不同的视图⾃⼰完成。

  