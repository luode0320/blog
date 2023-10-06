# Spring容器启动流程是怎样的 

- 在创建Spring容器，也就是启动Spring时： 
  - 创建`beanFactory `工厂,用来生产Bean
  - 注解读取器,读取那些`@Service丶@Component`注解
    - Spring的IOC容器是不读取**controller层**的
    - **controller层**是SpringMVC容器(IOC的子容器)中加载的
  - 路径扫描器,我们不仅要扫描当前主类包下的,还要扫描一些我们指定路径下的Class文件
  - 还有解析一些配置类,就是`@Configuration`标注的那些Bean
- 之后就是核心的`refresh`容器刷新,refresh方法里面就有好多步骤,注册一些组件
  - `BeanFactory后置处理器` -> BeanFactoryPostProcessor,可以修改BeanDefinition的元数据,比如单例的Bean改成原型
    - boot的自动配置类也在这个阶段加载完成的
  - `Bean后置处理器` -> BeanPostProcessor,这里可以依赖注入丶动态代理，等一下创建Bean要用的
- 把一些用得到的组件加载好
  
- 然后所有的单例Bean进⾏`getBean()`创建，对于多例Bean什么时候用就什么时候创建了

- 接着整个创建Bean的⽣命周期，这期间包括了**推断构造⽅法、实例化、依赖注入、初始化前、初始化、初始化后**，初始化后这里有AOP就生成代理对象,完成后讲Bean对象保存到容器的Map中

-  所有单例Bean创建完了之后

- `finishRefresh()`,最后一次刷新,清理一下缓存(循环依赖三级缓存)丶重置一下事件(标志我完成了)，Spring启动

  

