# 写完我自己都看得头大了

![在这里插入图片描述](../../../picture\20201104210411999.png)

> 1.SpringBoot项目的启动类

```java
public static void main(String[] args) {
    SpringApplication.run(Application.class, args);
}
```

> 2.run方法

```Java
//可配置的应用程序上下文,传入 启动类的class 和 启动参数
public static ConfigurableApplicationContext run(Class<?> primarySource, String... args) {
    return run(new Class[]{primarySource}, args);
}
//new Spring上下文，传入我们的class
public static ConfigurableApplicationContext run(Class<?>[] primarySources, String[] args) {
    return (new SpringApplication(primarySources)).run(args);
}
```

- `new SpringApplication(primarySources)`

  - 这里主要是判断应用是不是嵌入式tomcat应用程序丶加载`META-INF/spring.factories`
  - 自动配置一些引导类接口的实现类丶应用程序上下文初始化接口的实现类丶监听器接口的实现类

  ```Java
  public SpringApplication(Class<?>... primarySources) {
      //参数：资源加载器(默认null) 我们自己的Spring启动类class
      this((ResourceLoader)null, primarySources);
  }
  
  public SpringApplication(ResourceLoader resourceLoader, Class<?>... primarySources) {
      //定义一个资源的容器 -> 空set
      this.sources = new LinkedHashSet();
      this.bannerMode = Mode.CONSOLE;
      //记录启动信息
      this.logStartupInfo = true;
      //添加命令行属性
      this.addCommandLineProperties = true;
      //添加转换服务
      this.addConversionService = true;
      this.headless = true;
      this.registerShutdownHook = true;
      //附加配置文件 -> 现在是一个空的set
      this.additionalProfiles = Collections.emptySet();
      //是否自定义环境
      this.isCustomEnvironment = false;
      //是否惰性初始化
      this.lazyInitialization = false;
      //应用上下文工厂 -> 这是一个lambda表达式的函数，还没有执行，判断网络应用程序的，下面有说
      this.applicationContextFactory = ApplicationContextFactory.DEFAULT;
      //应用程序启动 -> 里面new了一个默认new DefaultApplicationStartup()
      this.applicationStartup = ApplicationStartup.DEFAULT;
      //资源加载器 -> 这是我们的参数 -> (ResourceLoader)null
      this.resourceLoader = resourceLoader;
      //断言 -> 主要资源 不能为空 -> 主要资源就是我们传入的的Spring启动类的class,Application.class
      Assert.notNull(primarySources, "PrimarySources must not be null");
      //将Application.class加入主要资源的set集合，当前只有我们一个class
      this.primarySources = new LinkedHashSet(Arrays.asList(primarySources));
      //网络应用程序类型 -> 得到这是一个嵌入式tomcat应用程序，还是响应式应用程序，还是什么都不是
      //我们设置是嵌入式tomcat应用程序
      this.webApplicationType = WebApplicationType.deduceFromClasspath();
      //获取引导器 -> BootstrapRegistryInitializer接口的实现类（引导注册表初始化程序）：看下面补充
      //去 META-INF/spring.factories 文件中找 org.springframework.boot.Bootstrapper
      //路径：classpath → spring-beans → boot-devtools → springboot → boot-autoconfigure
      this.bootstrapRegistryInitializers = new ArrayList(this.getSpringFactoriesInstances(BootstrapRegistryInitializer.class));
  	//设置初始化器 -> 应用程序上下文初始化器：看下面补充
      //spring.factories 文件中找ApplicationContextInitializer接口的实现类
       this.setInitializers(
           this.getSpringFactoriesInstances(ApplicationContextInitializer.class)
       );
      //设置监听器 -> spring.factories文件中找ApplicationListener接口的实现类：看下面补充
      this.setListeners(this.getSpringFactoriesInstances(ApplicationListener.class));
      //推导出主要应用类 -> 我们的启动类的main方法是哪一个
      this.mainApplicationClass = this.deduceMainApplicationClass();
  }
  ```

- 补充

  ```java
  this.bootstrappers：
  空列表
  
  this.initializers：共7个
  	//委派应用程序上下文初始化器
  	DelegatingApplicationContextInitializer
      //共享元数据读取器工厂上下文初始化器
      SharedMetadataReaderFactoryContextInitializer
      //上下文 ID 应用程序上下文初始化器
      ContextIdApplicationContextInitializer
      //配置警告应用程序上下文初始化器
      ConfigurationWarningsApplicationContextInitializer
      //套接字端口信息应用程序上下文初始化器
      RSocketPortInfoApplicationContextInitializer
      //服务器端口信息应用程序上下文初始化器
      ServerPortInfoApplicationContextInitializer
      //条件评估报告记录监听器
      ConditionEvaluationReportLoggingListener
      //重启作用域初始化器
      RestartScopeInitializer
      
  this.listeners：共10个
      //环境后处理器应用程序侦听器
      EnvironmentPostProcessorApplicationListener
      //输出应用监听器
      AnsiOutputApplicationListener
      //记录应用程序侦听器
      LoggingApplicationListener
      //后台预初始化器
      BackgroundPreinitializer
      //委派应用程序侦听器
      DelegatingApplicationListener
      //父上下文关闭器应用程序侦听器
      ParentContextCloserApplicationListener
      //清除缓存应用程序侦听器
      ClearCachesApplicationListener
      //文件编码应用程序监听器
      FileEncodingApplicationListener
      //重新开始应用程序监听器
      RestartApplicationListener
      //开发工具日志工厂监听器
      DevToolsLogFactoryListener
  ```

- `(new SpringApplication(primarySources)).run(args)` -> 下面是`run()`

  ```java
  public ConfigurableApplicationContext run(String... args) {
  	//返回正在运行的 Java 虚拟机的时间源当前值，以纳秒为单位,测量一些代码需要多长时间执行
      long startTime = System.nanoTime();
      //创建引导上下文 -> 上面才加载了Bootstrap的所有引导实现类(但是是0个哈哈)，用了再说
      DefaultBootstrapContext bootstrapContext = this.createBootstrapContext();
      //配置的应用程序上下文
      ConfigurableApplicationContext context = null;
      //设置系统参数 -> java.awt.headless：缺少键盘或鼠标这些外设的情况下使用该模式，Linux服务器
      this.configureHeadlessProperty();
      //获取Spring应用程序运行监听器 -> spring.factories文件SpringApplicationRunListener实现类
      SpringApplicationRunListeners listeners = this.getRunListeners(args);
      //开始监听 -> 开启所有监听器类
      listeners.starting(bootstrapContext, this.mainApplicationClass);
  
      try {
          //默认应用程序参数 -> 获取所有的命令行参数
          ApplicationArguments applicationArguments = new DefaultApplicationArguments(args);
          //准备环境 -> 根据当前应用的类型创建环境应用 Servlet 环境（嵌入式tomcat）等
          ConfigurableEnvironment environment = this.prepareEnvironment(listeners, bootstrapContext, applicationArguments);
          //配置忽略的 bean，保证某些bean不会添加到准备环境中
          this.configureIgnoreBeanInfo(environment);
          //打印横幅，就是Spring的哪个开始的图像信息，没啥用
          Banner printedBanner = this.printBanner(environment);
          //创建应用程序上下文，创建 IOC 容器 -> 从这里开始就是重灾区了
          //单独拿出来说 -> 可以去下面我单独分析的
          context = this.createApplicationContext();
          //设置应用程序启动
          context.setApplicationStartup(this.applicationStartup);
          //准备上下文
          this.prepareContext(bootstrapContext, context, environment, listeners, applicationArguments, printedBanner);
          //刷新上下文 -> 究极重灾区，Bean的生命周期丶SpringBoot自动配置丶Tomcat启动
          //单独拿出来说 -> 可以去下面我单独分析的
          this.refreshContext(context);
          this.afterRefresh(context, applicationArguments);
  }
  ```
  
  

> `createApplicationContext()` -> 创建应用程序上下文，创建 IOC 容器

```java
protected ConfigurableApplicationContext createApplicationContext() {
    //这里会调用实现类的create -> webApplicationType就是一直说到的嵌入式tocmat
    //applicationContextFactory我们在最开始的new SpringApplication(primarySources)这里见过
    //应用上下文工厂 -> 这是一个lambda表达式的函数，还没有执行，判断网络应用程序的
    //this.applicationContextFactory = ApplicationContextFactory.DEFAULT;
    //这里create就要执行lambda表达式 -> ApplicationContextFactory
    return this.applicationContextFactory.create(this.webApplicationType);
}
//ApplicationContextFactory的lambda表达式贴出来
ApplicationContextFactory DEFAULT = (webApplicationType) -> {
    switch (webApplicationType) {
        case SERVLET:
            //我们走这边 -> 我们是嵌入式tomcat，因为tomcat启动也是一个常问的
            //注解配置Servlet web服务器应用程序上下文
            //这也 也要简单讲，看下面
            return new AnnotationConfigServletWebServerApplicationContext();
        case REACTIVE:
            //响应式
            return new AnnotationConfigReactiveWebServerApplicationContext();
        default:
            //默认啥都没有
            return new AnnotationConfigApplicationContext();
};

//new AnnotationConfigServletWebServerApplicationContext();
//这个构造方法执行前，有它的父类先构造，父类中构造了BeanFactory -> 下面
public AnnotationConfigServletWebServerApplicationContext() {
    //注释类 -> 空的set
    this.annotatedClasses = new LinkedHashSet();
    //用来控制`@Scope丶@Autowired丶@Resource丶@Qualifier`这些
    //还没有扫，先注册工具
    this.reader = new AnnotatedBeanDefinitionReader(this);
    //扫描包下所有类，并将符合过滤条件的类注册到IOC容器内 -> 还没有扫，先注册工具
    //控制这些@Service @Controller @Repostory @Component
    this.scanner = new ClassPathBeanDefinitionScanner(this);
}

//AnnotationConfigServletWebServerApplicationContext的父类
public GenericApplicationContext() {
    this.customClassLoader = false;
    this.refreshed = new AtomicBoolean();
    //构造了BeanFactory -> 下面
    this.beanFactory = new DefaultListableBeanFactory();
}
//来了默认的BeanFactory -> 这里面都是一些保存Bean信息的list丶map
public DefaultListableBeanFactory() {
    //autowire 候选解析器
    this.autowireCandidateResolver = SimpleAutowireCandidateResolver.INSTANCE;
    //可解析的依赖项 -> 此时为空，之后肯定会把依赖扫描put到这个map中
    this.resolvableDependencies = new ConcurrentHashMap(16);
    //bean 定义容器 -> 保存beanDefinition的map -> 此时为空，但是Bean要创建肯定从这里面拿的
    this.beanDefinitionMap = new ConcurrentHashMap(256);
    //合并的 Bean 定义持有者
    this.mergedBeanDefinitionHolders = new ConcurrentHashMap(256);
    //所有 Bean 名称（按类型） -> 我们getBean用类型查找肯定从这里面的map拿了
    this.allBeanNamesByType = new ConcurrentHashMap(64);
    //单例 Bean 名称（按类型） -> 单例的getBean用类型查找
    this.singletonBeanNamesByType = new ConcurrentHashMap(64);
    //beanDefinition名称 -> 也是一个保存的
    this.beanDefinitionNames = new ArrayList(256);
    //手动单例名称
    this.manualSingletonNames = new LinkedHashSet(16);
    //思路要跟上啊 -> 回去上面去
}
```

- 跟上思路，创建应用程序上下文完成了，IOC容器初始化了，下面要把Bean加进去了，回到上面`run()`去

> `refreshContext(context)` -> 刷新上下文

```java
private void refreshContext(ConfigurableApplicationContext context) {
    if (this.registerShutdownHook) {
        //注册应用程序上下文
        shutdownHook.registerApplicationContext(context);
    }
	//大名鼎鼎的refresh
    this.refresh(context);
}
protected void refresh(ConfigurableApplicationContext applicationContext) {
    applicationContext.refresh();
}
```

> `refresh()`在`AbstractApplicationContext`实现类中

- 这里是噩梦的源泉

```java
public void refresh() throws BeansException, IllegalStateException {
    synchronized(this.startupShutdownMonitor) {
        StartupStep contextRefresh = this.applicationStartup.start("spring.context.refresh");
        //准备刷新 -> 这里会设置一些状态什么的
        this.prepareRefresh();
        //获得新的BeanFactory -> 刷新
        ConfigurableListableBeanFactory beanFactory = this.obtainFreshBeanFactory();
        //准备BeanFactory -> 设置一些beanPostProcess丶一些可以加载和忽略的class等
        this.prepareBeanFactory(beanFactory);

        try {
            //BeanFactorypostProcess添加一些加载和忽略的class
            this.postProcessBeanFactory(beanFactory);
            StartupStep beanPostProcess = this.applicationStartup.start("spring.context.beans.post-process");
            //开始执行BeanFactoryPostProcessors的方法
            //SpringBoot的自动配置类就是这里加载完成的 -> AutoConfigurationImportSelector
            //这个在@SpringBootApplication进去@Import(AutoConfigurationImportSelector.class)
            //导入这个自动配置类，调用selectImports()方法，就是BeanFactory后置处理器调用的
            //我们下面开个代码块讲这个 -> 自动配置的selectImports()
            this.invokeBeanFactoryPostProcessors(beanFactory);
            //注册 Bean 后处理器
            this.registerBeanPostProcessors(beanFactory);
            beanPostProcess.end();
            //初始化消息源丶国际化相关
            this.initMessageSource();
            //初始化应用事件广播器
            this.initApplicationEventMulticaster();
            //tomcat创建+启动 -> 下面代码块tomcat创建+启动
            this.onRefresh();
            //注册监听器
            this.registerListeners();
            //完成 Bean 工厂初始化,生产单例Bean -> Bean的生命周期在这里
            //新的代码块 -> Bean的生命周期,我腻了,累了
            this.finishBeanFactoryInitialization(beanFactory);
            this.finishRefresh();
    }
}
```

- `selectImports()` -> SpringBoot自动配置类加载

  - `AutoConfigurationImportSelector`

  ```java
  @Override
  public String[] selectImports(AnnotationMetadata annotationMetadata) {
      //annotationMetadata就是我们传入的SpringApplication.run(Application.class, args);
      //的Application，就是我们的启动Spring的入口类
      if (!isEnabled(annotationMetadata)) {
          return NO_IMPORTS;
      }
      //获取自动配置条目
      AutoConfigurationEntry autoConfigurationEntry = getAutoConfigurationEntry(annotationMetadata);
      return StringUtils.toStringArray(autoConfigurationEntry.getConfigurations());
  }
  
  //获取自动配置条目 -> 返回应该导入的自动配置类
  protected AutoConfigurationEntry getAutoConfigurationEntry(AnnotationMetadata annotationMetadata) {
      if (!isEnabled(annotationMetadata)) {
          return EMPTY_ENTRY;
      }
      //获取注解 -> EnableAutoConfiguration.class，写死的这个class
      //attributes内容就是这个EnableAutoConfiguration接口的抽象方法
      //exclude()排除特定的自动配置类，使它们永远不会被应用
      //excludeName()排除特定的自动配置类名称，使其永远不会被应用
      AnnotationAttributes attributes = getAttributes(annotationMetadata);
      //获取候选配置 -> 先拿到所有的SpringBoot给的自动配置类
      //这个要细说一下 -> 看下面新代码块
      //拿到了所有的SpringBoot给我们准备的自动配置类
      //但是，不是所有的我们都需要，所以下面我们会过滤
      List<String> configurations = getCandidateConfigurations(annotationMetadata, attributes);
      //删除重复项 -> 去重
      configurations = removeDuplicates(configurations);
      //获取排除项，是否有标注了直接要排除不加载的
      Set<String> exclusions = getExclusions(annotationMetadata, attributes);
      //检查排除类
      checkExcludedClasses(configurations, exclusions);
      //先过滤掉，我们直接选择排除的类，比如我们自己注解上手动排除的
      configurations.removeAll(exclusions);
      //获取配置类过滤器，过滤 -> 获取依赖，真正的过滤哪些我们依赖中没有依赖的不需要的自动配置
      //getConfigurationClassFilter():也可以说一下 -> 看下面代码块，不看也行
      //就是用@Condition注解来设置一个过滤器
      //filter正式过滤掉那些不使用的自动配置类
      configurations = getConfigurationClassFilter().filter(configurations);
      //触发自动配置导入事件，完成自动配置类加载，回到上面refresh()
      fireAutoConfigurationImportEvents(configurations, exclusions);
      return new AutoConfigurationEntry(configurations, exclusions);
  }
  ```

  - `getCandidateConfigurations()` -> 拿到所有的SpringBoot给的自动配置类

  ```java
  protected List<String> getCandidateConfigurations(AnnotationMetadata metadata, AnnotationAttributes attributes) {
      //getSpringFactoriesLoaderFactoryClass()返回就是EnableAutoConfiguration.class
      //看最下面贴的方法getSpringFactoriesLoaderFactoryClass()
      //getBeanClassLoader()就是一个加载器，名字叫RestartClassLoader
      List<String> configurations = SpringFactoriesLoader.loadFactoryNames(this.getSpringFactoriesLoaderFactoryClass(), this.getBeanClassLoader());
      return configurations;
  }
  //使用给定的类加载器从"META-INF/spring.factories"加载给定类型的工厂实现的完全限定类名。
  public static List<String> loadFactoryNames(Class<?> factoryType, @Nullable ClassLoader classLoader) {
      //factoryTypeName：我们传过来的EnableAutoConfiguration
      String factoryTypeName = factoryType.getName();
      //loadSpringFactories： 看下面，这是重点
      //getOrDefault：过滤出EnableAutoConfiguration的自动配置类一个137个
      //AOP Rabbit Elasticsertch Mongo Redis等自动配置类
      //tomcat的自动配置类叫EmbeddedWebServerFactoryCustomizerAutoConfiguration
      //跟上思路，拿到了自动配置类了，回到selectImports()方法getAutoConfigurationEntry那里
      return loadSpringFactories(classLoader).getOrDefault(factoryTypeName, Collections.emptyList());
  }
  
      
  private static Map<String, List<String>> loadSpringFactories(ClassLoader classLoader) {
      //有缓存就从缓存拿
      Map<String, List<String>> result = (Map)cache.get(classLoader);
      if (result != null) {
          return result;
      } else {
          HashMap result = new HashMap();
  
          try {
              //拿到路径的一个迭代器 -> 这里是指拿到了多少个叫做META-INF/spring.factories的路径
              //现在有很多个spring.factories的文件
              Enumeration urls = classLoader.getResources("META-INF/spring.factories");
  
              while(urls.hasMoreElements()) {
                  //拿到其中一个
                  //spring-beans.jar!/META-INF/spring.factories
                  //spring-boot-devtools.jar!/META-INF/spring.factories
                  //spring-boot.jar!/META-INF/spring.factories
                  //spring-boot-autoconfigure.jar!/META-INF/spring.factories
                  URL url = (URL)urls.nextElement();
                  //根据给定的 URL 对象创建一个新的UrlResource 
                  UrlResource resource = new UrlResource(url);
                  //从给定资源加载属性 -> 这里就拿到了spring.factories的所有配置
                  //此时还没有过滤，因为我们要EnableAutoConfiguration接口的，现在是所有的
                  Properties properties = PropertiesLoaderUtils.loadProperties(resource);
                  //搞成一个迭代器
                  Iterator var6 = properties.entrySet().iterator();
  				//一顿修剪空格啥的，放到result中
                  while(var6.hasNext()) {
                      Entry<?, ?> entry = (Entry)var6.next();
                      String factoryTypeName = ((String)entry.getKey()).trim();
                      String[] factoryImplementationNames = StringUtils.commaDelimitedListToStringArray((String)entry.getValue());
                      String[] var10 = factoryImplementationNames;
                      int var11 = factoryImplementationNames.length;
  
                      for(int var12 = 0; var12 < var11; ++var12) {
                          String factoryImplementationName = var10[var12];
                          ((List)result.computeIfAbsent(factoryTypeName, (key) -> {
                              return new ArrayList();
                          })).add(factoryImplementationName.trim());
                      }
                  }
              }
  
              result.replaceAll((factoryType, implementations) -> {
                  return (List)implementations.stream().distinct().collect(Collectors.collectingAndThen(Collectors.toList(), Collections::unmodifiableList));
              });
              //加入缓存
              cache.put(classLoader, result);
              //这里面是所有的spring.factories信息
              return result;
          } catch (IOException var14) {
              throw new IllegalArgumentException("Unable to load factories from location [META-INF/spring.factories]", var14);
          }
      }
  }
  
  
  
  protected Class<?> getSpringFactoriesLoaderFactoryClass() {
      return EnableAutoConfiguration.class;
  }
  ```

  - `getConfigurationClassFilter()` -> 过滤依赖

    ```java
    private AutoConfigurationImportSelector.ConfigurationClassFilter getConfigurationClassFilter() {
        if (this.configurationClassFilter == null) {
            //获取过滤器
            //org.springframework.boot.autoconfigure.condition.OnClassCondition
            //org.springframework.boot.autoconfigure.condition.OnWebApplicationCondition
            //org.springframework.boot.autoconfigure.condition.OnBeanCondition
            //都是用@Condition注解来判断过滤的
            List<AutoConfigurationImportFilter> filters = this.getAutoConfigurationImportFilters();
            Iterator var2 = filters.iterator();
    		//不同的过滤器
            while(var2.hasNext()) {
                AutoConfigurationImportFilter filter = (AutoConfigurationImportFilter)var2.next();
                //配置好一些类加载器，准备过滤
                this.invokeAwareMethods(filter);
            }
    		//配置类过滤器ConfigurationClassFilter
            this.configurationClassFilter = new AutoConfigurationImportSelector.ConfigurationClassFilter(this.beanClassLoader, filters);
        }
    
        return this.configurationClassFilter;
    }
    ```

    

> `tomcat创建+启动` -> onRefresh()

- `ServletWebServerApplicationContext`

```java
protected void onRefresh() {
    super.onRefresh();

    try {
        //在入口在这里
        this.createWebServer();
    } catch (Throwable var2) {
        throw new ApplicationContextException("Unable to start web server", var2);
    }
}

private void createWebServer() {
    //获取web服务器 -> 当前是没有的
    WebServer webServer = this.webServer;
    //定义一组servlet用来与其servlet容器通信的方法，例如，获取文件的 MIME 类型、分派请求或写入日志文件
    ServletContext servletContext = this.getServletContext();
    if (webServer == null && servletContext == null) {
        //获取Web服务器工厂 -> 这个工厂中因为自动配置类已经加载完成
        //依赖中有tomcat,所以返回一个tomcat的工厂,tomcat的工厂定制器
        ServletWebServerFactory factory = this.getWebServerFactory();
        createWebServer.tag("factory", factory.getClass().toString());
        //用tomcat工厂定制器生产一个WebServer -> 详细看下面的getWebServer()
        this.webServer = factory.getWebServer(new ServletContextInitializer[]{this.getSelfInitializer()});
}
```

- `getWebServer()` -> **创建Tomcat并启动**

  - 这是创建Tomcat的最核心方法

  ```java
  public WebServer getWebServer(ServletContextInitializer... initializers) {
      //禁用 M Bean 注册表
      if (this.disableMBeanRegistry) {
          Registry.disableRegistry();
      }
  	//创建一个Tomcat的对象
      Tomcat tomcat = new Tomcat();
      //创建临时文件目录:C:\用户\AppData\Local\Temp\tomcat.8080.3765047936726166640
      //端口默认8080
      File baseDir = this.baseDirectory != null ? this.baseDirectory : this.createTempDir("tomcat");
      //路径设置到tomcat对象上
      tomcat.setBaseDir(baseDir.getAbsolutePath());
      //服务器生命周期监听器
      Iterator var4 = this.serverLifecycleListeners.iterator();
  
      while(var4.hasNext()) {
          LifecycleListener listener = (LifecycleListener)var4.next();
          tomcat.getServer().addLifecycleListener(listener);
      }
  	// 协议: protocol = "org.apache.coyote.http11.Http11NioProtocol";非阻塞连接池
      // tomcat默认的连接池是阻塞连接池
      //创建一个连接,使用非阻塞连接池
      Connector connector = new Connector(this.protocol);
      //设置失败时抛出异常
      connector.setThrowOnFailure(true);
      //tomcat添加连接
      tomcat.getService().addConnector(connector);
      //定制连接器
      this.customizeConnector(connector);
      //设置连接器
      tomcat.setConnector(connector);
      //设置自动部署:Host=localhost
      tomcat.getHost().setAutoDeploy(false);
      //配置引擎
      this.configureEngine(tomcat.getEngine());
      //额外的 Tomcat 连接器: 没有空的
      Iterator var8 = this.additionalTomcatConnectors.iterator();
  
      while(var8.hasNext()) {
          Connector additionalConnector = (Connector)var8.next();
          tomcat.getService().addConnector(additionalConnector);
      }
  
      this.prepareContext(tomcat.getHost(), initializers);
      //获取TomcatWebServer,这里将会启动tomcat
      return this.getTomcatWebServer(tomcat);
  }
  ```

  - `启动Tomcat`

    ```java
    protected TomcatWebServer getTomcatWebServer(Tomcat tomcat) {
        return new TomcatWebServer(tomcat, this.getPort() >= 0, this.getShutdown());
    }
    
    public TomcatWebServer(Tomcat tomcat, boolean autoStart, Shutdown shutdown) {
        Assert.notNull(tomcat, "Tomcat Server must not be null");
        this.tomcat = tomcat;
        this.autoStart = autoStart;
        //优雅关机
        this.gracefulShutdown = (shutdown == Shutdown.GRACEFUL) ? new GracefulShutdown(tomcat) : null;
        //初始化,启动
        initialize();
    }
    
    private void initialize() throws WebServerException {
        //打印日志
        //控制台可以看到的
        //Tomcat initialized with port(s): 8080 (http)
        logger.info("Tomcat initialized with port(s): " + getPortsDescription(false));
        synchronized (this.monitor) {
            try {
                //将实例 ID 添加到引擎名称
                addInstanceIdToEngineName();
    			//查找上下文
                Context context = findContext();
                //添加生命周期监听器
                context.addLifecycleListener((event) -> {
                    if (context.equals(event.getSource()) && Lifecycle.START_EVENT.equals(event.getType())) {
                        // 移除服务连接器，这样协议绑定就不会
                        // 服务启动时发生。
                        removeServiceConnectors();
                    }
                });
    
                // 启动服务器以触发初始化侦听器,启动完成,回到最前面的refresh()
                this.tomcat.start();
    
                // 我们可以直接在主线程中重新抛出失败异常
                rethrowDeferredStartupExceptions();
        }
    }
    
    ```

    

> Bean的生命周期 

- 这个Bean的生命周期 从初始化这里看是很乱的,代码没有那么好看
- 我们还是跟网上的一样,`getBean()`这样的节奏
  - `getBean()` -> `doGetBean()` -> `createBean()` ->  `doCreateBean()`
- 但是我们会把这个调用的源码贴一部分出来

```java
protected void finishBeanFactoryInitialization(ConfigurableListableBeanFactory beanFactory) {
   ....
   //最后一步,预实例化单例
   //确保实例化所有非惰性初始化单例，同时考虑FactoryBeans 。如果需要，通常在工厂设置结束时调用。
   beanFactory.preInstantiateSingletons();
}

public void preInstantiateSingletons() throws BeansException {
	//拿到所有beanDefinition
    List<String> beanNames = new ArrayList(this.beanDefinitionNames);
    ...
	//省略了很多,我们只看一个getBean就行,这时候是一个单例的
   	this.getBean(beanName);
}
//AbstractBeanFactory -> getBean()
@Override
public Object getBean(String name) throws BeansException {
    return doGetBean(name, null, null, false);
}
```

- `doGetBean()`  -> `createBean()`
  - 这里都不是重点

```java
protected <T> T doGetBean(String name)  {
    ...
    //如果是单例
    return this.createBean(beanName, mbd, args);
}
//AbstractAutowireCapableBeanFactory -> createBean()
protected Object createBean(String beanName, RootBeanDefinition mbd, @Nullable Object[] args)  {
    ...
    //去创建Beaan
    beanInstance = this.doCreateBean(beanName, mbdToUse, args);
	...
    return beanInstance;
}
```

- `doCreateBean()` -> 大魔王来了,开始了,开始了
  - 记住这个方法就是整个Bean的生命周期 -> `AbstractAutowireCapableBeanFactory`
  - `推断构造方法` -> `生成一个实例Bean` ->  `属性注入` -> `初始化前` -> `初始化` -> `初始化后`
    - 里面还有 -> 解决循环依赖

```java
protected Object doCreateBean(String beanName, RootBeanDefinition mbd, @Nullable Object[] args) throws BeanCreationException {
    //实例包装器
    BeanWrapper instanceWrapper = null;
    if (mbd.isSingleton()) {
        // 如果是单例，则先清除缓存
        instanceWrapper = (BeanWrapper)this.factoryBeanInstanceCache.remove(beanName);
    }
	//1.开始创建一个实例Bean,包装到BeanWrapper实例 -> 这里面有推断构造方法,分开详解
    if (instanceWrapper == null) {
        instanceWrapper = this.createBeanInstance(beanName, mbd, args);
    }
	//获取实例,刚刚已经推断完成构造方法,创建了一个实例Bean
    Object bean = instanceWrapper.getWrappedInstance();
    Class<?> beanType = instanceWrapper.getWrappedClass();
    if (beanType != NullBean.class) {
        //已解决的目标类型
        mbd.resolvedTargetType = beanType;
    }
    synchronized(mbd.postProcessingLock) {
        if (!mbd.postProcessed) {
            try {
                //应用合并的 Bean 定义后处理器
                //在这里可以添加修改beanDefinition的内容，可以算作一个beanPostProcessor的扩展点
                //扫描方法上是否有@PostConstruct @PreDestroy注解
                //扫描方法和属性上是否有@Autowired @Value注解
                this.applyMergedBeanDefinitionPostProcessors(mbd, beanType, beanName);
            } catch (Throwable var17) {
                throw new BeanCreationException(mbd.getResourceDescription(), beanName, "Post-processing of merged bean definition failed", var17);
            }

            mbd.postProcessed = true;
        }
    }
	
	// 当前创建的是单例bean，并且允许循环依赖，并且还在创建过程中
    boolean earlySingletonExposure = mbd.isSingleton() && this.allowCircularReferences && this.isSingletonCurrentlyInCreation(beanName);
    //如果是上面的情况 -> 需要解决循环依赖等问题了 -> 三级缓存解决循环依赖
    if (earlySingletonExposure) {
        if (this.logger.isTraceEnabled()) {
            //急切地缓存bean + name + 允许解析潜在的循环引用
            this.logger.trace("Eagerly caching bean '" + beanName + "' to allow for resolving potential circular references");
        }
		//如有必要，添加给定的单例工厂以构建指定的单例。
		//被要求急切注册单例，例如能够解决循环引用。
        //解决循环依赖
        //此时讲这个beanName的工厂加入第三级的缓存中 -> 是一个只实例化,没有属性注入的不完整的Bean
        //如果循环引用的Bean1对象要使用Bean2,就从这个工厂里拿这个bean2的工厂获取到Bean2实例
        //获取到的Bean2实例给这个Bean1对象注入使用,并且将这个Bean2加入第二级缓存中
        //Bean1完成所有步骤创建Bena完成,将Bean1加入第一级缓存中,也就是IOC容器
        //Bean2接着初始化,拿这个已经完成的Bean1注入,也完成Bean创建,也加入IOC容器,并从第二级缓存移除
        //利用Java的 值引用,完成循环依赖注入
        this.addSingletonFactory(beanName, () -> {
            //获取早期 Bean 参考
            return this.getEarlyBeanReference(beanName, mbd, bean);
        });
    }

    Object exposedObject = bean;

    try {
        //填充 Bean -> 属性注入,单独拿出来说的
        this.populateBean(beanName, mbd, instanceWrapper);
        //初始化 -> 搞完这里算了,不搞了,全麻了,写道后面我自己不想写了 -> 下面initializeBean初始化
        exposedObject = this.initializeBean(beanName, exposedObject, mbd);
    } catch (Throwable var18) {

    }
}
```



- `推断构造方法,实例化Bean`
  - 总结: **有无参数的执行无参,有@Autowired注解的执行,只有一个构造方法也直接执行**

  - **有2个有参的构造方法,没有无参的、也没有加@Autowired报错**

```java
protected BeanWrapper createBeanInstance(String beanName, RootBeanDefinition mbd, @Nullable Object[] args) {
    //解析Bean类: 首先确保bean已经被解析为 BeanDefinition
    Class<?> beanClass = this.resolveBeanClass(mbd, beanName, new Class[0]);
    // 如果beanClass 不是public类型，那么就抛出异常，提示   non-public access not allowed
    // 这里说明了条件,Bean必须是public的
    if (beanClass != null && !Modifier.isPublic(beanClass.getModifiers()) && !mbd.isNonPublicAccessAllowed()) {
        throw new BeanCreationException(mbd.getResourceDescription(), beanName, "Bean class isn't public, and non-public access not allowed: " + beanClass.getName());
    } else {
        //返回用于创建 bean 实例的回调。 -> 先不管
        Supplier<?> instanceSupplier = mbd.getInstanceSupplier();
        if (instanceSupplier != null) {
            return this.obtainFromSupplier(instanceSupplier, beanName);
        // 如果存在对应的工厂方法，那么就使用工厂方法进行初始化 -> 不管
        } else if (mbd.getFactoryMethodName() != null) {
            return this.instantiateUsingFactoryMethod(beanName, mbd, args);
        } else {
            // 表示构造信息是否已经解析成可以反射调用的构造方法method信息了...
            boolean resolved = false;
            // 是否自动匹配构造方法..
            boolean autowireNecessary = false;
            //如果没有参数传递到这个Bean创建的构造方法中
            if (args == null) {
                synchronized(mbd.constructorArgumentLock) {
					//一个类有多个构造函数，每个构造参数数都有不同的参数
                    //所以调用前前需要先根据参数 锁定对应的解析工厂方法 
                    if (mbd.resolvedConstructorOrFactoryMethod != null) {
                        //解析标记 -> 下面这两个都不是方法都是boolean类型的标记
                        //表示这个Bean的构造方法已经解析、已经推断过了
                        //一般第一次是没有解析过的 ->  -> 不管
                        resolved = true;
                        autowireNecessary = mbd.constructorArgumentsResolved;
                    }
                }
            }
			//如果已经解析过则使用解析好的构造函数方法，不用再次锁定 -> 第一次是没有解析过的 -> 不管
            if (resolved) {
                return autowireNecessary ? this.autowireConstructor(beanName, mbd, (Constructor[])null, (Object[])null) : this.instantiateBean(beanName, mbd);
            } else {
                // 第一次解析都来这里 -> 这里就开始要推断构造方法了 -> 来了,来了
                // 确定来自Bean后处理器的构造函数
                // 典型的应用：@Autowired 注解打在了构造器方法上
                Constructor<?>[] ctors = this.determineConstructorsFromBeanPostProcessors(beanClass, beanName);
                //1.构造函数没有加@Autowired
                //2.不根据构造方法进行自动装配
                //3.不是有参的构造函数
                //4.此时没有传入参数
                if (ctors == null && mbd.getResolvedAutowireMode() != 3 && !mbd.hasConstructorArgumentValues() && ObjectUtils.isEmpty(args)) {
                    //获取首选构造函数 -> 意思就是是不是有多个构造函数
                    //Constructor<?>[] -> 就是一个构造函数的数组
                    ctors = mbd.getPreferredConstructors();
                    //1. 有多个构造函数 -> autowireConstructor()
                    //2. 默认无参构造函数实例化 Bean -> instantiateBean()
                    //无参的构造函数就简单了,就不进去看了
                    //有多个构造函数时,推断使用哪一个? 
                    //autowireConstructor;自动配置构造方法 -> 下面的注释解释这个方法
                    return ctors != null ? this.autowireConstructor(beanName, mbd, ctors, (Object[])null) : this.instantiateBean(beanName, mbd);
                } else {
                    //这个方法有点复杂,稍微总结一下吧
                    //存在有参数的构造方法
                    //	如果其中有一个加@Autowired注解了,就走这个加入注解的构造方法
                    //	如果没加@Autowired注解
                    //		存在有参数的构造方法,且没有无参的,报错 -> 比如2个都是有参的构造方法,报错
                    //		存在有参数的构造方法,其中有一个是无参的 -> 就走无参的构造方法
                    //		只有1个有参数的构造方法 -> 就可以执行这一个
                    //总结: 有无参数的执行无参,有@Autowired注解的执行,只有一个构造方法直接执行
                   	//		有2个有参的构造方法,没有无参的、也没有加@Autowired报错
                    //推断构造方法完成 -> 回到doCreateBean()方法的createBeanInstance
                    return this.autowireConstructor(beanName, mbd, ctors, args);
                }
            }
        }
    }
}
```

- `属性注入` -> `populateBean()`

```java
protected void populateBean(String beanName, RootBeanDefinition mbd, @Nullable BeanWrapper bw) {
    if (bw == null) {
        if (mbd.hasPropertyValues()) {
            //无法将属性值应用于空实例 -> Bean实例刚刚我们已经创建了
            throw new BeanCreationException(mbd.getResourceDescription(), beanName, "Cannot apply property values to null instance");
        }
    } else {
        //返回此工厂是否拥有一个将在创建时应用于单例 bean 的 InstantiationAwareBeanPostProcessor。
        //只有postProcessAfterInstantiation返回值是false才会进行属性填充，否则直接结束属性填充。
        //如果实现了这个接口就不会属性填充了
        //判断该bean是否进行属性填充 -> 进去了这个if就代表不用依赖注入
        //public interface InstantiationAwareBeanPostProcessor extends BeanPostProcessor
        //它继承了BeanPostProcessor 通常用于抑制特定目标 bean 的默认实例化，例如创建具有特殊 				//TargetSources 的代理（池化目标、延迟初始化目标等），或实现额外的注入策略，如字段注入
        //我想你大概知道了上面情况了,AOP代理在这里,不让你正常属性注入了,AOP代理都不走这里的,reture
        if (!mbd.isSynthetic() && this.hasInstantiationAwareBeanPostProcessors()) {
            Iterator var4 = this.getBeanPostProcessorCache().instantiationAware.iterator();

            while(var4.hasNext()) {
                InstantiationAwareBeanPostProcessor bp = (InstantiationAwareBeanPostProcessor)var4.next();
                if (!bp.postProcessAfterInstantiation(bw.getWrappedInstance(), beanName)) {
                    return;
                }
            }
        }
		//具有属性值? 是就获取
        PropertyValues pvs = mbd.hasPropertyValues() ? mbd.getPropertyValues() : null;
        //获取自动注入的类型: 0没有Autowire 1Autowire_BY_NAME 2Autowire_BY_TYPE
        int resolvedAutowireMode = mbd.getResolvedAutowireMode();
        if (resolvedAutowireMode == 1 || resolvedAutowireMode == 2) {
            //可变属性值 -> 深拷贝PropertyValues的构造函数
            MutablePropertyValues newPvs = new MutablePropertyValues((PropertyValues)pvs);
            if (resolvedAutowireMode == 1) {
                //内容就是遍历属性的name,getBean()
                //再利用set方法注入
                this.autowireByName(beanName, mbd, bw, newPvs);
            }

            if (resolvedAutowireMode == 2) {
                //内容就是遍历属性的Type,getBean()
                //再利用set方法注入
                this.autowireByType(beanName, mbd, bw, newPvs);
            }
		   // 注意，执行完这里的代码之后，这是把属性以及找到的值存在了pvs里面，并没有完成反射赋值
            pvs = newPvs;
        }
        // 执行完了Spring的自动注入之后，就开始解析@Autowired
        if (hasInstAwareBpps) {
            PropertyValues pvsToUse;
            for(Iterator var9 = this.getBeanPostProcessorCache().instantiationAware.iterator(); var9.hasNext(); pvs = pvsToUse) {
                InstantiationAwareBeanPostProcessor bp = (InstantiationAwareBeanPostProcessor)var9.next();
                // 调用BeanPostProcessor分别解析@Autowired、@Resource、@Value，得到属性值
                // 对@AutoWired标记的属性进行依赖注入,调用反射set进行赋值
                pvsToUse = bp.postProcessProperties((PropertyValues)pvs, bw.getWrappedInstance(), beanName);
                if (pvsToUse == null) {
                    if (filteredPds == null) {
                        filteredPds = this.filterPropertyDescriptorsForDependencyCheck(bw, mbd.allowCaching);
                    }
					// 对解析完未设置的属性再进行处理
                    // 依赖注入完成,回到注入开始,准备初始化Bean -> doCreateBean()的 初始化Bean
                    pvsToUse = bp.postProcessPropertyValues((PropertyValues)pvs, filteredPds, bw.getWrappedInstance(), beanName);
                    if (pvsToUse == null) {
                        return;
                    }
                }
            }
        }
    }
}
```

- `initializeBean初始化`

```java
protected Object initializeBean(String beanName, Object bean, @Nullable RootBeanDefinition mbd) {
    //获取安全管理器
    if (System.getSecurityManager() != null) {
        AccessController.doPrivileged(() -> {
            this.invokeAwareMethods(beanName, bean);
            return null;
        }, this.getAccessControlContext());
    } else {
        //执行实现Aware接口的方法
        this.invokeAwareMethods(beanName, bean);
    }

    Object wrappedBean = bean;
    if (mbd == null || !mbd.isSynthetic()) {
        //在初始化bean前执行bean的Before后置处理器
        wrappedBean = this.applyBeanPostProcessorsBeforeInitialization(bean, beanName);
    }

    try {
        ////执行初始化方法
        this.invokeInitMethods(beanName, wrappedBean, mbd);
    } catch (Throwable var6) {

    }

    if (mbd == null || !mbd.isSynthetic()) {
        //在初始化bean后执行bean的After后置处理器
        wrappedBean = this.applyBeanPostProcessorsAfterInitialization(wrappedBean, beanName);
    }

    return wrappedBean;
}
```

