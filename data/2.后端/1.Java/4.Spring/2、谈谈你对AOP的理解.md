# 谈谈你对AOP的理解

> 简介

- AOP可以对`某个对象或某些对象的功能`进⾏增强
  - ⽐如对象中的⽅法进⾏增强
  - 可以在执⾏某个`⽅法之前`额外的做⼀些事情，在某个`⽅法之后`额外的做⼀些事情 

- AOP真正强大之处在于,**在系统主体业务逻辑丶流程已经固定的情况下**
- 可以在`随意位置丶方法前后`添加某些方法来对流程做一些增强或者修改,在任何代码位置`插队`
  - **想加逻辑就加逻辑,想增加一些业务就增加一些业务**
  - 并且想去掉的时候,也可以直接去掉,不会影响主体业务
  - 例如,全局日志、全局异常处理
- 想加业务就加,想停某个业务就停,可以说`解耦力度是非常大的`,`灵活度非常高`

> 原理

- **AOP是IOC容器的一个扩展功能**,AOP的代理Bean是由一个实现了FactoryBean接口的工厂Bean生产的
  - 在Bean的生命周期中,初始化`后置处理器`阶段
  - AOP是通过BeanPostProcessor接口的`后置方法`,去实现对一个**正常Bean对象的代理**
- AOP实现的核心就是动态代理
- AOP切的`对象有接口`,且`方法是实现接口的方法`就用JDK代理
  - JDK代理实现`InvocationHandler的接口`
  - 被代理类跟静态代理一样需要一个接口
  - 所以AOP切的对象有接口,且`方法是实现接口的方法`就用JDK代理
- 否则用CGLIB代理
  - CGLIB代理的被代理类是不需要实现接口的,它的原理是**继承被代理类**,重写代理方法实现的
  - 只需要一个普通类和实现了`MethodInterceptor`接口的代理类就行
  - 所以AOP切的对象没有接口就用CGLIB代理

## SpringBoot中集成AOP

- ##### pom.xml

  ```java
  //aspectjweaver是aspectj的织入包
  <dependency>
      <groupId>org.aspectj</groupId>
      <artifactId>aspectjweaver</artifactId>
  </dependency>
  //aspectjrt是aspectj的运行时包。
  <dependency>
      <groupId>org.aspectj</groupId>
      <artifactId>aspectjrt</artifactId>
  </dependency>
  ```

- controller

  ```java
  @RestController
  @RequestMapping("/aopTest")
  public class AopController {
      @PostMapping("/add")
      public RModel add(@RequestBody ActionModel actionModel) {
      }
  }
  
  ```

- ##### AOP

  ```java
  @Aspect
  @Component
  public class AOPTest {
      /**
       * 定义切入点(Pointcut)，以aop下所有包的请求为切入点
       */
      @Pointcut("execution(public * rod.spring.aop..*.*(..))*")
      public void AopController() {
      }
  
      /**
       * 定义第二个切入点(Pointcut)，以Aop下所有包的请求为切入点
       */
      @Pointcut("execution(public * rod.spring.aop..*.*(..))*")
      public void AopController2() {
      }
      
      /**
       * 前置通知(Before)：在切入点之前执行的通知
       * 可以使用全类名 -> rod.spring.aop.AopController()
       * JoinPoint -> 连接点
       */
      @Before("AopController()")
      public void doBefore(JoinPoint joinPoint) throws Throwable {
          //获取目标方法的参数信息
          joinPoint.getArgs();
          //获取通知的签名
          joinPoint.getSignature();
          //获取`代理类`的名字，
          joinPoint.getSignature().getDeclaringTypeName();
          //获取`代理方法`的名字。
          joinPoint.getSignature().getName();
      }
  
      /**
       * 后置通知(AfterReturning)
       * 可以使用全类名 -> rod.spring.aop.AopController()
       */
      @AfterReturning(returning = "ret", pointcut = "AopController()")
      public void doAfterReturning(Object ret) throws Throwable {
      }
  
      /**
       * 后置最终通知(After)
       * 可以使用全类名 -> rod.spring.aop.AopController()
       */
      @After("AopController()")
      public void doAfter() throws Throwable {
      }
  
      /**
       * 环绕通知
       * 环绕通知第一个参数必须是org.aspectj.lang.ProceedingJoinPoint类型
       * 可以使用全类名 -> rod.spring.aop.AopController()
       */
      @Around("AopController()")
      public Object doAround(ProceedingJoinPoint proceedingJoinPoint) throws Throwable {
          return 0;
      }
  }
  ```


## AOP有一些专业术语,稍微了解一下就行

> `切面（Aspect）`:是指横切多个对象的关注点的一个模块化。

- 在Spring AOP中，切面通过常规类或者通过使用了注解`@Aspect`的常规类来实现。

  - AOP的整个整体就是一个切面,比如在业务什么地方加个逻辑,就是加个切面

    ```java
    @Component
    @Aspect
    public class LogAspect {
        //我们整个AOP的逻辑都写在这里面
    }
    ```

> `连接点（Joint point）`:是指在程序执行期间的一个点，比如某个方法的执行或者是某个异常的处理。

- 在Spring AOP中，一个连接点往往代表的是`一个方法执行`。

  - 我们要吧这个切面逻辑加在具体的哪个方法前面还是后面,这个方法就是一个连接点

    ```java
    @Before("pointcut()")
    ////这个JoinPoint参数就是连接点
    public void log(JoinPoint joinPoint) { 
    }
    ```

> `通知（Advice）`：是指切面在某个特殊连接点上执行的动作。

- 通知有不同类型，包括`"around"`,`"before"`和`"after"`通知。

- 许多AOP框架包括Spring，将通知建模成一个拦截器，并且围绕连接点维持一个拦截器链。

  - 通知就是我们要多加的方法是在连接点前面还是后面执行

    ```java
    // @Before说明这是一个前置通知，log函数中是要前置执行的代码，JoinPoint是连接点，
    @Before("pointcut()")
    public void log(JoinPoint joinPoint) { 
    }
    ```

> `切入点（Pointcut）`：是指匹配连接点的一个断言。

- 通知是和一个切入点表达式关联的，并且在任何被切入点匹配的连接点上运行。

- AOP的核心就是`切入点表达式 匹配 连接点的思想`。Spring默认使用`AspectJ`切入点表达式语言

  - 连接点是系统存在的那个方法

  - 我们知道这个方法在哪里,要想AOP锁定这个方法在哪里,要靠一段切入点表达式来指明连接点的位置

    ```java
    //com.service包下的所有类的所有函数。
    @Pointcut("execution(* com.service..*(..))")
    ```

> `引入（Introduction）`：代表了对一个类型额外的方法或者属性的声明。

- Spring AOP允许**引入新接口**到任何被通知对象。

- [Spring](https://so.csdn.net/so/search?q=Spring&spm=1001.2101.3001.7020)为我们提供了一个注解`@DeclareParents`来定义需要`introduce`（引入）新的接口实现的类、以及默认的接口实现类型。

```java
@DeclareParents(value="com.service.*+", defaultImpl=DefaultRunInterface.class)	
//所有`com.service`包下的类及其子类均新增对`RunInterface`接口的实现
//默认实现类为`DefaultRunInterface`
public static RunInterface runInterface;
```

```java
//需要引入的接口
public interface RunInterface {
	void run();
}
//引入接口的实现类,这个类的实现方法,就会加到指定的类里面,对指定的类动态加了方法
public class DefaultRunInterface implements RunInterface {
	@Override
	public void run() {
		System.out.println("default run method");
	}
}
```

> `目标对象（Target object）`：是指被一个或多个切面通知的那个对象。

- 也指被通知对象，由于Spring AOP是通过运行时代理事项的，这个目标对象往往是一个`代理对象`。
  - 我们要在对象A的test方法切入`@Before`一个方法
  - 对象A就是目标对象

> `AOP 代理（AOP proxy）`：是指通过AOP框架创建的对象，用来实现切面通知方法等。

- 在Spring框架中，一个AOP代理是一个`JDK动态代理`或者是一个`CGLIB代理`。
  - 切面对象

> `织入（Weaving）`：将切面和其他应用类型或者对象连接起来，创骗一个被通知对象。

- 这些可以在编译时（如使用AspectJ编译器）、加载时或者运行时完成。
- Spring AOP，比如其他纯Java AOP框架一般是在`运行时`完成织入。

> `通知的方法`

- `前置通知（Before advice）`：在一个连接点之前执行的通知。
  - 但这种通知不能阻止连接点的执行流程（除非它抛出一个异常）

- `后置返回通知（After returning advice）`：在一个连接点正常完成后执行的通知
  - 如果一个连接点方法没有抛出异常的返回

- `后置异常通知（After throwing advice）`：在一个方法抛出一个异常退出时执行的通知。

- `后置（最终）通知（After(finally) advice）`：在一个连接点退出时（不管是正常还是异常返回）执行的通知。

- `环绕通知（Around advice）`：环绕一个连接点的通知，比如方法的调用。
  - 这是一个最强大的通知类型。
  - 环绕通知可以在方法**调用之前和之后**完成自定义的行为。
  - 也负责通过返回自己的返回值或者抛出异常这些方式，`选择是否继续执行连接点`或者简化被通知方法的执行。

## 补充: 切入点表达式

- **execution：一般用于`指定方法`的执行，用的最多。**
- within：指定某些类型的`全部方法`执行，也可用来指定一个包。
- this：Spring Aop是基于动态代理的，生成的bean也是一个代理对象，this就是这个代理对象，当这个对象可以转换为指定的类型时，对应的切入点就是它了，Spring Aop将生效。
- target：当被代理的对象可以转换为指定的类型时，对应的切入点就是它了，Spring Aop将生效。
- args：当执行的方法的参数是`指定类型时生效`。
- @target：当代理的`目标对象`上拥有`指定的注解`时生效
  - 必须是目标对象的类上有指定的注解。
- @args：当执行的方法`参数类型`上拥有`指定的注解`时生效。
- @within：只需要`目标对象`的**类或者父类上有指定的注解**时生效
- @annotation：当执行的`方法`上拥有`指定的注解`时生效。
- reference pointcut：(`经常使用`)表示引用`其他命名切入点`，@ApectJ风格支持
- bean：当调用的方法是`指定的bean的方法`时生效。

> **execution**  -> 一般用于`指定方法`的执行，用的最多

```javascript
//表示匹配所有方法  
execution(* *(..))  
//表示匹配rod.spring.Aop中所有的公有方法  
execution(public * rod.spring.Aop.*(..))  
//表示匹配rod.spring.Aop包及其子包下的所有方法
execution(* rod.spring.Aop..*.*(..))  
```

```java
// 签名：消息发送切面
@Pointcut("execution(* rod.spring.aop.*(..))")
private void logAop(){}
// 签名：消息接收切面
@Pointcut("execution(* rod.spring.aop2.*(..))")
private void logAop2(){}
// 只有满足logAop或者logAop2这个切面都会切进去,&&、||、! 都可以使用
@Pointcut("logAop() || logAop2()")
private void logMessage(){}
```

> **within** -> 指定某些类型的`全部方法`执行，也可用来指定一个包

```java
// AopController下面所有外部调用方法，都会拦截。
//备注：只能是AopController的方法，子类不会拦截的,此处只能写实现类,接口无效
@Pointcut("within(rod.spring.aop.AopController)")
public void pointCut() {
}
//匹配包以及子包内的所有类
@Pointcut("within(rod.spring.aop..*)")
public void pointCut() {
}
```

> **this** -> Spring Aop是基于代理的，this就表示代理对象。

```java
// 这样子，就可以拦截到AopController(可以是接口)所有的子类的所有外部调用方法
@Pointcut("this(rod.spring.aop.AopController*)")
public void pointCut() {
}
```

> **target** -> Spring Aop是基于代理的，target则表示被代理的目标对象。

```java
//只能是实现类   
@Pointcut("target(rod.spring.aop.AopController)")
public void pointCut() {
}
```

> **args** -> args用来匹配方法参数的。

```java
//args() 					-> 无参
//args(java.lang.String) 	-> 匹配任何只带一个String参数
//args(…) 					-> 带任意参数的方法
//args(java.lang.String,…)  -> 匹配带任意个参数，但是第一个参数的类型是String的方法。
//args(…,java.lang.String)  -> 匹配带任意个参数，但是最后一个参数的类型是String的方法。
//这个匹配的范围非常广，所以一般和别的表达式结合起来使用
@Pointcut("args()")
public void pointCut() {
}
```

> **@target** -> 匹配当被代理的目标对象对应的类型及其父类型上拥有指定的注解时。

```java
//类上(非方法上)Test注解的所有外部调用方法
@Pointcut("@target(rod.spring.aop.Test)")
public void pointCut() {
}
```

> **@args** -> 匹配被调用的方法上含有参数，且对应的参数类型上拥有指定的注解的情况。

```java
// 匹配方法(非类)参数类型上拥Test注解的方法调用。
//如我们有一个方法add(MyParam param)接收一个MyParam类型的参数
//而MyParam这个类是拥有注解Test的，则它可以被Pointcut表达式匹配上
@Pointcut("@args(rod.spring.aop.Test)")
public void pointCut() {
}
```

> **@annotation** -> 用于匹配**方法上**拥有指定注解的情况（使用得非常多）。

```java
// 可以匹配所有方法上标有此注解的方法
@Pointcut("@annotation(rod.spring.aop.Test)")
public void pointCut() {
}
```

> **reference pointcut** -> **切入点引用（使用得非常多）**

```java
@Pointcut("execution(* rod.spring.aop.*.*(..)) ")
public void point() {
}

// 这个就是一个`reference pointcut`
// 甚至还可以这样 @Before("point1() && point2()")
@Before("point()")  
public void before() {
    System.out.println("this is from HelloAspect#before...");
}
```

> **bean** -> **这是Spring增加的一种方法，spring独有**

```java
// 这个就能切入到AopController类的素有的外部调用的方法里
@Pointcut("bean(AopController)")
public void pointCut() {
}
```

****

#### 类型匹配语法

- `*`：匹配任何数量字符；
- ` …`：匹配任何数量字符的重复，如在类型模式中匹配任何数量子包；而在方法参数模式中匹配任何数量参数。 
- `+`：匹配指定类型的**子类型**；仅能作为**后缀放在类型模式后边**。

#### 表达式的组合

- `bean(userService) && args()`
  - 匹配id或name为userService的bean的所有无参方法。 
- `bean(userService) || @annotation(MyAnnotation)`
  - 匹配id或name为userService的bean的方法调用，或者是方法上使用了MyAnnotation注解的方法调用。 
- `bean(userService) && !args()`
  - 匹配id或name为userService的bean的所有有参方法调用。

