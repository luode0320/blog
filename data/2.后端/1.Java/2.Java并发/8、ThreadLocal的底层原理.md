# ThreadLocal的底层原理

> ThreadLocal简介

- ThreadLocal是一个`线程级别的局部变量`,内部使用`Map结构保存数据`

- 它的作用更多的是包装数据到线程中,**相当于**线程任何位置都可以用this可以获取这个数据

- 在线程执行方法的时候,不用`每次都显示的制定一个参数位置`用来传递对象,而是用线程中的ThreadLocal来获取对象

  ```java
  private static final ThreadLocal threadLocal = new ThreadLocal();
  main(){
      threadLocal.set(object);
  	//不用ThreadLocal
      test(object);
  	//使用ThreadLocal
      test1();
  }
  
  test(object){
      //object...
  }
  test1() {
     object = threadLocal.get();
     //object...
  }
  ```

  

> ThreadLocal实现

**先看看结构 -> 这不是什么类结构,是用来理解存储过程的**

![image-20220301174623213](../../../picture\image-20220301174623213.png)

- 第一步: `new一个ThreadLocal`
  - 每一个ThreadLocal都是不同的内存地址,可以随意在任何的线程存数据

```java
private static final ThreadLocal threadLocal = new ThreadLocal();
```

- 第二部: `set(value) `-> 在哪个线程set,那个线程保存的值就是value

```java
public void set(T value) {
    //拿到此时所在的线程
    Thread t = Thread.currentThread();
    //拿到此时线程对应的ThreadLocalMap
    ThreadLocalMap map = getMap(t);
    //用当前的ThreadLocal的内存地址作为key,将value保存好
    map.set(this, value);
}
```

- 第三步: `get() `-> 在哪个线程get,就获取那个线程保存的值

```java
public T get() {
    //拿到此时所在的线程
    Thread t = Thread.currentThread();
    //拿到此时线程对应的ThreadLocalMap中的对应的位置
    ThreadLocalMap map = getMap(t);
	//用当前ThreadLocal的内存地址作为key,拿到value -> Entry就是包装了value的一个类,就是value
    ThreadLocalMap.Entry e = map.getEntry(this);
    @SuppressWarnings("unchecked")
    //Entry就是包装了value的一个类,就是value
    T result = (T)e.value;
    return result;
}
```

- 所以看起来,每个线程使用的ThreadLocal实例都是不一样的,都是相互独立的
- 但是如果set的时候传递的对象是引用型的,依旧`无法解决并发问题`,因为最终修改的对象内存地址还是没有变化的

注意: `如果在线程池中使⽤ThreadLocal会造成内存泄漏`

- 因为当ThreadLocal对象使⽤完之后，应该要把 设置的key，value，也就是Entry对象进⾏回收，但线程池中的线程不会回收,线程不被回收，ThreadLocal不回收,Entry对象也就不会被回收，从⽽出现内存泄漏
  - 内存泄漏: 本该被垃圾回收的却因为引用不断,不被回收,占用内存
- 解决办法是，在使⽤了ThreadLocal对象之后，⼿动调⽤ThreadLocal的remove⽅法，⼿动清楚Entry对象 

> 经典的使用场景

- 经典的使用场景是为每个线程分配一个 [JDBC](https://so.csdn.net/so/search?q=JDBC&spm=1001.2101.3001.7020) 连接 Connection。
  - 当然每个连接都是新new的一个连接,并不是同一个连接 
- 这样就可以保证每个线程的都在各自的 Connection 上进行数据库的操作，不会出现 A 线程关了 B线程正在使用的 Connection；
- 每个HTTP请求都对应一个用户对象,存在ThreadLocal中