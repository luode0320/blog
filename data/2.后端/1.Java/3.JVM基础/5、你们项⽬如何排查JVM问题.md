# 你们项目如何排查JVM问题

## 一、cpu占用过高

cpu占用过高要分情况讨论，是不是业务上在搞活动，突然有大批的流量进来，而且活动结束后cpu占用率就下降了，如果是这种情况其实可以不用太关心，因为请求越多，需要处理的线程数越多，这是正常的现象。话说回来，如果你的服务器配置本身就差，cpu也只有一个核心，这种情况，稍微多一点流量就真的能够把你的cpu资源耗尽，这时应该考虑先把配置提升吧。

第二种情况，cpu占用率**「长期过高」**，这种情况下可能是你的程序有那种循环次数超级多的代码，甚至是出现死循环了。排查步骤如下：

[用top命令查看cpu占用情况](http://c.biancheng.net/view/1065.html)

![图片](../../../picture\640)

**用top命令查看cpu占用情况**

**这样就可以定位出cpu过高的进程。在linux下，top命令获得的进程号和jps工具获得的vmid是相同的：**

![图片](../../../picture\640)

**定位出cpu过高的进程**

用top -Hp命令查看线程的情况 -> 注意此时的pid变成了对应的线程号

可以看到是线程id为7287这个线程一直在占用cpu

**把线程号转换为16进制**

```
[root@localhost ~]# printf "%x" 7287
1c77
```

记下这个16进制的数字，下面我们要用

### （4）用jstack工具查看线程栈情况

```
[root@localhost ~]# jstack 7268 | grep 1c77 -A 10
"http-nio-8080-exec-2" #16 daemon prio=5 os_prio=0 tid=0x00007fb66ce81000 nid=0x1c77 runnable [0x00007fb639ab9000]
   java.lang.Thread.State: RUNNABLE
 at com.spareyaya.jvm.service.EndlessLoopService.service(EndlessLoopService.java:19)
 at com.spareyaya.jvm.controller.JVMController.endlessLoop(JVMController.java:30)
 at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
 at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
 at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
 at java.lang.reflect.Method.invoke(Method.java:498)
 at org.springframework.web.method.support.InvocableHandlerMethod.doInvoke(InvocableHandlerMethod.java:190)
 at org.springframework.web.method.support.InvocableHandlerMethod.invokeForRequest(InvocableHandlerMethod.java:138)
 at org.springframework.web.servlet.mvc.method.annotation.ServletInvocableHandlerMethod.invokeAndHandle(ServletInvocableHandlerMethod.java:105)
```

通过jstack工具输出现在的线程栈，再通过grep命令结合上一步拿到的线程16进制的id定位到这个线程的运行情况，其中jstack后面的7268是第（1）步定位到的进程号，grep后面的是（2）、（3）步定位到的线程号。

从输出结果可以看到这个线程处于运行状态，在执行`com.spareyaya.jvm.service.EndlessLoopService.service`这个方法，代码行号是19行，这样就可以去到代码的19行，找到其所在的代码块，看看是不是处于循环中，这样就定位到了问题。

## 二、死锁

死锁并没有第一种场景那么明显，web应用肯定是多线程的程序，它服务于多个请求，程序发生死锁后，死锁的线程处于等待状态（WAITING或TIMED_WAITING），等待状态的线程不占用cpu，消耗的内存也很有限，而表现上可能是请求没法进行，最后超时了。在死锁情况不多的时候，这种情况不容易被发现。

可以使用jstack工具来查看

### （1）jps查看java进程

```
[root@localhost ~]# jps -l
8737 sun.tools.jps.Jps
8682 jvm-0.0.1-SNAPSHOT.jar
```

### （2）jstack查看死锁问题

由于web应用往往会有很多工作线程，特别是在高并发的情况下线程数更多，于是这个命令的输出内容会十分多。jstack最大的好处就是会把产生死锁的信息（包含是什么线程产生的）输出到最后，所以我们只需要看最后的内容就行了

```
Java stack information for the threads listed above:
===================================================
"Thread-4":
 at com.spareyaya.jvm.service.DeadLockService.service2(DeadLockService.java:35)
 - waiting to lock <0x00000000f5035ae0> (a java.lang.Object)
 - locked <0x00000000f5035af0> (a java.lang.Object)
 at com.spareyaya.jvm.controller.JVMController.lambda$deadLock$1(JVMController.java:41)
 at com.spareyaya.jvm.controller.JVMController$$Lambda$457/1776922136.run(Unknown Source)
 at java.lang.Thread.run(Thread.java:748)
"Thread-3":
 at com.spareyaya.jvm.service.DeadLockService.service1(DeadLockService.java:27)
 - waiting to lock <0x00000000f5035af0> (a java.lang.Object)
 - locked <0x00000000f5035ae0> (a java.lang.Object)
 at com.spareyaya.jvm.controller.JVMController.lambda$deadLock$0(JVMController.java:37)
 at com.spareyaya.jvm.controller.JVMController$$Lambda$456/474286897.run(Unknown Source)
 at java.lang.Thread.run(Thread.java:748)

Found 1 deadlock.
```

发现了一个死锁，原因也一目了然。

## 三、内存泄漏

我们都知道，java和c++的最大区别是前者会自动收回不再使用的内存，后者需要程序员手动释放。在c++中，如果我们忘记释放内存就会发生内存泄漏。但是，不要以为jvm帮我们回收了内存就不会出现内存泄漏。

程序发生内存泄漏后，进程的可用内存会慢慢变少，最后的结果就是抛出OOM错误。发生OOM错误后可能会想到是内存不够大，于是把-Xmx参数调大，然后重启应用。这么做的结果就是，过了一段时间后，OOM依然会出现。最后无法再调大最大堆内存了，结果就是只能每隔一段时间重启一下应用。

内存泄漏的另一个可能的表现是请求的响应时间变长了。这是因为频繁发生的GC会暂停其它所有线程（Stop The World）造成的。

为了模拟这个场景，使用了以下的程序

```
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class Main {

    public static void main(String[] args) {
        Main main = new Main();
        while (true) {
            try {
                Thread.sleep(1);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            main.run();
        }
    }

    private void run() {
        ExecutorService executorService = Executors.newCachedThreadPool();
        for (int i = 0; i < 10; i++) {
            executorService.execute(() -> {
                // do something...
            });
        }
    }
}
```

运行参数是`-Xms20m -Xmx20m -XX:+PrintGC`，把可用内存调小一点，并且在发生gc时输出信息，运行结果如下

```
...
[GC (Allocation Failure)  12776K->10840K(18432K), 0.0309510 secs]
[GC (Allocation Failure)  13400K->11520K(18432K), 0.0333385 secs]
[GC (Allocation Failure)  14080K->12168K(18432K), 0.0332409 secs]
[GC (Allocation Failure)  14728K->12832K(18432K), 0.0370435 secs]
[Full GC (Ergonomics)  12832K->12363K(18432K), 0.1942141 secs]
[Full GC (Ergonomics)  14923K->12951K(18432K), 0.1607221 secs]
[Full GC (Ergonomics)  15511K->13542K(18432K), 0.1956311 secs]
...
[Full GC (Ergonomics)  16382K->16381K(18432K), 0.1734902 secs]
[Full GC (Ergonomics)  16383K->16383K(18432K), 0.1922607 secs]
[Full GC (Ergonomics)  16383K->16383K(18432K), 0.1824278 secs]
[Full GC (Allocation Failure)  16383K->16383K(18432K), 0.1710382 secs]
[Full GC (Ergonomics)  16383K->16382K(18432K), 0.1829138 secs]
[Full GC (Ergonomics) Exception in thread "main"  16383K->16382K(18432K), 0.1406222 secs]
[Full GC (Allocation Failure)  16382K->16382K(18432K), 0.1392928 secs]
[Full GC (Ergonomics)  16383K->16382K(18432K), 0.1546243 secs]
[Full GC (Ergonomics)  16383K->16382K(18432K), 0.1755271 secs]
[Full GC (Ergonomics)  16383K->16382K(18432K), 0.1699080 secs]
[Full GC (Allocation Failure)  16382K->16382K(18432K), 0.1697982 secs]
[Full GC (Ergonomics)  16383K->16382K(18432K), 0.1851136 secs]
[Full GC (Allocation Failure)  16382K->16382K(18432K), 0.1655088 secs]
java.lang.OutOfMemoryError: Java heap space
```

可以看到虽然一直在gc，占用的内存却越来越多，说明程序有的对象无法被回收。但是上面的程序对象都是定义在方法内的，属于局部变量，局部变量在方法运行结果后，所引用的对象在gc时应该被回收啊，但是这里明显没有。

为了找出到底是哪些对象没能被回收，我们加上运行参数-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=heap.bin，意思是发生OOM时把堆内存信息dump出来。运行程序直至异常，于是得到heap.dump文件，然后我们借助eclipse的MAT插件来分析，如果没有安装需要先安装。

然后File->Open Heap Dump... ，然后选择刚才dump出来的文件，选择Leak Suspects

![图片](https://mmbiz.qpic.cn/mmbiz_png/TLH3CicPVibrd0XbLH70cBH9z3n9sicxltE1SdShZHIUtKKZBEAGW3p8eXibD8w4tNb1AJuJmPic9WwU1V6NZ9rVqIw/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)借助eclipse的MAT插件

MAT会列出所有可能发生内存泄漏的对象

![图片](../../../picture\640)

可以看到居然有21260个Thread对象，3386个ThreadPoolExecutor对象，如果你去看一下`java.util.concurrent.ThreadPoolExecutor`的源码，可以发现线程池为了复用线程，会不断地等待新的任务，线程也不会回收，需要调用其shutdown方法才能让线程池执行完任务后停止。

其实线程池定义成局部变量，好的做法是设置成单例。

**「上面只是其中一种处理方法」**

在线上的应用，内存往往会设置得很大，这样发生OOM再把内存快照dump出来的文件就会很大，可能大到在本地的电脑中已经无法分析了（因为内存不足够打开这个dump文件）。这里介绍另一种处理办法：

### （1）用jps定位到进程号

```
C:\Users\spareyaya\IdeaProjects\maven-project\target\classes\org\example\net>jps -l
24836 org.example.net.Main
62520 org.jetbrains.jps.cmdline.Launcher
129980 sun.tools.jps.Jps
136028 org.jetbrains.jps.cmdline.Launcher
```

因为已经知道了是哪个应用发生了OOM，这样可以直接用jps找到进程号135988

### （2）用jstat分析gc活动情况

jstat是一个统计java进程内存使用情况和gc活动的工具，参数可以有很多，可以通过jstat -help查看所有参数以及含义

```
C:\Users\spareyaya\IdeaProjects\maven-project\target\classes\org\example\net>jstat -gcutil -t -h8 24836 1000
Timestamp         S0     S1     E      O      M     CCS    YGC     YGCT    FGC    FGCT     GCT
           29.1  32.81   0.00  23.48  85.92  92.84  84.13     14    0.339     0    0.000    0.339
           30.1  32.81   0.00  78.12  85.92  92.84  84.13     14    0.339     0    0.000    0.339
           31.1   0.00   0.00  22.70  91.74  92.72  83.71     15    0.389     1    0.233    0.622
```

上面是命令意思是输出gc的情况，输出时间，每8行输出一个行头信息，统计的进程号是24836，每1000毫秒输出一次信息。

输出信息是Timestamp是距离jvm启动的时间，S0、S1、E是新生代的两个Survivor和Eden，O是老年代区，M是Metaspace，CCS使用压缩比例，YGC和YGCT分别是新生代gc的次数和时间，FGC和FGCT分别是老年代gc的次数和时间，GCT是gc的总时间。虽然发生了gc，但是老年代内存占用率根本没下降，说明有的对象没法被回收（当然也不排除这些对象真的是有用）。

### （3）用jmap工具dump出内存快照

jmap可以把指定java进程的内存快照dump出来，效果和第一种处理办法一样，不同的是它不用等OOM就可以做到，而且dump出来的快照也会小很多。

```
jmap -dump:live,format=b,file=heap.bin 24836
```

这时会得到heap.bin的内存快照文件，然后就可以用eclipse来分析了。

## 四、总结

以上三种严格地说还算不上jvm的调优，只是用了jvm工具把代码中存在的问题找了出来。我们进行jvm的主要目的是尽量减少停顿时间，提高系统的吞吐量。但是如果我们没有对系统进行分析就盲目去设置其中的参数，可能会得到更坏的结果，jvm发展到今天，各种默认的参数可能是实验室的人经过多次的测试来做平衡的，适用大多数的应用场景。如果你认为你的jvm确实有调优的必要，也务必要取样分析，最后还得慢慢多次调节，才有可能得到更优的效果。



> 对于还在正常运⾏的系统： 

- 通过各个命令的结果，或者jvisualvm等⼯具来进⾏分析 
  - 可以使⽤jmap来查看JVM中各个区域的使⽤情况 

  - 可以通过jstack来查看线程的运⾏情况，⽐如哪些线程阻塞、是否出现了死锁 

  - 可以通过jstat命令来查看垃圾回收的情况，特别是fullgc，如果发现fullgc⽐较频繁，那么就得进⾏调优了 

- ⾸先，初步猜测频繁`fullgc(老年代整体大面积垃圾回收)`的原因

- 如果频繁发⽣fullgc但是⼜⼀直`没有出现内存溢出`,系统运行的好好的

- 那么表示gc实际上是`一下可以回收很多对象了`，所以这些对象最好能在`younggc(新生代垃圾回收)`过程中就直接回收掉，避免这些对象进⼊到⽼年代,甚至搞到永久区里去

- 对于这种情况，就要看看什么原因了
  - 考虑这些`存活时间不⻓的对象是不是⽐较⼤`，导致年轻代放不下，直接进⼊到了⽼年代，尝试加⼤年轻代的⼤小
  - 检查一下是哪个线程使用内存太多了
  - 检查一下是哪个线程占⽤CPU太多了，定位到具体的⽅法，优化这个⽅法的执⾏，看是否能避免某些对象的创建，从⽽节省内存

> 对于已经发⽣了`OOM(内存溢出)`的系统：

1. ⼀般⽣产系统中都会设置当系统发⽣了OOM时，⽣成当时的dump⽂件
   - `- XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/usr/local/base`

2. 我们可以利⽤jsisualvm(可视化)等⼯具来分析dump⽂件 

3. 根据dump⽂件找到异常的实例对象，和异常的线程（占⽤CPU⾼），定位到具体的代码 

4. 然后再进⾏详细的分析和调试 

## JVM图形化查看详细

> - 图形界面可以去jdk的bin下面找到`jvisualvm.exe` -> 这是一个自带的图形化界面
> - 有一些好用的插件可以试着安装`Visual GC  ` `btrace  `

**查看线程情况**

![image-20220222201127364](../../../picture\image-20220222201127364.png)

**查看各个线程使用的内存和cpu的情况**

![image-20220222224418331](../../../picture\image-20220222224418331.png)

**查看垃圾回收情况**

![image-20220222223844536](../../../picture\image-20220222223844536.png)

**查看dump跟踪信息**

![image-20220222223924362](../../../picture\image-20220222223924362.png)

## JVM命令查看详细

> `jps` -> Java ps:查看正在运行的Java进程

- jps: 可以列出正在运行的`Java进程`，并显示虚拟机执行主类名称以及进程id

  ```java
  C:\>jps
  5932 测试Collection
  ```

- 常见的选项: `jps -l` `jps -v`

  - `jps -l` -> 输出主类全类名，如果进程执行的是Jar包，输出jar包名字

    ```shell
    C:\>jps -l
    5932 rod.集合.测试Collection
    ```

  - `jps -v` -> 程序启动时指定的jvm参数

    ```java
    5932 测试Collection 
        -agentlib:jdwp=transport=dt_socket,
    	address=127.0.0.1:54731,
    	suspend=y,
    	server=n 
        -javaagent:C:\Users\欧皇小德子\AppData\Local\JetBrains\IntelliJIdea2021.2\captureAgent\debugger-agent.jar 
        -Dfile.encoding=UTF-8
    ```

> `jstack` -> Java stack:打印线程快照

- 查看某个Java进程中`所有线程的状态`。

- 一般用来`定位线程出现长时间停顿的原因`，如**发生死循环，死锁，请求外部资源长时间等待**等！

- 常见的选项: `jstack 进程id` `jps -v`

  - `jstack 进程id`  -> 进程中所有线程的状态,只要程序还在走,就打印轨迹

    ```shell
    [C:\~]$ jstack 37476
    2022-02-22 19:17:04
    Full thread dump Java HotSpot(TM) 64-Bit Server VM (25.231-b11 mixed mode):
    
    "DestroyJavaVM" #24 prio=5 os_prio=0 tid=0x0000000002f94000 nid=0x8a40 waiting on condition [0x0000000000000000]
       java.lang.Thread.State: RUNNABLE
    
    "myThreadB" #23 prio=5 os_prio=0 tid=0x0000000025314000 nid=0x5018 waiting for monitor entry [0x00000000266bf000]
       java.lang.Thread.State: BLOCKED (on object monitor)
    	at rod.TestMain.lambda$main$1(TestMain.java:35)
    	- waiting to lock <0x0000000743a6a820> (a java.lang.Object)
    	- locked <0x0000000743a6a830> (a java.lang.Object)
    	at rod.TestMain$$Lambda$2/1349414238.run(Unknown Source)
    	at java.lang.Thread.run(Thread.java:748)
    
    "myThreadA" #22 prio=5 os_prio=0 tid=0x0000000025313000 nid=0x2794 waiting for monitor entry [0x00000000265bf000]
       java.lang.Thread.State: BLOCKED (on object monitor)
    	at rod.TestMain.lambda$main$0(TestMain.java:21)
    	- waiting to lock <0x0000000743a6a830> (a java.lang.Object)
    	- locked <0x0000000743a6a820> (a java.lang.Object)
    	at rod.TestMain$$Lambda$1/1873653341.run(Unknown Source)
    	at java.lang.Thread.run(Thread.java:748)
    
    "Service Thread" #21 daemon prio=9 os_prio=0 tid=0x0000000024ff1000 nid=0x8cc4 runnable [0x0000000000000000]
       java.lang.Thread.State: RUNNABLE
       
    ...
    
    "VM Thread" os_prio=2 tid=0x00000000215f7000 nid=0x8710 runnable 
    
    "GC task thread#0 (ParallelGC)" os_prio=0 tid=0x0000000002faa800 nid=0x9378 runnable 
    ...
    发现一个Java级死锁:
    =============================
    "myThreadB":
      等待锁定监视器 0x0000000021601c08 (object 0x0000000743a6a820, a java.lang.Object),
      这是由 "myThreadA"
    "myThreadA":
      等待锁定监视器 0x0000000021604338 (object 0x0000000743a6a830, a java.lang.Object),
      这是由 "myThreadB"
    
    列出的线程的Java堆栈信息:
    ===================================================
    "myThreadB":
    	at rod.TestMain.lambda$main$1(TestMain.java:35)
    	- waiting to lock <0x0000000743a6a820> (a java.lang.Object)
    	- locked <0x0000000743a6a830> (a java.lang.Object)
    	at rod.TestMain$$Lambda$2/1349414238.run(Unknown Source)
    	at java.lang.Thread.run(Thread.java:748)
    "myThreadA":
    	at rod.TestMain.lambda$main$0(TestMain.java:21)
    	- waiting to lock <0x0000000743a6a830> (a java.lang.Object)
    	- locked <0x0000000743a6a820> (a java.lang.Object)
    	at rod.TestMain$$Lambda$1/1873653341.run(Unknown Source)
    	at java.lang.Thread.run(Thread.java:748)
    
    ```

  - 可能看到一些线程的轨迹:

    - `DestroyJavaVM` -> 销毁线程**(RUNNABLE=运行状态)**
    - `myThreadB丶myThreadA` -> 我们直接定义的线程**(BLOCKED=阻塞状态)**
    - `Service Thread` -> 还有很多名称的`daemon`守护线程也是`运行状态`就不列举了
    - `GC` -> 垃圾回收线程**(RUNNABLE=运行状态)**

  - **并且在最后提示出了死锁发生的位置**

> `jmap` -> Java map:导出堆内存映像文件

- jmap主要用来用来导出`堆内存映像文件，看是否发生内存泄露`等。

  - 内存溢出: 内存满了,炸了,你还要创建新对象,直接爆炸 -> `溢出比较好记,就是满了,反过来就是泄露`
  - 内存泄露:  内存没满好好的,但是`有很多垃圾需要可以回收却回收不了`,站着茅坑不拉屎

- 生产环境一般会`配置如下参数`，让虚拟机在OOM异常出现之后自动生成[dump](https://so.csdn.net/so/search?q=dump&spm=1001.2101.3001.7020)文件

  - Dump文件是[进程](https://baike.baidu.com/item/进程/382503)的[内存镜像](https://baike.baidu.com/item/内存镜像/179117)。可以把程序的[执行状态](https://baike.baidu.com/item/执行状态/4281530)通过[调试器](https://baike.baidu.com/item/调试器/3351943)保存到dump文件中。
  - 主要是用来在系统中`出现异常或者崩溃`的时候来生成dump文件
  - 然后用`调试器进行调试`，这样就可以把生产环境中的dump文件拷贝到自己的开发机上
  - 调试就可以找到程序出错的位置。

  ```shell
  //输出错误堆Dump信息 路径/Users/peng
  -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/Users/peng
  ```

- 执行如下命令即可`手动获得dump文件`

  ```shell
  jmap -dump:file=文件名.dump 进程id
  ```

> `jstat` -> java stat: 查看jvm统计信息

- jstat可以显示`本地或者远程虚拟机`进程中的`类装载、 内存、 垃圾收集、 JIT(编译器)编译`等运行数据

- 用jstat查看一下类装载的信息。我个人很少使用这个命令，`命令行看垃圾收集信息真不如看图形界面方便`

  ```shell
  [C:\~]$ jstat -class  37476
  加载类的个数	加载类的字节数	卸载类的个数 卸载类的字节数	花费的时间
  Loaded  		Bytes 		Unloaded  	Bytes    	 Time   
     661  		1285.3        0     	0.0      	 0.17
  ```

  

# 简介

![img](../../../picture\arthas.png)

Arthas 是一款线上监控诊断产品，通过全局视角实时查看应用 load、内存、gc、线程的状态信息，并能在不修改应用代码的情况下，对业务问题进行诊断，包括查看方法调用的出入参、异常，监测方法执行耗时，类加载信息等，大大提升线上问题排查效率。

https://arthas.aliyun.com/doc/

## (https://arthas.aliyun.com/doc/#arthas-阿尔萨斯-能为你做什么)Arthas（阿尔萨斯）能为你做什么？

`Arthas` 是 Alibaba 开源的 Java 诊断工具，深受开发者喜爱。

当你遇到以下类似问题而束手无策时，`Arthas`可以帮助你解决：

1. 这个类从哪个 jar 包加载的？为什么会报各种类相关的 Exception？
2. 我改的代码为什么没有执行到？难道是我没 commit？分支搞错了？
3. 遇到问题无法在线上 debug，难道只能通过加日志再重新发布吗？
4. 线上遇到某个用户的数据处理有问题，但线上同样无法 debug，线下无法重现！
5. 是否有一个全局视角来查看系统的运行状况？
6. 有什么办法可以监控到 JVM 的实时运行状态？
7. 怎么快速定位应用的热点，生成火焰图？
8. 怎样直接从 JVM 内查找某个类的实例？

`Arthas` 支持 JDK 6+，支持 Linux/Mac/Windows，采用命令行交互模式，同时提供丰富的 `Tab` 自动补全功能，进一步方便进行问题的定位和诊断。