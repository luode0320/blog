# Spring Boot ⾃动配置原理？ 

-  **`SpringBootApplication`** -> 启动类最头上的哪个注解
- 它是 `@Configuration`、`@EnableAutoConfiguration`、`@ComponentScan` 注解的集合
  - @Configuration -> 允许在上下文中自己注册的 bean 或导入其他配置类
  - @ComponentScan -> 扫描被`@Component`注解的 bean
  - @EnableAutoConfiguration -> **启用 SpringBoot 的自动配置机制**
- EnableAutoConfiguration 这也是一个组合的注解
- 反正最终就是用`@Import`这个注解导入了2个类
  - 一个类是将我们当前包下的Bean扫描注册到容器 -> `AutoConfigurationPackages.Registrar.class`
  - 另一个类就是有个方法会将超级多的类加载到容器中,这个方法会在run方法执行的时候被调用到
    - `spring.factories` -> 配置文件里面很多要加载的类
    - 不仅Spring Boot自动配置包下面又这个文件，所有starter包都会有一个这个文件
    - 我们自己写一个starter也要一个这样的文件去加载的
    - 读取所有`需要`自动装配的配置类
  - 并不会到加载，会根据`@ConditionalOnXXX`注解的条件去判断哪些是我们需要用的才加载的

> `@Import + @Configuration + Spring spi `

- `⾃动配置类由各个starter提供`，使⽤**@Configuration + @Bean定义配置类**
- 放到META-INF/spring.factories下 

- 使⽤@Import导⼊⾃动配置类 

> 什么是 SpringBoot 自动装配

- **通过注解或者一些简单的配置就能在 Spring Boot 的帮助下实现某块功能**
  - Redis丶AOP丶Rabbit丶Kafka丶jdbc丶Elasticsearch等100来个呢
  - 只要引入一个starter就可以在自动装配时生效



**AutoConfigurationImportSelector**

```java
@Override
public String[] selectImports(AnnotationMetadata annotationMetadata) {
	//检查自动配置功能是否开启，默认开启
	if (!isEnabled(annotationMetadata)) {
		return NO_IMPORTS;
	}
	//加载自动配置的元信息
	AutoConfigurationMetadata autoConfigurationMetadata = AutoConfigurationMetadataLoader
			.loadMetadata(this.beanClassLoader);
	AnnotationAttributes attributes = getAttributes(annotationMetadata);
	//获取候选配置类
	List<String> configurations = getCandidateConfigurations(annotationMetadata,
			attributes);
	//去掉重复的配置类
	configurations = removeDuplicates(configurations);
	//获得注解中被exclude和excludeName排除的类的集合
	Set<String> exclusions = getExclusions(annotationMetadata, attributes);
	//检查被排除类是否可实例化、是否被自动注册配置所使用，不符合条件则抛出异常
	checkExcludedClasses(configurations, exclusions);
	//从候选配置类中去除掉被排除的类
	configurations.removeAll(exclusions);
	//过滤
	configurations = filter(configurations, autoConfigurationMetadata);
	//将配置类和排除类通过事件传入到监听器中
	fireAutoConfigurationImportEvents(configurations, exclusions);
	//最终返回符合条件的自动配置类的全限定名数组
	return StringUtils.toStringArray(configurations);
}
```