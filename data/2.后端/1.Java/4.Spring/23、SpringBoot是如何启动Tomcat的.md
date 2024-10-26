# Spring Boot是如何启动Tomcat的 

- ⾸先，SpringBoot在启动时会先创建⼀个Spring容器 

- 在创建上下文的时候判断是否是内嵌的web服务类型,选择不同是上下文加载方式

- `refreshContext()`刷新上下文,IOC容器的创建过程的调用`BeanFactoryPostProcessors` -> BeanFactory后置处理器

- BeanFactory后置处理器中加载`spring.factories`内的自动配置类

  - 自动配置接口对应的哪些自动配置类 -> `EnableAutoConfiguration`

- 生成一个`EmbeddedWebServerFactoryCustomizerAutoConfiguration`

  - 嵌入式web服务器工厂定制自动配置类

- 利⽤`@ConditionalOnClass`技术来判断当前ClassPath中是否存在Tomcat依赖

- 是否存在`Tomcat.calss`文件,加载一个Tomcat的定制器,生成一个Tomcat的服务器类

- 调用`getWebServer()`方法,创建Tomcat对象，并绑定端⼝等，然后初始化启动Tomcat

  - `EmbeddedWebServerFactoryCustomizerAutoConfiguration` -> `TomcatWebServerFactoryCustomizerConfiguration` -> `TomcatServletWebServerFactory` -> `TomcatWebServer`

  - `ServletWebServerFactory`  -> `TomcatWebServer`

    ```java
    @Override
    public WebServer getWebServer(ServletContextInitializer... initializers) {
        //创建Tomcat实例
        Tomcat tomcat = new Tomcat();
        //创建Tomcat工作目录
        File baseDir = (this.baseDirectory != null) ? this.baseDirectory
            : createTempDir("tomcat");
        tomcat.setBaseDir(baseDir.getAbsolutePath());
        //创建连接对象（Connector是Tomcat重要组件，主要负责处理客户端连接，以及请求处理，这里简单解释下）
        Connector connector = new Connector(this.protocol);
        tomcat.getService().addConnector(connector);
        customizeConnector(connector);
        tomcat.setConnector(connector);
        tomcat.getHost().setAutoDeploy(false);
        configureEngine(tomcat.getEngine());
        for (Connector additionalConnector : this.additionalTomcatConnectors) {
          tomcat.getService().addConnector(additionalConnector);
        }
        //准备tomcat context
        prepareContext(tomcat.getHost(), initializers);
        //返回WebServer实现TomcatWebServer
        return getTomcatWebServer(tomcat);
      }
    ```

    - getTomcatWebServer中会启动tomcat

    ```java
    	private void initialize() throws WebServerException {
    		logger.info("Tomcat initialized with port(s): " + getPortsDescription(false));
    		synchronized (this.monitor) {
    			try {
    				addInstanceIdToEngineName();
    
    				Context context = findContext();
    				context.addLifecycleListener((event) -> {
    					if (context.equals(event.getSource()) && Lifecycle.START_EVENT.equals(event.getType())) {
    						// Remove service connectors so that protocol binding doesn't
    						// happen when the service is started.
    						removeServiceConnectors();
    					}
    				});
    
    				// 启动服务器以触发初始化侦听器
    				this.tomcat.start();
    
    				// We can re-throw failure exception directly in the main thread
    				rethrowDeferredStartupExceptions();
    
    				try {
    					ContextBindings.bindClassLoader(context, context.getNamingToken(), getClass().getClassLoader());
    				}
    				catch (NamingException ex) {
    					// Naming is not enabled. Continue
    				}
    
    				// Unlike Jetty, all Tomcat threads are daemon threads. We create a
    				// blocking non-daemon to stop immediate shutdown
    				startDaemonAwaitThread();
    			}
    			catch (Exception ex) {
    				stopSilently();
    				destroySilently();
    				throw new WebServerException("Unable to start embedded Tomcat", ex);
    			}
    		}
    	}
    ```

    
