# BeanFactory 与FactoryBean有什么区别？

> Bean Factory是一个接口,Factory是工厂,Bean Factory其实就是一个`工厂接口`

- BeanFactory: IOC容器的核心接口，定义了getBean()、containsBean()等管理Bean的通用方法。
- BeanFactory就是一个`工厂接口`,IOC容器其实就`像一个工厂`,用来生产一些Bean
  - Bean工厂和Bean容器实际上意思差不多
- 那么BeanFactory作为一个接口,其实就是给`Bean容器制定规范的`
- 结论: **BeanFactory 是给 IOC容器制定规范的**
  - 规定了IOC容器有getBean()这样获取Bean丶管理Bean的方法

> FactoryBean也是一个接口,**它说出花来,它也是用来制定规范的**

- FactoryBean是用来制定谁的规范的?
  - 是一个Bean的规范,这个Bean的名字叫做工厂

- 所以FactoryBean的理解就是`给一类叫做工厂的特殊的Bean做规范的`

**所以我们可以得出这样一个结论**

- IOC容器生产的Bean`有普通的Bean,有稍微特殊的Bean叫工厂Bean`,
- 工厂Bean又可以生产出有**其他特点的Bean对象**
- `实现了FactoryBean接口的工厂Bean可以生产特殊的Bean`
- 这些特殊的Bean是什么?
  - **AOP的Bean对象就是则类特殊的Bean**
  - 我们自己随便弄的Bean就是普通的Bean
- 我们要将普通的Bean变成**AOP的代理Bean**,就要通过反射动态生成一个实现了FactoryBean的代理类
- 类似的还有事务相关的Bean
- 注意: FactoryBean使用了工厂模式和装饰者模式
  - 将一个普通的Bean包装成一个功能较多的Bean用的就是装饰者模式

> 区别

- BeanFactory 和 FactoryBean都是工厂接口
  - BeanFactory 说的是`IOC容器`,是给**生产普通Bean**做规范的
  - FactoryBean说的是**容器中的工厂Bean**,是给**生产特殊的Bean**做规范的

