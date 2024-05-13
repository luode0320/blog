# 什么是Mybatis

> 如何获得Mybatis

- maven仓库：

```xml
<!-- https://mvnrepository.com/artifact/org.mybatis/mybatis -->
        <dependency>
            <groupId>org.mybatis</groupId>
            <artifactId>mybatis</artifactId>
            <version>3.5.6</version>
        </dependency>
```

- 中文文档：https://mybatis.org/mybatis-3/zh/index.html
- Github:https://github.com/mybatis/mybatis-3

# 持久化

> 数据持久化

- 持久化就是将程序的数据在持久状态和瞬时状态转化的过程
- 内存：**断电即失**
- 数据库（Jdbc），io文件持久化
- 生活方面例子：冷藏，罐头。

**为什么需要持久化？**

- 不想丢掉一些对象
- 内存太贵

# 持久层

Dao层，Service层，Controller层…

- 完成持久化工作的代码块
- 层界限十分明显

# 为什么需要Mybatis？

- 帮助程序猿将数据存入到数据库中
- 方便
- 传统的JDBC代码太复杂，简化–>框架–>自动化

**最重要的一点：使用的人多！**
Spring-SpringMVC-SpringBoot

# 第一个Mybatis程序

**思路：搭建环境–>导入Mybatis–>编写代码–>测试**

# 搭建环境

搭建数据库
新建项目

- 新建一个普通maven项目
- 删除src目录
- 导入maven依赖

```xml
<!--import dependencies-->
    <dependencies>
        <!--mysql driver-->
        <dependency>
            <groupId>mysql</groupId>
            <artifactId>mysql-connector-java</artifactId>
            <version>5.1.47</version>
        </dependency>
        <!--mybatis-->
        <!-- https://mvnrepository.com/artifact/org.mybatis/mybatis -->
        <dependency>
            <groupId>org.mybatis</groupId>
            <artifactId>mybatis</artifactId>
            <version>3.5.6</version>
        </dependency>
        <!--junit-->
        <dependency>
            <groupId>junit</groupId>
            <artifactId>junit</artifactId>
            <version>4.12</version>
        </dependency>
    </dependencies>
```

# 创建一个模块

- 编写mybatis的核心配置文件

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE configuration
        PUBLIC "-//mybatis.org//DTD Config 3.0//EN"
        "http://mybatis.org/dtd/mybatis-3-config.dtd">
<!--configuration core file-->
<configuration>

    <environments default="development">
        <environment id="development">
            <transactionManager type="JDBC"/>
            <dataSource type="POOLED">
                <property name="driver" value="com.mysql.jdbc.Driver"/>
                <property name="url" value="jdbc:mysql://localhost:3306/mybatis?useSSL=false&amp;useUnicode=true&amp;characterEncoding=UTF-8"/>
                <property name="username" value="root"/>
                <property name="password" value="123456"/>
            </dataSource>
        </environment>
    </environments>

    <!--a Mapper.xml need regist in Mybatis core configuration file-->
    <mappers>
        <mapper resource="com/kuang/dao/UserMapper.xml"/>
    </mappers>
</configuration>
```

此处设useSSL=false。

- 编写mybatis工具类

```java
//SqlSessionFactory -->SqlSession
public class MybatisUtils {

    private static SqlSessionFactory sqlSessionFactory;
    static {

        try {
            //使用Mybaties第一步：获取sqlSessionFactory对象
            String resource = "mybatis-config.xml";
            InputStream inputStream = Resources.getResourceAsStream(resource);
            sqlSessionFactory = new SqlSessionFactoryBuilder().build(inputStream);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    //既然有了 SqlSessionFactory，顾名思义，我们可以从中获得 SqlSession 的实例。
    // SqlSession 提供了在数据库执行 SQL 命令所需的所有方法。你可以通过 SqlSession 实例来直接执行已映射的 SQL 语句。
    public static SqlSession getSqlSession(){
//        SqlSession sqlSession =  sqlSessionFactory.openSession();
//        return sqlSession;

        return sqlSessionFactory.openSession();
    }

}
```

# 编写代码

- 实体类

```java
//实体类
public class User {
    private int id;
    private String name;
    private String pwd;
}
```

- Dao接口

```java
public interface UserDao {
    List<User> getUserList();
}
```

- 接口实现类由原来的UserDaoImpl转变成一个Mapper配置文件。

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE mapper
        PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN"
        "http://mybatis.org/dtd/mybatis-3-mapper.dtd">

<mapper namespace="com.kuang.dao.UserDao">

    <!--sql-->
    <select id="getUserList" resultType="com.kuang.pojo.User">
        select * from mybatis.user
    </select>
</mapper>
```

# 测试

**注意点：**

`org.apache.ibatis.binding.BindingException: Type interface com.kuang.dao.UserDao is not known to the MapperRegistry`

> MapperRegistry是什么？

- 核心配置文件中注册mappers

- junit测试
  

```java
@Test
    public void test(){
        //第一步：获得SqlSession对象
        SqlSession sqlSession = MybatisUtils.getSqlSession();

        //方式一：getMapper
        UserDao userDao = sqlSession.getMapper(UserDao.class);
        List<User> userList = userDao.getUserList();

        for (User user : userList) {
            System.out.println(user);
        }

        //关闭SqlSession
        sqlSession.close();
        
    }
```

可能遇到的问题：

1. 配置文件没有注册；
2. 绑定接口错误；
3. 方法名不对；
4. 返回类型不对；
5. Maven导出资源问题。

# CRUD

>  namespace

- namespace中的包名要和Dao/Mapper接口的包名一致！

### select

选择，查询语句；

- id:就是对应的namespace中的方法名；
- resultType:Sql语句执行的返回值！
- parameterType:参数类型！

编写接口

```java
//根据id查询用户
    User getUserById(int id);
```

编写对应的mapper中的sql语句

```xml
	<select id="getUserById" parameterType="int" resultType="com.kuang.pojo.User">
        select * from mybatis.user where id = #{id}
	</select>
```

测试

```java
@Test
    public void getUserById(){
        SqlSession sqlSession = MybatisUtils.getSqlSession();

        UserMapper mapper = sqlSession.getMapper(UserMapper.class);
        User user = mapper.getUserById(1);
        System.out.println(user);

        //关闭SqlSession
        sqlSession.close();
    }
```

### Insert

```xml
	<insert id="addUser" parameterType="com.kuang.pojo.User">
        insert into mybatis.user (id,name,pwd) values (#{id},#{name},#{pwd})
    </insert>
```

### Update

```xml
	<update id="updateUser" parameterType="com.kuang.pojo.User">
        update mybatis.user set name=#{name},pwd=#{pwd} where id = #{id}
    </update>
```

### Delete

```xml
	<delete id="deleteUser" parameterType="int">
        delete from mybatis.user where id = #{id}
    </delete>
```

注意点：

- 增删改需要提交事务！

# 分析错误

1. xml文件中注释不能出现中文报错，查看自己的是UTF-8还是GBK编码，改成为相应的就行。

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<?xml version="1.0" encoding="GBK" ?>
```

即可成功测试。

1. 标签不要匹配错！
2. resource绑定mapper，需要使用路径！
3. 程序配置文件必须符合规范！
4. NullPointerException，没有注册到资源！
5. maven资源没有导出问题！

# 万能Map

假设，我们的实体类，或者数据库中的表，字段或者参数过多，我们应当考虑使用Map！

```java
	//万能的Map
    int addUser2(Map<String,Object> map);
```

```xml
<!--对象中的属性，可以直接取出来  传递map的key-->
    <insert id="addUser2" parameterType="map">
        insert into mybatis.user (id,pwd) values (#{userid},#{password})
    </insert>
```

```java
@Test
     public void addUser2(){
         SqlSession sqlSession = MybatisUtils.getSqlSession();

         UserMapper mapper = sqlSession.getMapper(UserMapper.class);
         Map<String,Object> map = new HashMap<String, Object>();
         map.put("userid",4);
         map.put("password","123321");

         mapper.addUser2(map);


         sqlSession.commit();
         sqlSession.close();
     }
```

- Map传递参数，直接在sql中取出key即可！【parameterType=“map”】
- 对象传递参数，直接在sql中取对象的属性即可！【parameterType=“Object”】
- 只有一个基本类型参数的情况下，可以直接在sql中取到！
- 多个参数用Map，**或者注解！**

# 思考题

模糊查询怎么写？

1. java代码执行的时候，传递通配符% % -> 建议

```java
List<User> userList = mapper.getUserLike("%李%");
```

2. 在sql拼接中使用通配符！ -> 不建议

```sql
select * from mybatis.user where name like "%"#{value}"%"
```

# 配置解析

###  核心配置文件(mybatis-config.xml)

- MyBatis的配置文件包含了会深深影响MyBatis行为的设置和属性信息。

```xml
configuration（配置）
properties（属性）
settings（设置）
typeAliases（类型别名）
typeHandlers（类型处理器）
objectFactory（对象工厂）
plugins（插件）
environments（环境配置）
environment（环境变量）
transactionManager（事务管理器）
dataSource（数据源）
databaseIdProvider（数据库厂商标识）
mappers（映射器）
```

### 环境配置（environments）

- Mybatis可以配置成适应多种环境
- **不过要记住：尽管可以配置多个环境，但每个SqlSessionFactory实例只能选择一种环境。**
- 学会使用配置多套运行环境！
- Mybatis默认的事务管理器就是JDBC,连接池：POOLED

### 属性（properties）

- 我们可以通过properties属性来实现引用配置文件
- 这些属性都是可外部配置且可动态替换的，既可以在典型的Java属性文件中配置，亦可通过properties元素的子元素来传递。
- 【db.properties】编写一个配置文件
- db.properties

```properties
driver=com.mysql.jdbc.Driver
url=jdbc:mysql://localhost:3306/mybatis?useSSL=false&useUnicode=true&characterEncoding=UTF-8
username=root
password=123456
```

在核心配置文件中映入

```xml
	<!--引入外部配置文件-->
    <properties resource="db.properties">
        <property name="username" value="root"/>
        <property name="pwd" value="123123"/>
    </properties>
```

- 可以直接引入外部文件
- 可以在其中增加一些属性配置
- 如果两个文件有同一个字段，优先使用外部配置文件的！

### 类型别名（typeAliases）

- 类型别名是为Java类型设置一个短的名字。
- 存在的意义仅在于用来减少类完全限定名的冗余。

```xml
	<!--可以给实体类起别名-->
    <typeAliases>
        <typeAlias type="com.kuang.pojo.User" alias="User" />
    </typeAliases>
```

- 也可以指定一个包名，MyBatis会在包名下面搜索需要的JavaBean
- 比如：扫描实体类的包，它的默认别名就为这个类的类名，首字母小写！

```xml
	<!--可以给实体类起别名-->
    <typeAliases>
        <package name="com.kuang.pojo"/>
    </typeAliases>
```

- 在实体类比较少的时候，使用第一种方式。
- 如果实体类十分多，建议使用第二种。
- 第一种可以DIY别名，第二种则不行，如果非要改，需要在实体上增加注解

```java
@Alias("user")
//实体类
public class User {}
```

### 设置

这是MyBatis中极为重要的调整设置，它们会改变MyBatis的运行时行为。

![image-20220320223400889](../../../picture\image-20220320223400889.png)

### 其他配置

- typeHandlers（类型处理器）
- objectFactory（对象工厂）
- plugins（插件）
  1. mybatis-generator-core
  2. mybatis-plus
  3. 通用mapper

### 映射器（mappers）

- MapperRegistry：注册绑定我们的Mapper文件；

yml

```yml
mybatis:
  # 指定 mapper.xml 的位置
  mapper-locations: classpath:mybatis/mapper/*.xml
```

方式一：

```xml
    <!--每一个Mapper.xml都需要在Mybatis核心配置文件中注册！-->
    <mappers>
        <mapper resource="com/kuang/dao/UserMapper.xml"/>
    </mappers>
```

方式二：使用class文件绑定注册

```xml
    <!--每一个Mapper.xml都需要在Mybatis核心配置文件中注册！-->
    <mappers>
        <mapper class="com.kuang.dao.UserMapper"/>
    </mappers>
```

注意点：

- 接口和它的Mapper配置文件必须同名！
- 接口和它的Mapper配置文件必须在同一个包下!

方式三：使用扫描包进行注入绑定

```xml
    <!--每一个Mapper.xml都需要在Mybatis核心配置文件中注册！-->
    <mappers>
        <package name="com.kuang.dao"/>
    </mappers>
```

注意点：

- 接口和它的Mapper配置文件必须同名！
- 接口和它的Mapper配置文件必须在同一个包下!

### 生命周期和作用域

![在这里插入图片描述](../../../picture\20201023104621506.png)

- 生命周期和作用域是至关重要的，因为错误的使用会导致非常严重的并发问题。

> SqlSessionFactoryBuilder：

- 一旦创建了 SqlSessionFactory，就不再需要它了。
- 局部变量

> SqlSessionFactory：

- 说白就是可以想象为：数据库连接池。
- SqlSessionFactory 一旦被创建就应该在应用的运行期间一直存在，没有任何理由丢弃它或重新创建另一个实例。
- SqlSessionFactory 的最佳作用域是应用作用域。
- 最简单的就是使用单例模式或者静态单例模式。

> SqlSession：

- 连接到连接池的一个请求！
- SqlSession 的实例不是线程安全的，因此是不能被共享的，所以它的最佳的作用域是请求或方法作用域。
- 用完后需要赶紧关闭，否则资源被占用！

![在这里插入图片描述](../../../picture\20201023104427946.png)

这里的每一个Mapper，就代表一个具体的业务！

# 解决属性名和字段名不一致的问题

### 问题

数据库中的字段

![在这里插入图片描述](../../../picture\20201023111734299.png)

新建一个项目，拷贝之前的，测试实体类字段不一致的情况

```java
public class User {
    private int id;
    private String name;
    private String password;
}
```

测试出现问题

![在这里插入图片描述](../../../picture\2020102311202794.png)

```sql
select * from mybatis.user where id = #{id}
/* 类型处理器 */
select id,name,pwd from mybatis.user where id = #{id}
```

解决方法：

- 起别名

```xml
  <select id="getUserById" parameterType="int" resultType="user">
      select id,name,pwd as password from mybatis.user where id = #{id}
  </select>
```

- resultMap解决

结果集映射

```xml
id name pwd
id name password
```

```xml
    <!--  结果集映射  -->
    <resultMap id="UserMap" type="User">
        <!--column数据库中的字段，property实体类中的属性-->
        <result column="id" property="id" />
        <result column="name" property="name" />
        <result column="pwd" property="password" />
    </resultMap>

    <select id="getUserById" parameterType="int" resultMap="UserMap">
        select * from mybatis.user where id = #{id}
    </select>
```

- resultMap 元素是 MyBatis 中最重要最强大的元素。
- ResultMap 的设计思想是，对简单的语句做到零配置，对于复杂一点的语句，只需要描述语句之间的关系就行了。
- ResultMap 的优秀之处——你完全可以不用显式地配置它们。
- 如果这个世界总是这么简单就好了。

# 日志（2020-10-24）

### 日志工厂

如果一个数据库操作出现了异常，我们需要排错。日志就是最好的助手！
曾经：sout、debug
现在：日志工厂！

![在这里插入图片描述](../../../picture\20201024092353850.png)

- SLF4J
- LOG4J 【掌握】
- LOG4J2
- JDK_LOGGING
- COMMONS_LOGGING
- STDOUT_LOGGING【掌握】
- NO_LOGGING

在Mybatis中具体使用哪一个日志实现，在设置中设定！

> **STDOUT_LOGGING**标准日志输出

在mybatis-config.xml核心配置文件中，配置我们的日志！

```xml
    <settings>
        <setting name="logImpl" value="STDOUT_LOGGING"/>
    </settings>
```

![在这里插入图片描述](../../../picture\20201024094029735.png)

### Log4j

> 什么是Log4j？

- Log4j是Apache的一个开源项目，通过使用Log4j，我们可以控制日志信息输送的目的地是控制台、文件、GUI组件
- 我们也可以控制每一条日志的输出格式；
- 通过定义每一条日志信息的级别，我们能够更加细致地控制日志的生成过程。
- 可以通过一个配置文件来灵活地进行配置，而不需要修改应用的代码。

1. 先在pom.xml文件中导入log4j的依赖包

```xml
    <dependencies>
        <!-- https://mvnrepository.com/artifact/log4j/log4j -->
        <dependency>
            <groupId>log4j</groupId>
            <artifactId>log4j</artifactId>
            <version>1.2.17</version>
        </dependency>
    </dependencies>
```

2. 在resources文件夹下建立log4j.properties文件进行配置

```properties
#将等级为DEBUG的日志信息输出到console和file这两个目的地，console和file的定义在下面的代码
log4j.rootLogger = DEBUG,console ,file

#控制台输出的相关设置
log4j.appender.console = org.apache.log4j.ConsoleAppender
log4j.appender.console.Target = System.out
log4j.appender.console.Threshold = DEBUG
log4j.appender.console.layout = org.apache.log4j.PatternLayout
log4j.appender.console.layout.ConversionPattern =  [%c]-%m%n

#文件输出的相关设置
log4j.appender.file = org.apache.log4j.RollingFileAppender
log4j.appender.file.File = ./log/kuang.log
log4j.appender.file.MaxFileSize = 10mb
log4j.appender.file.Threshold = DEBUG
log4j.appender.file.layout = org.apache.log4j.PatternLayout
log4j.appender.file.layout.ConversionPattern = [%p][%d{yy-MM-dd}][%c]%m%n

#日志输出级别
log4j.logger.org.mybatis=DEBUG
log4j.logger.java.sql=DEBUG
log4j.logger.java.sql.Statement=DEBUG
log4j.logger.java.sql.ResultSet=DEBUG
log4j.logger.java.sql.PreparedStatement=DEBUG
```

3. 在mybatis-config.xml核心配置文件中，配置log4j为日志的实现！

```xml
    <settings>
        <setting name="logImpl" value="LOG4J"/>
    </settings>
```

4. Log4j的使用，直接测试运行

![在这里插入图片描述](../../../picture\20201024101856564.png)

**简单使用**

1. 在要使用Log4j的测试类中，导入包import org.apache.log4j.Logger;
2. 日志对象，参数为当前类的class

```java
static Logger logger = Logger.getLogger(UserDaoTest.class);
```

3. 日志级别

```java
        logger.info("info:进入了testLog4j");
        logger.debug("DEBUG:进入了testLog4j");
        logger.error("erro:进入了testLog4j");
```

4. 之后可在log文件夹中查看日志文件信息

# 分页

**思考：为什么要分页！**

- 减少数据的处理量

### 使用Limit分页

```sql
/* 语法：SELECT * from user limit startIndex,pageSize */
SELECT  * from user limit 3 #[0,n]
```

**使用Mybatis实现分页，核心SQL**

1. 接口

```java
    //分页
    List<User> getUserByLimit(Map<String,Integer> map);
```

2. Mapper.xml

```xml
<!--    分页-->
    <select id="getUserByLimit" parameterType="map" resultMap="UserMap">
        select * from mybatis.user limit #{startIndex},#{pageSize}
    </select>
```

3. 测试

```java
    @Test
    public void getUserByLimit(){
        SqlSession sqlSession = MybatisUtils.getSqlSession();
        UserMapper mapper = sqlSession.getMapper(UserMapper.class);

        HashMap<String, Integer> map = new HashMap<String, Integer>();
        map.put("startIndex",0);
        map.put("pageSize",2);

        List<User> userList = mapper.getUserByLimit(map);
        for (User user : userList) {
            System.out.println(user);
        }
        
        sqlSession.close();
    }
```

### RowBounds分页(不推荐)

不再使用SQL实现分页

1. 接口

```java
    //分页2
    List<User> getUserByRowBounds();
```

2. Mapper.xml

```xml
<!--    分页2-->
    <select id="getUserByRowBounds" resultMap="UserMap">
        select * from mybatis.user
    </select>
```

3. 测试

```java
    @Test
    public void getUserByRowBounds(){
        SqlSession sqlSession = MybatisUtils.getSqlSession();

        //RowBounds实现
        RowBounds rowBounds = new RowBounds(0, 2);

        //通过java代码层面实现分页
        List<User> userList = sqlSession.selectList("com.kuang.dao.UserMapper.getUserByRowBounds",null,rowBounds);

        for (User user : userList) {
            System.out.println(user);
        }
        
        sqlSession.close();
    }
```

### 分页插件

![在这里插入图片描述](../../../picture\20201024131905259.png)

了解即可，使用时，需要知道是什么东西！

# 使用注解开发

### 面向接口编程

- 之前学过面向对象编程，也学习过接口，但在真正的开发中，很多时候会选择面向接口编程。
- 根本原因：解耦，可拓展，提高复用，分层开发中，上层不用管具体的实现，大家都遵守共同的标准，使得开发变得容易，规范性更好
- 在一个面向对象的系统中，系统的各种功能是由许许多多的不同对象协作完成的。
- 在这种情况下，各个对象内部是如何实现自己的，对系统设计人员来讲就不那么重要了；
- 而各个对象之间的协作关系则成为系统设计的关键。
- 小到不同类之间的通信，大到各模块之间的交互，在系统设计之初都是要着重考虑的，这也是系统设计的主要工作内容。
- 面向接口编程就是指按照这种思想来编程。
  

### 使用注解开发

1. 注解在UserMapper接口上实现，并删除UserMapper.xml文件

```java
    @Select("select * from user")
    List<User> getUsers();
```

2. 需要在mybatis-config.xml核心配置文件中绑定接口 -> SpringBoot加上注解也行

```xml
    <!--绑定接口！-->
    <mappers>
        <mapper class="com.kuang.dao.UserMapper" />
    </mappers>
```

3. 测试

```java
    @Test
    public void getUsers(){
        SqlSession sqlSession = MybatisUtils.getSqlSession();
        UserMapper mapper = sqlSession.getMapper(UserMapper.class);
        List<User> users = mapper.getUsers();

        for (User user : users) {
            System.out.println(user);
        }

        sqlSession.close();
    }
```

本质：反射机制实现
底层：动态代理！

**Mybatis详细的执行流程！（之后应用的多了详细再走一遍）**

### CRUD

1. 在MybatisUtils工具类创建的时候实现自动提交事务！

```java
    public static SqlSession getSqlSession(){
        return sqlSessionFactory.openSession(true);
    }
```

2. 编写接口，增加注解

```java
public interface UserMapper {

    @Select("select * from user")
    List<User> getUsers();

    //方法存在多个参数，所有参数前面必须加上@Param("id")注解
    @Select("select * from user where id=#{id}")
    User getUserById(@Param("id") int id);

    @Insert("insert into user (id,name,pwd) values(#{id},#{name},#{password})")
    int addUser(User user);

    @Update("update user set name=#{name},pwd=#{password} where id=#{id}")
    int updateUser(User user);

    @Delete("delete from user where id = #{uid}")
    int deleteUser(@Param("uid") int id);
    
}
```

3. 测试类

【注意：我们必须要将接口注册绑定到我们的核心配置文件中！】

- 关于`@Param()`注解
- 基本类型的参数或者String类型，需要加上
- 引用类型可以不加,加了就是一个别名在SQL中使用
- 如果只有一个基本类型的话，可以忽略，但是建议都加上！
- 我们在`SQL中引用的`就是我们这里的@Param("")中设定的属性名！
- #{}和${}区别

# Lombok（偷懒的话可以使用）

使用步骤：

1. 在IDEA中安装Lombok插件！
2. 在项目pom.xml文件中导入Lombok的jar包

```xml
        <!-- https://mvnrepository.com/artifact/org.projectlombok/lombok -->
        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <version>1.18.10</version>
        </dependency>
```

```java
@Data
@AllArgsConstructor
@NoArgsConstructor
@Getter and @Setter
@FieldNameConstants
@ToString
@EqualsAndHashCode
@AllArgsConstructor, @RequiredArgsConstructor and @NoArgsConstructor
@Log, @Log4j, @Log4j2, @Slf4j, @XSlf4j, @CommonsLog, @JBossLog, @Flogger, @CustomLog
@Data
@Builder
@SuperBuilder
@Singular
@Delegate
@Value
@Accessors
@Wither
@With
@SneakyThrows
```

说明：

```java
@Data:无参构造、get、set、toString、hashCode、equals
@AllArgsConstructor
@NoArgsConstructor
@EqualsAndHashCode
@ToString
@Getter and @Setter
```

# 多对一处理

多对一：

- 多个学生，对应一个老师
- 对于学生而言，**关联**–多个学生，关联一个老师【多对一】
- 对于老师而言，**集合**–一个老师，有很多个学生【一对多】

SQL语句：

```sql
CREATE TABLE `teacher` (
	`id` INT(10) NOT NULL,
	`name` VARCHAR(30) DEFAULT NULL,
	PRIMARY KEY (`id`)
)ENGINE = INNODB DEFAULT CHARSET=utf8

INSERT INTO teacher(`id`,`name`) VALUES (1,'秦老师');

CREATE TABLE `student` (
	`id` INT(10) NOT NULL,
	`name` VARCHAR(30) DEFAULT NULL,
	`tid` INT(10) DEFAULT NULL,
	PRIMARY KEY (`id`),
	KEY `fktid`(`tid`),
	CONSTRAINT `fktid` FOREIGN KEY (`tid`) REFERENCES `teacher` (`id`)
)ENGINE = INNODB DEFAULT CHARSET=utf8

INSERT INTO `student`(`id`,`name`,`tid`) VALUES ('1','小明','1');
INSERT INTO `student`(`id`,`name`,`tid`) VALUES ('2','小红','1');
INSERT INTO `student`(`id`,`name`,`tid`) VALUES ('3','小张','1');
INSERT INTO `student`(`id`,`name`,`tid`) VALUES ('4','小李','1');
INSERT INTO `student`(`id`,`name`,`tid`) VALUES ('5','小王','1');
```

### 测试环境搭建

1. 导入Lombok
2. 新建实体类Teacher，Student
3. 建立Mapper接口
4. 建立Mapper.XML文件
5. 在核心配置文件中绑定注册我们的Mapper接口或者文件！【方式很多,随心选】
6. 测试查询是否能够成功！

### 按照结果嵌套处理

```xml
    <!--按照结果嵌套处理 s  t  association:关联-->
    <select id="getStudent2" resultMap="StudentTeacher2">
        select s.id sid,s.name sname,t.name tname
        from mybatis.student s,mybatis.teacher t
        where s.tid = t.id
    </select>

    <resultMap id="StudentTeacher2" type="Student">
        <result property="id" column="sid"/>
        <result property="name" column="sname"/>
        <association property="teacher" javaType="Teacher">
            <result property="name" column="tname"/>
        </association>
    </resultMap>
```

### 按照查询嵌套处理

```xml
    <!--
      思路：
          1.查询所有的学生信息
          2.根据查询出来的学生的tid，寻找对应的老师！ 子查询-->
    <select id="getStudent" resultMap="StudentTeacher">
        select * from mybatis.student
    </select>

    <resultMap id="StudentTeacher" type="Student">
        <result property="id" column="id"/>
        <result property="name" column="name"/>
        <!--  复杂的属性，我们需要单独处理 对象：association 集合：collection      -->
        <association property="teacher" column="tid" javaType="Teacher" select="getTeacher"/>
    </resultMap>

    <select id="getTeacher" resultType="Teacher">
        select * from mybatis.teacher where id = #{id}
    </select>
```

回顾Mysql多对一查询方式：

- 子查询
- 联表查询

# 一对多处理

比如：一个老师拥有多个学生！
对于老师而言，就是一对多的关系！

### 环境搭建

1. 环境搭建，和刚才一样

   **实体类：**

```java
@Data
public class Student {
    private int id;
    private String name;
    private int tid;

}
@Data
public class Teacher {
    private int id;
    private String name;

    //一个老师拥有多个学生
    private List<Student> students;
}
```

### 按照结果嵌套处理

```xml
    <!--    按结果嵌套查询-->
    <select id="getTeacher" resultMap="TeacherStudent">
            SELECT  s.id sid,s.name sname,t.name tname,t.id,tid
            from student s,teacher t
            where s.tid = t.id and t.id = #{tid}
    </select>

    <resultMap id="TeacherStudent" type="Teacher">
        <result property="id" column="tid"/>
        <result property="name" column="tname"/>
        <!--  复杂的属性，我们需要单独处理 对象：association 集合：collection
             javaType="" 指定属性的类型！
             集合中的泛型信息，我们使用ofType获取
             -->
        <collection property="students" ofType="Student">
            <result property="id" column="sid"/>
            <result property="name" column="sname"/>
            <result property="tid" column="tid"/>
        </collection>
    </resultMap>
```

### 按照查询嵌套处理

```xml
    <select id="getTeacher2" resultMap="TeacherStudent2">
        select * from mybatis.teacher where id = #{tid}
    </select>

    <resultMap id="TeacherStudent2" type="Teacher">
        <collection property="students" javaType="ArrayList" ofType="Student" select="getStudentByTeacherId" column="id"/>
    </resultMap>

    <select id="getStudentByTeacherId" resultType="Student">
        select * from  mybatis.student where tid = #{tid}
    </select>
```

**小结**

- 关联-association【多对一】
- 集合-collection【一对多】
- javaType & ofType
- javaType 用来指定实体类中属性的类型
- ofType 用来指定映射到List或者集合中的pojo类型，泛型中的约束类型！
- **注意点：**

- 保证SQL的可读性，尽量保证通俗易懂
- 注意一对多和多对一中，属性名和字段的问题！
- 如果问题不好排查错误，可以使用日志，建议使用Log4j
- **面试高频**

- Mysql引擎
- InnoDB底层原理
- 索引
- 索引优化

# 动态SQL

**什么是动态SQL：动态SQL就是 指根据不同的条件生成不同的SQL语句**

利用动态SQL这一特性可以彻底摆脱这种痛苦。

- 在 MyBatis 之前的版本中，需要花时间了解大量的元素。借助功能强大的基于 OGNL 的表达式，MyBatis 3 替换了之前的大部分元素，大大精简了元素种类，现在要学习的元素种类比原来的一半还要少。

- if
- choose (when, otherwise)
- trim (where, set)
- foreach

### 搭建环境

```sql
CREATE TABLE `blog`(
	`id` VARCHAR(50) NOT NULL COMMENT '博客id',
	`title` VARCHAR(100) NOT NULL COMMENT '博客标题',
	`author` VARCHAR(30) NOT NULL COMMENT '博客作者',
	`create_time` DATETIME NOT NULL COMMENT '创建时间',
	`views` INT(30) NOT NULL COMMENT '浏览量'
)ENGINE=INNODB DEFAULT CHARSET=utf8
```

创建一个基础工程

1. 导包
2. 编写配置文件
3. 编写实体类

```java
@Data
public class Blog {
    private String id;
    private String title;
    private String author;
    private Date createTime; //属性名和字段名不一致
    private int views;
}
```

4. 编写实体类对应Mapper接口和Mapper.XML文件

### IF

```xml
    <select id="queryBlogIF" parameterType="map" resultType="Blog">
        select * from mybatis.blog where 1=1
        <if test="title != null">
            and title = #{title}
        </if>
        <if test="author != null">
            and author = #{author}
        </if>
    </select>
```

### choose (when, otherwise)

```xml
    <select id="queryBlogChoose" parameterType="map" resultType="Blog">
        select * from mybatis.blog
        <where>
            <choose>
                <when test="title != null">
                    title = #{title}
                </when>
                <when test="author != null">
                    and author = #{author}
                </when>
                <otherwise>
                    and views = #{views}
                </otherwise>
            </choose>
        </where>
    </select>
```

### trim (where, set)

```xml
    <select id="queryBlogIF" parameterType="map" resultType="Blog">
        select * from mybatis.blog
        <where>
            <if test="title != null">
                and title = #{title}
            </if>
            <if test="author != null">
                and author = #{author}
            </if>
        </where>

    </select>

    <update id="updateBlog" parameterType="map">
        update mybatis.blog
        <set>
            <if test="title != null">
                title = #{title},
            </if>
            <if test="author != null">
                author = #{author}
            </if>
        </set>
        where id = #{id}
    </update>
```

**所谓的动态SQL，本质还是SQL语句，只是我们可以在SQL层面，去执行一个逻辑代码**

### Foreach
- 动态 SQL 的另一个常见使用场景是对集合进行遍历（尤其是在构建 IN 条件语句的时候）。
- foreach 元素的功能非常强大，它允许你指定一个集合，声明可以在元素体内使用的集合项（item）和索引（index）变量。
- 它也允许你指定开头与结尾的字符串以及集合项迭代之间的分隔符。这个元素也不会错误地添加多余的分隔符，看它多智能！

- 提示你可以将任何可迭代对象（如 List、Set 等）、Map 对象或者数组对象作为集合参数传递给 foreach。
- 当使用可迭代对象或者数组时，index 是当前迭代的序号，item 的值是本次迭代获取到的元素。
- 当使用 Map 对象（或者 Map.Entry 对象的集合）时，index 是键，item 是值。
  

```xml
    <!--select * from blog where 1=1 and (id=1 or id=2 or id=3)
        我们现在传递一个万能的map，这map中可以存在一个集合！
        -->
    <select id="queryBlogForeach" parameterType="map" resultType="Blog">
        select * from mybatis.blog
        <where>
            <foreach collection="ids" item="id" open="and (" close=")" separator="or">
                id = #{id}
            </foreach>
        </where>
    </select>
```

- 动态SQL就是在拼接SQL语句，我们只要保证SQL的正确性，按照SQL的格式，去排列组合就可以了。
- **建议：**

- 先在Mysql中写出完整的SQL，再对应的去修改成我们的动态SQL实现通用即可！

### SQL片段

有的时候，我们可以能会将一些功能的部分抽取出来，方便复用！

1. 使用SQL标签抽取公共的部分

```xml
    <sql id="if-title-author">
        <if test="title != null">
            title = #{title}
        </if>
        <if test="author != null">
            and author = #{author}
        </if>
    </sql>
```

2. 在需要使用的地方使用Include标签引用即可

```xml
    <select id="queryBlogIF" parameterType="map" resultType="Blog">
        select * from mybatis.blog
        <where>
            <include refid="if-title-author"></include>
        </where>
    </select>
```

**注意事项：**

- 最好基于单表来定义SQL片段！
- 不要存在where标签

# 缓存（了解即可）

1. **什么是缓存[Cache]？**
   - 存在内存中的临时数据。
   - 将用户经常查询的数据放在缓存（内存）中，用户去查询数据就不用从磁盘上（关系型数据库查询文件）查询，从缓存中查询，从而提高查询效率，解决了高并发系统的性能问题。

2. **为什么使用缓存？**
- 减少和数据库的交互次数，减少系统开销，提高系统效率。
3. **什么样的数据能使用缓存？**
- 经常查询并且不经常改变的数据。【可以使用缓存】

> Mybatis缓存

- Mybatis包含一个非常强大的查询缓存特性，它可以非常方便地定制和配置缓存。缓存可以极大的提升查询效率。
- Mybatis系统中默认定义了两级缓存：一级缓存和二级缓存
- 默认情况下，只有一级缓存开启。（SqlSession级别的缓存，也称为本地缓存）
- 二级缓存需要手动开启和配置，它是基于namespace级别的缓存。
- 为了提高扩展性，Mybatis定义了缓存接口Cache，我们可以通过实现Cache接口来自定义二级缓存。

### 一级缓存

- 一级缓存也叫本地缓存：
- 与数据库同一次会话期间查询到的数据会放在本地缓存中。
- 以后如果需要获取相同的数据，直接从缓存中拿，没必要再去查询数据库

测试步骤：

- 开启日志！
- 测试在一个Session中查询两次相同记录
- 查看日志输出

![在这里插入图片描述](../../../picture\20201030104307657.png)

缓存失效的情况：

1. 查询不同的东西；
2. 增删改操作，可能会改变原来的数据，所以必定会刷新缓存！

![在这里插入图片描述](../../../picture\20201030105031892.png)

3. 查询不同的Mapper.xml

4. 手动清理缓存！

![在这里插入图片描述](../../../picture\20201030105220680.png)

**小结：**

- 一级缓存默认是开启的，只在一次SqlSession中有效，也就是拿到连接到关闭连接这个区间段！
- 一级缓存相当于一个Map。

### 二级缓存

- 二级缓存也叫全局缓存，一级缓存作用域太低了，所以诞生了二级缓存；
- 基于namespace级别的缓存，一个名称空间，对应一个二级缓存；
- **工作机制**
- 一个会话查询一条数据，这个数据就会被放在当前会话的一级缓存中；
- 如果当前会话关闭了，这个会话对应的一级缓存就没了；
- 但是我们想要的是，会话关闭了，一级缓存中的数据被保存到二级缓存中；
- 新的会话查询信息，就可以从二级缓存中获取内容；
- 不同的mapper查出的数据就会放在自己对应的缓存（map）中；
- **步骤：**

1. 在mybatis-config.xm开启全局缓存

```xml
        <!--显示的开启全局缓存-->
        <setting name="cacheEnabled" value="true"/>
```

2. 在要使用二级缓存的Mapper中开启

```xml
    <!--在当前Mapper.xml中使用二级缓存-->
    <cache/>
```

也可以自定义参数

```xml
    <!--在当前Mapper.xml中使用二级缓存-->
    <cache
            eviction="FIFO"
            flushInterval="60000"
            size="512"
            readOnly="true"/>
```

3. 测试

问题：如果没有自定义参数，则会报错，我们需要将实体类序列化！

`Cause: java.io.NotSerializableException: com.kuang.pojo.User`

**小结：**

- 只要开启了二级缓存，在同一个Mapper下就有效；
- 所有的数据都会先放在一级缓存中；
- 只有当会话提交或者关闭的时候，才会提交到二级缓存中！
- 一般会用Redis了,Mybatis不能分布式保存

### 缓存原理

![在这里插入图片描述](../../../picture\20201030140755274.png)

### 自定义缓存-ehcache（可以了解）

Ehcache是一种广泛使用的开源Java分布式缓存，主要面向通用缓存。

要在程序中使用ehcache，先要导包！

在mapper中指定使用我们的ehcache缓存实现！

**目前：Redis数据库来做缓存！K-V**

# Mybatis-puls

![在这里插入图片描述](../../../picture\20210518172357678.png)