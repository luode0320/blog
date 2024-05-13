# ConcurrentHashMap的实现原理

> 在并发编程中使用HashMap可能导致`程序死循环`。而使用线程安全的HashTable效率又非常低下，基于以上两个原因，便有了ConcurrentHashMap的登场机会

**ConcurrentHashMap所使用的锁分段技术。**

1. 首先将数据分成一段一段地存储
2. 然后给每一段数据配一把锁，当一个线程占用锁访问其中一个段数据的时候，其他段的数据也能被其他线程访问。

## jdk1.7

**了解了解就行,现在jdk大多都是1.8,几乎重写了一边**

> 采用`Segment` + `HashEntry`的方式进行实现，结构如下：

![img](../../../picture\5220087-8c5b0cc951e61398.png)

- ConcurrentHashMap是由`Segment数组结构`和`HashEntry数组结构(类似Map)`组成。
- Segment是一种`可重入锁`（ReentrantLock），在ConcurrentHashMap里扮演锁的角色；HashEntry则用于存储键值对数据。

- 一个ConcurrentHashMap里包含一个Segment数组。
- Segment的结构和HashMap类似，是一种`数组和链表`结构。
- Segment数组的每个节点都相当于一个小HashMap,这样就可以对`单个Segment节点加锁`,不会影响到所有数据都被锁上

- 原理跟HashMap差不多,都是用hash算法找位置
  - 第一次hash找Segment数组的某个节点
  - 第二次hash找这个Segment节点下这个小HashMap的数组位置(就类似HashMap的操作了)

## jdk1.8

**ConcurrentHashMap在1.8中的实现，相比于1.7的版本基本上全部都变掉了。**

1. 首先，`取消`了Segment分段锁的数据结构，取而代之的是`数组+链表（红黑树）`的结构(`回到了HashMap结构`)。
2. 而对于锁的粒度，调整为对`每个数组元素加锁(就是对每个链表或红黑树加锁)`。
3. ConcurrentHashMap采用 `CAS` + `Synchronized`来保证并发安全进行实现(`乐观锁+悲观锁`)

![image-20220225195508378](../../../picture\image-20220225195508378.png)

## ConcurrentHashMap的put实现

- 与HashMap稍微不同就是,HashMap会计算hash和equals()比较后直接加上去

- ConcurrentHashMap会有相应锁的控制(`CAS+synchronized`)后再添加数据
  - 执行第一次`put`方法时,采用`CAS机制`
  - 链表or树的其他节点put就是用`synchronized`加锁,利用头节点锁住整个链表或者树结构
  - 后面跟HashMap差不多了
    - 计算hash和equals()比较后直接加上去
  
  **为什么不都用CAS机制,而是有一部分用synchronized呢?**
  
  - 还是因为`CAS`的缺点,不能对多个变量进行原子操作,不能保证代码块的原子性
  - 并且CAS的预测值与实际值比较`并不包括next的属性`,仅仅对(k,v)进行比较
  - 所以对同一节点进行操作时
    - 线程1要修改value属性,线程2修改next属性
    - 线程2执行快,先替换了next属性
    - 而线程1预测(k,v)并没有变化,又将之前的旧next覆盖掉线程2修改后的

> `点赞,靓仔`