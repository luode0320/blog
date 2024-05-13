# Java中有哪些类加载器？ 类加载器工作原理？ 

**JDK⾃带有三个类加载器：`bootstrap ClassLoader`、`ExtClassLoader`、`AppClassLoader`。** 

> `BootStrapClassLoader(引导类加载器)`:
>
> - 根类加载器,依赖于底层操作系统,由C编写而成
> - 默认负责加载`jre\lib`⽂件夹下的jar包和class⽂件。 
> - 负责加载虚拟机的核心类库
>   - 如java.lang.*。
>   - `Object类就是由根类加载器加载的`。
>   - 都是在lib/rt.jar中

> `ExtClassLoader(标准扩展类加载器)`:
>
> - 它的父加载器为根类加载器,是AppClassLoader的⽗类加载器,由java编写而成
> - 负责加载`jre\lib\ext`⽂件夹下的jar包和class类。 
> - 如果把我们的jar文件放在该目录下，也会自动由扩展类加载器加载。
>   - `ext目录`：extend 翻译过来就是扩展， 也就是存放扩展的资料，就不属于Java自带的，也就是那些程序需要用到的jar包

> `AppClassLoader(应用程序类路径类加载器丶系统类加载器)`:
>
> - 它的父加载器为扩展类加载器。由java编写而成
> - 它从环境变量`classpath`或者系统属性`java.class.path`所指定的目录中加载类，是用户自定义的类加载器的`默认父加载器`。
>
> 

## 类加载器工作原理

> - Java类加载器是用来在运行时加载类`(*.class文件)`。
>   - 也就是jvm解释器工作的时候,将`.class文件解释为二进制机器码文件`

**工作的流程**

> **`双亲委派机制`: 如果一个类加载器收到类加载的请求，它首先不会自己去尝试加载这个类，而是把这个请求委派给父类(双亲)加载器完成。**

1. 首先判断该类之前是否已加载,逐级向父类判断之前是否加载

2. 若之前都没加载,则传自顶向下调用双亲加载器加载

3. 若父类加载器`都没能成功加载它`,则`自己用findClass()去加载`.所以是个向上递归的过程

>- 如果所有加载器都找不到，就会丢出`NoClassDefFoundError`。
> - `ClassNotfoundException`是在`编译时JVM加载不到.java文件`导致的；
>   - **.java文件编译为.class文件**时找不到java文件
> - 而`NoClassDefError`是在运行时JVM`加载不到.class文件`导致的；
>   - **.class文件解释为二进制机器码文件**时找不到.class文件
>- `类加载器是在运行阶段`,过了编译期来到了解释阶段,类加载器工作时,就不会出现`ClassNotfoundException`了

![img](../../../picture\aHR0cHM6Ly91cGxvYWQtaW1hZ2VzLmppYW5zaHUuaW8vdXBsb2FkX2ltYWdlcy83NjM0MjQ1LTdiNzg4MmUxZjRlYTVkN2QucG5n)

**为什么要使用这种机制?**

- 是因为父亲已经加载了该类的时候，就没有必要子ClassLoader再加载一次。
  - 防止重复加载同一个.class。通过委托去向上面问一问，加载过了，就不用再加载一遍。保证数据安全。

- 如果不使用这种委托模式，那就可以随时使用`自定义的String`来`替代java的String`,这是不行的