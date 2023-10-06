# CopyOnWriteArrayList的底层原理是怎样的

- ⾸先CopyOnWriteArrayList内部也是⽤过数组来实现的，在向CopyOnWriteArrayList添加元素 时，会复制⼀个新的数组，写操作在新数组上进⾏，读操作在原数组上进⾏ 

```java
public boolean add(E e) {
    final ReentrantLock lock = this.lock;
    //加个锁
    lock.lock();
    try {
        Object[] elements = getArray();
        int len = elements.length;
        //复制
        Object[] newElements = Arrays.copyOf(elements, len + 1);
        newElements[len] = e;
        //set进去
        setArray(newElements);
        return true;
    } finally {
        lock.unlock();
    }
}
//完全就是一个正常的ArrayList的get方法
public E get(int index) {
    return get(getArray(), index);
}
```

- 写操作会`加锁`，防⽌出现并发写⼊丢失数据的问题 
  - 引发的问题,多线程写的过程中去读,可能读到的数据`不是实时最新的数据`
  - 还没有将改的数据提交,读的是旧数据
- 写操作结束之后会把原数组指向新数组

**其他的什么移除也都是这样的逻辑,在`原数据中找到目标数据`,创建一个新的,把`除了目标数据的其他数据都复制到新的里面`,最后替换旧的数据,当然执行步骤的代码块都加上锁**

> **CopyOnWriteArrayList的理解**

- CopyOnWriteArrayList只是再`写时加了锁`,也不是什么高端大气的操作
- CopyOnWriteArrayList`允许在写操作时来读取数据`，⼤⼤提⾼了读的性能，因此适合读多写少的应⽤场景
  - 不过`这类慎用` ，因为谁也没法保证CopyOnWriteArrayList 到底要放置多少数据，每次写都要重新复制数组，这个代价实在太高昂了。
  - 在高性能的互联网应用中，这种操作分分钟`引起故障`。
- CopyOnWriteArrayList会⽐较占内存，同时可能读到的数据`不是实时最新的数据`，所以不适合实时性要求很⾼的场景 
  - 本来如果一个数组贼大(几十上百亿数据),整了个1G,你还要给他复制一下,变成2个
  - 你自己体会!!!

