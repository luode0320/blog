# 谈谈ConcurrentHashMap的扩容机制 

> 1.7版本  -> 理解即可

1. 1.7版本的ConcurrentHashMap是基于Segment分段实现的 

2. 每个Segment相对于⼀个⼩型的HashMap 

3. 每个Segment内部会进⾏扩容，和HashMap的扩容逻辑类似 

4. 先⽣成新的数组，然后转移元素到新数组中 

5. 扩容的判断也是每个Segment内部单独判断的，判断是否超过阈值 

> 1.8版本 

**扩容相关的属性:**

1. `nextTable`: 扩容期间，将元素迁移到 nextTable 新Map, nextTable是共享变量。

2. `sizeCtl`: 多线程之间，sizeCtl来判断ConcurrentHashMap当前所处的状态。

   	- 通过CAS设置sizeCtl属性，告知其他线程ConcurrentHashMap的状态变更。

   ```
   sizeCtl = 0：表示没有指定初始容量
   sizeCtl > 0：表示初始容量(可以使用阶段)
   sizeCtl = -1,标记作用，告知其他线程，正在初始化
   sizeCtl = 0.75n ,扩容阈值
   sizeCtl < 0 : 表示有其他线程正在执行扩容or初始化(不能使用阶段)
   sizeCtl = (resizeStamp(n) << RESIZE_STAMP_SHIFT) + 2 :表示此时只有一个线程在执行扩容
   ```

3. `transferIndex`: 扩容索引，表示已经完成数据分配的table数组索引位置。

   - 数据转移已经到了哪个位置? 其他线程根据这个值帮助扩容从这个索引位置继续转移数据

4. `ForwardingNode节点`: 标记作用,表示此节点已经扩容完毕
   	- 数组位置的数据已经被转移到新Map中,此位置就会被设置为这个属性
   	- 这个属性包装了新Map,可以用find方法取扩容转移后的值

   ```java
   //旧数据分成两部分,分别放在新容器nextTable的i位置和i + n位置
   //如果扩容后重新存放数据,重新计算hash后hash不变则继续存在之前的索引位置
   //如果重新计算hash不等于之前的hash,则存在索引i + n的位置,与HashMap是一样的
   setTabAt(nextTable, i, ln);
   setTabAt(nextTable, i + n, hn);
   //记录旧数据的i位置的所有元素已经完成转移
   //并且i位置存放的ForwardingNode是包装了新容器nextTable
   setTabAt(tab, i, ForwardingNode);
   ```

**何时才会扩容?**

1. `第一种`:容量超过阈值，进⾏扩容 

   ```java
    private final void addCount(long x, int check) {
        ...
        if (check >= 0) {
            //s >= (long)(sc = sizeCtl); 此时sizeCtl是扩容阈值，s是数据个数,大于阈值就要扩容
            while (s >= (long)(sc = sizeCtl) && 
                   (tab = table) != null && 
                   (n = tab.length) < MAXIMUM_CAPACITY) {
               		 ...
            	}
        }
   }
   ```

   - 如果是第一个线程扩容,容量左移一位(容量 * 2)

   ```java
private transient volatile Node<K,V>[] nextTable;
   
   private final void transfer(Node<K,V>[] tab, Node<K,V>[] nextTab) {
   	...
      if (nextTab == null) { 
           //容量翻倍
           Node<K,V>[] nt = (Node<K,V>[])new Node<?,?>[n << 1];
           //将新的数组赋值到类成员变量共享
           //如果扩容没有完成,多线程会使用这个共享变量继续将原来的没有完成的部分数据转移到这个变量中
           nextTable = nt;
      }
       //下面 ↓ 数据转移部分
   }
   ```
   
   - 如果第二个或其他多个线程进来帮助扩容,因为成员变量都是共享的
  - 所以跳过上一步容量翻倍的步骤(第一个线程已经翻倍),直接到数据转移的代码块
   
   ```java
private final void transfer(Node<K,V>[] tab, Node<K,V>[] nextTab) {
       ...
       //下面 ↓ 数据转移部分
   }
   ```
   
   

2. `第二种`: 链表超过8,扩容

```java
final V putVal(K key, V value, boolean onlyIfAbsent) {
    	...
        if (binCount != 0) {
            //binCount:链表长度 TREEIFY_THRESHOLD:树节点阈值(8)
            if (binCount >= TREEIFY_THRESHOLD)
                //准备转换为树
                treeifyBin(tab, i);
            if (oldVal != null)
                return oldVal;
            break;
        }
}
private final void treeifyBin(Node<K,V>[] tab, int index) {
    	...
        //MIN_TREEIFY_CAPACITY:64 数组长度不足64,尝试扩容,与HashMap一样
        if ((n = tab.length) < MIN_TREEIFY_CAPACITY){
            tryPresize(n << 1);
        }else{
            //转换成红黑树
        }
    	...
}
```

3. `第三种`: 当其他线程发现有线程正在扩容时,帮助线程先扩容

```java
final V putVal(K key, V value, boolean onlyIfAbsent) {
   		 ...
        //f.hash == MOVED 表示为：ForwardingNode，说明其他线程正在扩容
        //并且这个数组的位置数据已经转移到新的数组结构中
        //但是数据还没有全部转移完成,帮助线程先扩容
        else if ((fh = f.hash) == MOVED){
            tab = helpTransfer(tab, f);
        }
   		 ...
}
```

**扩容过程分析**

1. 线程执行put操作，发现容量已经达到扩容阈值，需要进行扩容操作
2. 扩容线程A 以CAS机制修改transferindex值,然后按照`降序`迁移数据,transferindex是数组尾部的索引
   - transferindex的初始值: `新数组的长度 - 1` -> 就是数组的最后一位
3. 迁移hash桶时，会将桶内的链表或者红黑树，按照一定算法，拆分成2份，将其插入`nextTable[i]和nextTable[i+n]`（n是之前table数组的长度）。 
   - 扩容后重新计算的hash值与之前hash值一样,则存放位置不变
   - 重新计算的hash值与之前hash值不一样,则存放再索引`i +n`处(之前的数组长度 + 计算的索引)
4. 迁移完毕的hash桶,都会被设置成ForwardingNode节点，以此告知访问此桶的其他线程，此节点已经迁移完毕,但数据并没有全部迁移完成。
5. 此时线程2访问到了ForwardingNode节点，如果线程2执行的put或remove等写操作，那么就会先帮其扩容。
   - 如果线程2执行的是get等读方法，则会调用ForwardingNode的find方法，去nextTable里面查找相关元素。

> `点赞.靓仔`

