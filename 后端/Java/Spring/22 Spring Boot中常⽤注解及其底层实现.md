# Spring Boot中常⽤注解及其底层实现 

- `@SpringBootApplication`注解：这个注解标识了⼀个SpringBoot⼯程，它实际上是另外三个注解的组合，这三个注解是： 
  - `@SpringBootConfiguration`：这个注解实际就是⼀个`@Configuration`，表示启动类也是⼀个 配置类 
  -  `@EnableAutoConfiguration`：向Spring容器中导⼊了⼀个Selector，⽤来加载ClassPath下Spring.Factories中所定义的⾃动配置类，将这些⾃动加载为配置Bean 
  - `@ComponentScan`：标识扫描路径，因为默认是没有配置实际扫描路径，所以SpringBoot扫描的路径是启动类所在的当前⽬录 
- `@Bean`注解：⽤来定义Bean，类似于XML中的<bean>标签，Spring在启动时，会对加了**@Bean注解**的⽅法进⾏解析，将⽅法的名字做为beanName，并通过执⾏⽅法得到bean对象 

-  `@Controller、@RestController`
  - SpringMVC子容器会将所有标注了Controller注解的类加载创建
  - 在DispatcherServlet执行到**HandlerMapping** 处理器映射器时将URL对应的Controller找到
- `@Component丶@Repository丶@Service`
  - SpringIOC容器启动时会见标注了这些注解的类创建为Bean
- `@RequestMapping丶@GetMapping丶@PostMapping`
  - 处理特点HTTP请求的注解
- `@RequestParam丶@PathVariable`
  - 注释在方法参数的 ->  **HandlerAdapter** 处理器适配器解析参数时判断
- `@ResponseBody`
  - 用于返回json数据的注解 -> **HandlerAdapter** 处理器适配器解析返回类型时判断
- `@Aspect丶@befor丶@after丶@Transactional`
  - 用于AOP的注解
  - AOP事务相关的注解
- `@Autowired丶@Value`
  - 用于依赖注入的注解
- `@Entity丶@Table丶@Id`
  - 用于实体类的注解

- `@Import`
  - 导入类注解