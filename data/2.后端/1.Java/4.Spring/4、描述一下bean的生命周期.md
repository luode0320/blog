## 描述一下bean的生命周期

1. Spring启动,扫描到一个@controller等注解类,解析为BeanDefinition (Bean的 定义类)
2. 找到一个可用的构造方法`实例化一个对象`
3. `属性注入 -> 依赖注入`
4. `初始化前` -> 这一步骤时,**构造方法和@Autowired都已经完成**
5. `初始化Bean` -> InitializingBean接口
6. `初始化后，进⾏AOP `
7. `完成创建`
8. `销毁Bean`

- Spring启动,扫描到一个@controller等注解类,解析为BeanDefinition (Bean的 定义类)

  ```java
  //启动扫描
  @ComponentScan("rod.spring.ioc")
  public class IocTest {
      public static void main(String[] args) {
          AnnotationConfigApplicationContext context = new AnnotationConfigApplicationContext(IocTest.class);
      }
  }
  ```
  
- 找到一个可用的构造方法`实例化一个对象`

  - 这是一个比较普通的对象,如果构造方法有需要注入的Bean也会注入进去

    ```java
    @Component
    class User {
        private Order order;
    
        //这里的Order会从IOC容器中拿,不需要注解
        public User(Order order) {
            this.order = order;
            System.out.println("User创建普通对象 -> " + this.order);
        }
    }
    ```

- `属性注入 -> 依赖注入`

  - 有`@Autowired`注解的属性,从IOC容器中取出注入

  ```java
  @Component
  class User {
      @Autowired
      private Order order;
  }
  ```

- `Bean初始化前` -> 这一步骤时,**构造方法和@Autowired都已经完成**

  - 初始化方法前调用 -> `@PostConstruct` 

  - 这个方法只针对当前的类创建Bean有效 -> 为什么要提这一句?

  - 因为后面有方法,不管里加在哪个类,所有的Bean创建都重复会调用

    ```java
    @Component
    class User {
        @Autowired
        private Order order;
    
        @PostConstruct
        public void PostConstruct() {
            System.out.println("User -> 初始化之前");
        }
    }
    ```

- `初始化Bean`

  - **init-method是xml配置的**,现在都SpringBoot了就不提了,过时了
    - 初始化方法一开始说得就是init-method指定的方法,但是SpringBoot已经不用xml配置了
  - 初始化方法 -> 要实现**InitializingBean接口**
    - `afterPropertiesSet()` 

  ```java
  @Component
  class User implements InitializingBean{
      @Autowired
      private Order order;
  
      @Override
      public void afterPropertiesSet() throws Exception {
          System.out.println("User -> afterPropertiesSet");
      }
  }
  ```

- `扩展初始化方法`  -> 要实现**BeanPostProcessor接口 **

  - 扩展的方法执行在初始化方法`之前和之后`

  - `postProcessBeforeInitialization()` -> 之前(最前面,在上面注解的前面)

  - `postProcessAfterInitialization()` -> 之后(最后面,再之后就完成Bean创建了)

  - 注意: 这个接口和方法**不管在哪里实现了**,所有的Bean初始化都会执行一遍,**不仅仅当前类有效**

    - 所以这是个全局有效的东西

    ```java
    @Component
    class User implements BeanPostProcessor{
        @Override
        public Object postProcessBeforeInitialization(Object bean, String beanName) {
            System.out.println("初始化前");
            return bean;
        }
    
        @Override
        public Object postProcessAfterInitialization(Object bean, String beanName) {
            System.out.println("初始化后");
            return bean;
        }
    }
    ```

- Bean对象**准备**完成创建,`postProcessAfterInitialization`执行中,判断有没有AOP的切点与该对象匹配
  - 如果该Bean没有AOP操作,将该Bean存入IOC的map容器中 -> `完成创建`
  - 如果有AOP操作,则使用AOP将Bean对象进行代理,代理后的代理对象存入IOC的map容器中-> `完成创建`

- `销毁Bean` -> 两种办法

  - `DisposableBean接口`,允许在容器销毁该bean的时候获得一次回调
  -  `@PreDestroy `注解,容器销毁该bean的时候获得一次回调

  ```java
  @Component
  class User implements DisposableBean{
  	@Override
      public void destroy() throws Exception {
          System.out.println("我要销毁了 ....");
      }
  }
  
  @Component
  class User{
      @PreDestroy
      public void destroy2() throws Exception {
          System.out.println("我要销毁了2 ....");
      }
  }
  ```

  