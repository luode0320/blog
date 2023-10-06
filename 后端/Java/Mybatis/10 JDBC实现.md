# JDBC实现

> JDBC是由java编程语言编写的类及接口组成，同时它为程序开发人员提供了一组用于实现对数据库访问JDBC API,并支持SQL语言。

- 利用JDBC可以将JAVA代码连接到oracle、DB2、SQLServer、MYSQL等数据库，从而实现对数据库中的数据操作的目的。

> JDBC的主要功能如下：

（1）建立与数据库或者其他数据源的链接

（2）向数据库发送SQL命令

（3）处理数据库的返回结果

> JDBC中常用类和接口

- 连接到数据库（Connection）
- 建立操作指令（Statement）
- 执行查询指令（executeQuery）
- 获得查询结果（ResultSet）

> 驱动程序管理类（DriverManager）

- `DriverManager类是JDBC的管理类`，作用于用户和驱动程序之间。
- 它跟踪在可用的驱动程序，并在数据库和相应驱动程序之间建立连接。
- 对于简单的应用程序，一般程序员需要在此类中直接使用唯一的方法时DriverManager.getConnection()。
- 该方法将建立与数据库的链接。
- JDBC允许用户调用DriverManager的方法getDriver()、getDrivers()和registerDriver()及Driver的方法connect().

> 声明类（Statement）

- `Statement`对象用于将SQL语句发送到数据库中。
- 实际上有三种Statement对象，它们都作为在给定链接上执行SQL语句的包容器：
  - Statement
  - PreparedStatement（它从Statement继承而来）
  - CallableStatement（它从PreparedStatement继承而来）
  - 它们都专用于发送特定类型的SQL语句：
    - Statement对象用于**执行不带参数的简单的SQL语句**；Statement接口提供了执行语句和获取结果的基本方法。
    - PerparedStatement对象用于**执行带或不带IN参数的预编译SQL语句**；PeraredStatement接口添加处理IN参数的方法；
    - CallableStatement对象用于执行对数据库**已存储过程的调用**；CallableStatement添加处理OUT参数的方法。

#### Statement提供了许多方法，最常用的方法如下：

- `execute()`方法：运行语句，返回是否有结果集。

- `executeQuery()`方法：运行查询语句，返回ReaultSet对象。

- `executeUpdata()`方法：运行更新操作，返回更新的行数。

- `addBatch()`方法：增加批处理语句。

- `executeBatch()`方法：执行批处理语句。

- `clearBatch()`方法：清除批处理语句。

>  数据库连接类 （Connection）

- `Connection`对象代表与数据库的链接。

- 连接过程包括**所执行的SQL语句**和在该**连接上所返回的结果**。

- 一个应用程序可与单个数据库有一个或多个连接，或者可与很多数据库有连接。

- 打开连接与数据库建立连接的标准方法是调用`DriverManager.getConnection()`方法。

  ```java
  String url="jdbc:mysql://127.0.0.1:3306/imooc";
  
  String user="root";
  
  String password="tiger";
  
  DriverManager.getConnection(url,user,password);
  ```

  

>  结果集合类 （ResultSet）

- ResultSet包含**符合SQL语句中条件的所有行记录**，并且它通过一套`get()`方法提供了对这些行中数据的访问。
- `ResultSet.next()`方法用于移动到ResultSet中的下一行，使下一行成为当前行。

## JDBC编程步骤

（1）**加载驱动程序**：Class.forName(driverClass)

- 加载mysql驱动：Class.forName("com.mysql.jdbc.Driver");

- 加载oracle驱动：Class.forName("oracle.jdbc.driver.OracleDriver");

（2）**获得数据库连接**

- DriverManager.getConnection("jdbc:mysql://127.0.0.1:3306/imooc",user,password);

- DriverManager.gerConnection(URL,user,password);

（3）**创建Statement对象**：

- conn.createStatement();

（4）**向数据库发送SQL命令**

（5）**处理数据库的返回结果(ResultSet类)**

```java
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;


public class javaTest {

    public static void main(String[] args) throws ClassNotFoundException, SQLException  {
        String URL="jdbc:mysql://127.0.0.1:3306/imooc?useUnicode=true&characterEncoding=utf-8";
        String USER="root";
        String PASSWORD="tiger";
        //1.加载驱动程序
        Class.forName("com.mysql.jdbc.Driver");
        //2.获得数据库链接
        Connection conn=DriverManager.getConnection(URL, USER, PASSWORD);
        //3.通过数据库的连接操作数据库，实现增删改查（使用Statement类）
        Statement st=conn.createStatement();
        ResultSet rs=st.executeQuery("select * from user");
        //4.处理数据库的返回结果(使用ResultSet类)
        while(rs.next()){
            System.out.println(rs.getString("user_name")+" "
                               +rs.getString("user_password"));
        }

        //关闭资源
        rs.close();
        st.close();
        conn.close();
    }
}
```

```java
        //定义 sql 语句 ?表示占位符
        String sql = "select * from user where username = ?";
        //获取预处理 statement
        preparedStatement = connection.prepareStatement(sql);
        //设置参数，第一个参数为 sql 语句中参数的序号（从 1 开始），第二个参数为设置的参数值
        preparedStatement.setString(1, "王五");
        //向数据库发出 sql 执行查询，查询出结果集
        resultSet = preparedStatement.executeQuery();
```

