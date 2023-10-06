# 如何理解 Spring Boot 中的 Starter

- starter就是定义⼀个starter的jar包，写⼀个`@Configuration配置类`、`将这些bean定义`在⾥⾯
- 然后在starter包的`META-INF/spring.factories`中写⼊该配置类
- springboot会按照约定来加载该配置类开发⼈员只需要将相应的starter包依赖进应⽤
- 进⾏相应的属性配置（使⽤默认配置时，不需要配置），就可以直接进⾏代码开发，使⽤对应的功能了
  - ⽐如`mybatis-spring-boot-starter`，`spring-boot-starter-redis `
  - 比如我们自己写一个starter自动配置启动
  - 写一个我们自己的线程池，用`@Configuration+@Bean`定义一个线程池
  - 将这个配置类的路径写到`spring.factories`中,就可以了
  - 打上jar包，在其他地方引用,用`@Autowired`自动注入我们的Bean使用就可以了

> 自定义starter

- 引入boot的starter

  ```java
  <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter</artifactId>
  </dependency>
  ```

- 自己配置Bean

  ```java
  @Configuration
  public class MyThreadPoolExecutor {
      @Bean
      @ConditionalOnClass(ThreadPoolExecutor.class)
      public ThreadPoolExecutor myPool() {
          //可以改成配置文件
          return new ThreadPoolExecutor(0, Integer.MAX_VALUE,
                  60L, TimeUnit.SECONDS,
                  new SynchronousQueue<Runnable>());
      }
  }
  ```

- 新建一个`spring.factories在resources`下面

  ```java
  # Auto Configure
  org.springframework.boot.autoconfigure.EnableAutoConfiguration=\
  rod.spring.MyThreadPoolExecutor 
  ```

- 去别的地方引用，用`@Autowired`自动注入就行了

