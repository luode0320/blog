## HashMap和HashTable有什么区别？其底层实现是什么？ 

# 区别 ： 

1. HashMap和HashTable没有太大的差别,基本就是HashMap⽅法没有synchronized修饰，线程⾮安全，HashTable线程安全； 

```java
//HashMap:
public V get(Object key) {

}
//HashTable
public synchronized V get(Object key) {

}
```



2. HashMap允许key和value为null，⽽HashTable不允许, null是不可以再多线程中通信了,无法使用contains判断一个key是否存在

```java
//HashMap的hash算法对null有特殊处理 -> 赋值为0
static final int hash(Object key) {
    int h;
    return (key == null) ? 0 : (h = key.hashCode()) ^ (h >>> 16);
}
//HashTable的hash算法沿用Object -> 不允许null（空指针异常）
 public native int hashCode();
```

3. HashTable算是一种被淘汰的存储结构，几乎被HashMap替换，如果不是因为有兼容代码必须使用HashTable，理应不再使用，就算因为线程安全也有ConcurrentHashMap而不是继续使用HashTable

## 底层实现：数组+链表实现，初始链表大小为8，链表超过8转变为红黑树 

1. put一个数据时,计算key的hash值，⼆次hash然后对数组⻓度取模，对应到数组下标， 

2. 如果没有产⽣hash冲突(下标位置没有元素)，则直接创建Node存⼊数组， 

3. 如果产⽣hash冲突（链表有数据），先进⾏equal()⽐较，相同则取代该元素，不同，则是追加到链表末尾(jdk1.8)

   - 链表⾼度达到8（储存值数量到达8），则转变为红⿊树，⻓度低于6则将红⿊树转回链表
   - 也就是超过8就不存在链表了,`只剩下数组+红黑树`

   - 转变为红⿊树也是可能因为防止有些人搞事情，跑来攻击，整成很长的链表，搞成红黑树去查询就没问题了

4. key为null，存在下标0的位置（null的hash值特殊处理）

## 红黑树

- 我对树这块还不太理解，我大概知道红黑树因为排序过，通过左旋右旋查找快
- 当数据很多很多的时候用树结构去增删改查会贼快
- 数据很多时，树结构是一种非常优秀的结构

# HashMap的初始容量

- 初始数组大小16 -> `DEFAULT_INITIAL_CAPACITY = 1 << 4;`
- 初始链表大小8 -> `TREEIFY_THRESHOLD = 8;`
- 初始加载因子0.75  -> `DEFAULT_LOAD_FACTOR = 0.75f;`
- 初始树型容量64  -> `MIN_TREEIFY_CAPACITY = 64;`

## 如果HashMap的大小超过了负载因子(load factor)定义的容量，怎么办？

- 默认的负载因子大小为0.75
- 也就是说，当一个map填满了75%的bucket时候，和其它集合类(如ArrayList等)一样，将会创建原来HashMap大小的两倍的bucket数组，来重新调整map的大小，并将原来的对象放入新的bucket数组中。
- 这些东西我觉得不需要去特意去记，负载因子在0.7左右最好，扩容很多结构对象都是扩容2倍大差不差
- 因为2的倍数用二进制表示是`只有一个1其他都是0`的一串数字,之后运算方便
  - ​	- `0001,0010,0100,1000, 1 0000` 

## HashMap扩容原理

**`(当键值对个数 > 加载因子 * 数组长度)`时,HashMap会触发扩容**

> 1. 如果HashMap的键值对数据大于阀值,容量翻倍(`数据个数大于阀值扩容`)
>
> 2. 如果HashMap中链表长度大于等于8时(`链表长度大于8时扩容`)
>    1. 此时不会立即转换为树,而是先判断数组容量是否大于64
>    2. 如果数组容量是16或32,`进行一次扩容`
>
>    3. 使用扩容重新调整数据的存放位置来缩短链表长度

1. 旧map的`数组`大小左移一位相当于容量提升2倍

```java
if ((newCap = oldCap << 1) < MAXIMUM_CAPACITY && oldCap >= DEFAULT_INITIAL_CAPACITY){
      newThr = oldThr << 1; // 2倍
}        
```

2. 旧散列的数据迁移到新的散列中,做了一个位运算`e.hash & oldCap`判断链表是否也要改变位置
   - `新的索引位置 = 旧的位置 + 旧的数组长度`

```java
// 当node的hash值 & 旧容量位 == 0时,这个数据是不需要换桶位置的
if ((e.hash & oldCap) == 0) {
    if (loTail == null)
        loHead = e;
    else
        loTail.next = e;
    loTail = e;
}
// 当hash值 & 旧容量位 != 0时,这个数据是需要换位置的,而且换的位置为：旧桶的位置 + oldCap
else {
    if (hiTail == null)
        hiHead = e;
    else
        hiTail.next = e;
    hiTail = e;
}
```

- **为什么用这个位运算判断?**

  - 什么情况下扩容了,hash计算后跟原来的hash值是一样的?
  - HashMap的hash计算方式`(n - 1) & hash`,hash值与数组的最后一个索引做与运算
  - 如果扩容前后要相等,那么:

  ```java
  int oldCap = (扩容前数组长度 - 1) & hash;
  int newCap = ((扩容前数组长度 * 2) - 1 ) & hash;
  //那么
  if(oldCap == newCap)//一定是为true的
  ```

  - 那么就很简单了我们把他的源码:

  ```java
  if ((e.hash & oldCap) == 0) {
      
  }
  //改成
  if (((oldCap * 2) - 1 ) & hash == (oldCap - 1) & hash){
      
  }
  ```

  - 结果肯定是可以用的,而且是一样的效果
  - 所以`(e.hash & oldCap)`一定是我们猜测的公式再次简化的结果
  - 只是怎么简化来的我们不知道,我们知道逻辑就是这么个逻辑
  - **我们试着简化一下**

  ```java
  1. ((oldCap * 2) - 1 ) & hash = (oldCap - 1) & hash
  
  2. ((oldCap + oldCap) - 1 ) & hash = (oldCap - 1) & hash
  
  3. (oldCap + (oldCap - 1 )) & hash = (oldCap - 1) & hash
  
  //百度搜索的来: 位运算交换律能安全使用。
  
  4. (oldCap & hash) + ((oldCap - 1) & hash ) = (oldCap - 1) & hash
  
  5. oldCap & hash = 0
      
  ```

## HashMap在高并发下,会出现环形链表?

> 1. jdk1.7 map采用链表头节点插入,多线程扩容会出现环形链表
>
> 2. jdk1.8 map采用链表尾节点插入(永远向后,不会产生回环),多线程扩容不会出现环形链表了(修复bug)

## HashMap的线程不安全主要体现哪里?

> 1.在JDK1.7中，当并发执行扩容操作时会造成环形链和数据丢失的情况。
>
> 2.在JDK1.8中，在并发执行put操作时会发生数据覆盖的情况。
>
> - `HashMap的put()方法中`，有`modCount++`和`++size`的操作，即调用put()时，修改次数加1，“i++”操作，从表面上看 i++ 只是一行代码，但实际上它并不是一个原子操作，它的执行步骤主要分为三步，而且在每步操作之间都有可能被打断。
>
>   ```java
>   ++modCount;
>   if (++size > threshold)
>       resize();
>   ```
>
>   - 第一个步骤是: 读取；
>   - 第二个步骤是: 增加；
>   - 第三个步骤是: 保存。
>
> - 所以，从源码的角度，或者说从理论上来讲，这`完全足以证明 HashMap 是线程非安全的了`。因为如果有多个线程同时调用 put() 方法的话，它很有可能会把 modCount 的值计算错。

