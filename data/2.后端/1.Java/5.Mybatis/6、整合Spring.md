# 整合Spring

> MyBatis是一款非常优秀的持久层框架，SpringBoot官方虽然没有对MyBatis进行整合，但是MyBatis团队自行适配了对应的`启动器`，进一步简化了程序员使用MyBatis进行数据的操作。

### 数据库准备

使用MySQL，创建数据库**spring-boot-mybatis**，然后在该数据库中**创建两个表course和comment**，并向表中插入一些基础数据。

```sql
# 创建数据库
CREATE DATABASE spring-boot-mybatis; 

USE spring-boot-mybatis;

# 创建表course

DROP TABLE IF EXISTS user; 

CREATE TABLE user (
id int(20) NOT NULL AUTO_INCREMENT COMMENT '课程id', 
userName varchar COMMENT '课程内容',
PRIMARY KEY (id)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

INSERT INTO user VALUES ('1', '从入门到精通讲解...'); 
INSERT INTO user VALUES ('2', '从入门到精通讲解...');

```

### 创建对应的SpringBoot项目

### 编写与数据库对应的实体类(set和get方法省略）

```java
@Data
public class User  {
    private Integer id;
    private String userName;
}
```

## 引入依赖

```xml
<!--引入 mybatis-spring-boot-starter 的依赖-->
<dependency>
    <groupId>org.mybatis.spring.boot</groupId>
    <artifactId>mybatis-spring-boot-starter</artifactId>
    <version>2.2.0</version>
</dependency>
```

## 配置 MyBatis

- 在 Spring Boot 的配置文件（application.properties/yml）中对 MyBatis 进行配置，例如指定 mapper.xml 的位置、实体类的位置、是否开启驼峰命名法等等，示例代码如下。

```yml
###################################### MyBatis 配置######################################
mybatis:
  # 指定 mapper.xml 的位置
  mapper-locations: classpath:mybatis/mapper/*.xml
  #扫描实体类的位置,在此处指明扫描实体类的包，在 mapper.xml 中就可以不写实体类的全路径名
  type-aliases-package: net.biancheng.www.bean
  configuration:
    #默认开启驼峰命名法，可以不用设置该属性
    map-underscore-to-camel-case: true 
```

- 注意：使用 MyBatis 时，必须配置数据源信息
  - 例如数据库` URL`、数据库`用户`、数据库`密码`和数据库`驱动`等。

```yml
# MySQL数据库连接配置 
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/springbootmybatis?serverTimezone=UTC&characterEncoding=UTF-8
    username: root
    password: rootroot
```

### 创建course数据库对应的操作接口CourseMapper

```java
@Mapper
public interface CourseMapper {
    //通过id查询用户数据
    User selectUser(Integer id);
}
```

- 当 mapper 接口较多时，我们可以在 **Spring Boot 主启动类上使用 @MapperScan** 注解扫描指定包下的 mapper 接口，而不再需要在每个 mapper 接口上都标注 @Mapper 注解。

```java
@MapperScan("com.mapper")
@SpringBootApplication
public class Application {

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}
```

## 创建 Mapper 映射文件

- 在配置文件` application.properties/yml` 通过 `mybatis.mapper-locations `指定的位置中创建 UserMapper.xml -> **上面写过**

  ```yml
  mybatis:
    # 指定 mapper.xml 的位置
    mapper-locations: classpath:mybatis/mapper/*.xml
  ```

- 代码如下。

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
<!--namespace: 接口名称-->
mapper namespace="UserMapper">
    <resultMap id="BaseResultMap" type="User">
        <id column="id" jdbcType="INTEGER" property="id"/>
        <result column="user_name" jdbcType="VARCHAR" property="userName"/>
    </resultMap>
	<!--sql: 复用SQL-->
    <sql id="Base_Column_List">
        id, user_name
    </sql>
    <!--根据用户名密码查询用户信息-->
    <!--application.yml 中通过 type-aliases-package 指定了实体类的为了，因此-->
    <select id="getByUserNameAndPassword" resultType="User">
        select *
        from user
        where user_name = #{userName,jdbcType=VARCHAR}
          and password = #{password,jdbcType=VARCHAR}
    </select>
</mapper>
```

使用 Mapper 进行开发时，需要遵循以下规则：

- mapper 映射文件中 namespace 必须与对应的 mapper 接口的完全限定名一致。
- mapper 映射文件中 statement 的 id 必须与 mapper 接口中的方法的方法名一致
- mapper 映射文件中 statement 的 parameterType 指定的类型必须与 mapper 接口中方法的参数类型一致。
- mapper 映射文件中 statement 的 resultType 指定的类型必须与 mapper 接口中方法的返回值类型一致。



1. 在 spring-boot-adminex 项目中创建一个名为 UserService 的接口，代码如下。

```java
public interface UserService {
    public User getByUserNameAndPassword(User user);
}
```

2. 创建 UserService 接口的实现类，并使用 @@Service 注解将其以组件的形式添加到容器中，代码如下。

```java
@Service("userService")
public class UserServiceImpl implements UserService {
    @Autowired
    UserMapper userMapper;
    @Override
    public User getByUserNameAndPassword(User user) {
        User loginUser = userMapper.getByUserNameAndPassword(user);
        return loginUser;
    }
}
```

3. 修改 LoginController 中的 doLogin() 方法 ,代码如下。

```java
@Slf4j
@Controller
public class LoginController {
    @Autowired
    UserService userService;
    @RequestMapping("/user/login")
    public String doLogin(User user, Map<String, Object> map, HttpSession session) {
        //从数据库中查询用户信息
        User loginUser = userService.getByUserNameAndPassword(user);
        if (loginUser != null) {
            session.setAttribute("loginUser", loginUser);
            log.info("登陆成功，用户名：" + loginUser.getUserName());
            //防止重复提交使用重定向
            return "redirect:/main.html";
        } else {
            map.put("msg", "用户名或密码错误");
            log.error("登陆失败");
            return "login";
        }
    }
}
```



## 注解方式

通过上面的学习，我们知道 mapper 映射文件其实就是一个 XML 配置文件，它存在 XML 配置文件的通病，即编写繁琐，容易出错。即使是一个十分简单项目，涉及的 SQL 语句也都十分简单，我们仍然需要花费一定的时间在mapper 映射文件的配置上。

为了解决这个问题，MyBatis 针对实际实际业务中使用最多的“增伤改查”操作，分别提供了以下注解来替换 mapper 映射文件，简化配置：

- @Select
- @Insert
- @Update
- @Delete


通过以上注解，基本可以满足我们对数据库的增删改查操作，示例代码如下。

```java
@Mapper
public interface UserMapper {
    @Select("select * from user where user_name = #{userName,jdbcType=VARCHAR} and password = #{password,jdbcType=VARCHAR}")
    List<User> getByUserNameAndPassword(User user);
    @Delete("delete from user where id = #{id,jdbcType=INTEGER}")
    int deleteByPrimaryKey(Integer id);
    @Insert("insert into user ( user_id, user_name, password, email)" +
            "values ( #{userId,jdbcType=VARCHAR}, #{userName,jdbcType=VARCHAR}, #{password,jdbcType=VARCHAR}, #{email,jdbcType=VARCHAR})")
    int insert(User record);
    @Update(" update user" +
            "    set user_id = #{userId,jdbcType=VARCHAR},\n" +
            "      user_name = #{userName,jdbcType=VARCHAR},\n" +
            "      password = #{password,jdbcType=VARCHAR},\n" +
            "      email = #{email,jdbcType=VARCHAR}\n" +
            "    where id = #{id,jdbcType=INTEGER}")
    int updateByPrimaryKey(User record);
}
```

#### 注意事项

mapper 接口中的任何一个方法，都只能使用一种配置方式，即注解和 mapper 映射文件二选一，但不同方法之间，这两种方式则可以混合使用，例如方法 1 使用注解方式，方法 2 使用 mapper 映射文件方式。

我们可以根据 SQL 的复杂程度，选择不同的方式来提高开发效率。

- 如果没有复杂的连接查询，我们可以使用注解的方式来简化配置；
- 如果涉及的 sql 较为复杂时，则使用 XML （mapper 映射文件）的方式更好一些。