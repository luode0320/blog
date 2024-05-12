# Spring事务的实现⽅式和原理以及隔离级别？

>  在使⽤Spring框架时，可以有两种使⽤事务的⽅式，**⼀种是编程式的，⼀种是申明式的**

- Spring 并不直接支持事务，只有当数据库支持事务时,Spring 才支持事务
  - 数据库必须支持`执行sql`和`提交sql`的 **步骤可以分离**

- `@Transactional`注解就是申明式的。
  - @Transactional 注解和@EnableTransactionManagement（开启事务管理功能）
  - 它是基于 **Spring AOP** 实现的,搞一个专门针对事务的代理类
  - `before` -> sql执行前,关闭⾃动提交
  - `after` -> sql执行后,如果没有出现问题则提交,否则回滚

- 我们可以通过在**某个⽅法上增加@Transactional注解**，就可以`开启事务`，这个⽅法中**所有的sql**都会在⼀个事务中执⾏，统⼀成功或失败。 
  - 在⼀个⽅法上加了@Transactional注解后，**Spring会基于这个类⽣成⼀个代理对象**，会将这个代理对象作为bean
  - 当在使⽤这个代理对象的⽅法时，如果这个⽅法上存在`@Transactional`注解，那么代理`before()`会先把事务的`⾃动提交设置为false`
  - 然后再去执⾏原本的业务逻辑⽅法
  - 如果执⾏业务逻辑⽅法没有出现异常，那么代理`after()`中就会将`事务进⾏提交`
    - 出现了异常，那么则会将事务进⾏`回滚`。 

- 利⽤@Transactional注解中的`rollbackFor属性`进⾏配 置,对什么类型的异常执行回滚

  - 默认情况下会对**RuntimeException和Error进⾏回滚**。

  ```java
  @EnableTransactionManagement
  @Service
  public class 事务注解 {
      @Transactional(rollbackFor = Exception.class)
      public void add() throws Exception {
  
      }
  }
  ```

> spring事务隔离级别就是**数据库的隔离级别**

```java
@EnableTransactionManagement
@Service
public class 事务注解 {
    @Transactional(isolation = Isolation.READ_UNCOMMITTED)
    public void add() throws Exception {

    }
}
```

**事务隔离级别指的是`多个事务对同一份数据修改的隔离程度`**

- read uncommitted（`读 未提交`） 
  - 一个事务操作数据,其他事务都可以随便读
  - `脏读` `幻读` `不可重复读`

- read committed（`读 提交、不可重复读`）  -> 默认隔离级别: ORACLE（读已提交）
  - `幻读` `不可重复读`

- repeatable read（`可重复读`）  -> Spring默认隔离级别(以Spring为准)丶 MySQL（可重复读）
  - `幻读`

- serializable（`可串⾏化`） 
  - 单线程事务,一个事务执行完其他事务才允许执行,不会出现问题,但是慢

**如果没有隔离机制就会产生`脏读` `幻读` `不可重复读`的问题**

- 脏读: 指读到了其他事务未提交的数据,`数据是不准确的`,叫脏读
  - 简单理解为,内存中的数据已经发生了改变,但是你读到了缓存中的旧值
  - 避免脏读: 事务**一定要提交**

- 幻读: 官方定义 -> 当**同一个查询在不同的时间生成不同的行集**时，事务中就会出现所谓的幻象问题。
  - 例如，如果一个SELECT执行了两次，但第二次返回了第一次未返回的行，则该行是“幻影”行。
    - 行集 -> 行的集合,其实就是**表中多行结果组成的结果集**
  - 简单理解为,2次查询表中**多行数据或者全表数据**时,结果不一样了
  - 避免幻读: 要锁住被查的多行数据,或者锁住整个表

- 不可重复读: 前后多次读取，数据内容不一致,叫不可重复读
  - 简单理解为,我看第一眼是人,看第二眼变成了狗
  - 避免不可重复读: 要锁住这行数据,使事务连续读2次不会被修改

