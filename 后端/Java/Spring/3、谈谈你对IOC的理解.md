# 谈谈你对IOC的理解 

**IOC就是将你设计好的`Bean对象交给容器控制`，而不是传统的在你的对象内部直接控制**

> IOC有3个概念 -> 容器、控制反转、依赖注⼊ 

**容器**

- ioc容器：`实际上就是个map（key，value）`，⾥⾯存的是各种Bean对象
  - `Configuration配置的Bean、 @repository、@service、@controller、@component`
- 这个时候map⾥就有各种对象了，接下来我们在代码⾥需要⽤到⾥⾯的对象时，再通过DI注⼊ 
  - `@autowired、@resource`等注解
  - 根据**类型或id注⼊,id就是对象名**。 

**控制反转**

- 没有引⼊`IOC容器之前`，**对象有一个依赖对象**
- 那么我们必须`主动去创建依赖对象`或者显示的从参数传递过来。
- ⽆论是创建还是使⽤依赖对象，控制权都在⾃⼰⼿上。 
  - **什么时候创建,在哪里创建都是我们自己决定的**,从而导致类与类之间`高耦合`

- 有IOC容器之后，对象与依赖之间`失去了直接联系`
  - **创建和查找依赖对象的控制权交给了容器**
  - 由容器进行`注入组合对象`，所以对象与对象之间是` 松散耦合`
  - 显得整个结构`变得非常灵活`
- IOC容器会`主动创建⼀个Bean`注⼊到对象需要的地⽅。 

- 通过前后的对⽐，不难看出来：
  - 对象获得依赖对象丶初始化对象属性的过程,由**主动⾏为变为了被动⾏为**
  - 控制权颠倒过来了，这就是“控制反转”这个名称的由来。 

- 全部对象的控制权全部上缴给`“第三⽅”IOC容器`

**依赖注⼊**

- 从IOC容器中拿到`依赖的Bean对象`,**新创建的Bean在初始化过程中赋值到依赖的属性上**

  - 如果容器中还没有依赖的Bean,就先创建这个依赖的Bean对象
  - 创建完成后赋值到新对象的属性中去

  ```java
  @Resource
  private ActionService actionService;
  @Autowired
  private ActionService actionService;
  ```

  

> 补充: 获取IOC容器

```java
//方法一; 启动类的run方法返回的就是IOC容器 -> 不推荐
ApplicationContext Context = SpringApplication.run(Application.class, args);
Object startSerive = Context.getBean("startSerive");

//方法二; 创建工具类来获取IOC容器
@Component
public class 获取IOC容器 {
    public void test() {
        ApplicationContext context = SpringContextUtil.getApplicationContext();
        System.out.println(context.toString());
    }
}
@Component
class SpringContextUtil implements ApplicationContextAware {
    private static ApplicationContext applicationContext;

    public SpringContextUtil() {
    }

    /**
     * 设置上下文
     * 自动调用ApplicationContextAware中的setApplicationContext方法
     * 将IOC容器传入setApplicationContext方法的形参
     */
    @Override
    public void setApplicationContext(ApplicationContext applicationContext) throws BeansException {
        if (SpringContextUtil.applicationContext == null) {
            SpringContextUtil.applicationContext = applicationContext;
        }
    }

    /**
     * 获取上下文
     */
    public static ApplicationContext getApplicationContext() {
        return applicationContext;
    }

    /**
     * 通过名字获取上下文中的bean
     */
    public static Object getBean(String name) {
        return applicationContext.getBean(name);
    }

    /**
     * 通过类型获取上下文中的bean
     */
    public static Object getBean(Class<?> requiredType) {
        return applicationContext.getBean(requiredType);
    }
}
```

> 配置Bean

```java
//通过方法名或者类型获取Bean对象
@Configuration
class Config {
    @Bean
    public Object object() {
        return new Object();
    }

    //通过name指定Bean的id
    @Bean(name = "object1")
    public Object object1() {
        return new Object();
    }
}
```

