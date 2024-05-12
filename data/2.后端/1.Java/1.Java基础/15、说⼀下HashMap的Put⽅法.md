# 说说HashMap的Put方法的大体流程： 

1. 根据Key通过哈希算法与与运算得出数组下标 

```java
tab[i = (n - 1) & hash]
```

2. 如果数组下标位置元素为空，则将key和value封装为Entry对象（JDK1.7中是Entry对象，JDK1.8中 是Node对象）并放⼊该位置 

```java
tab[i] = newNode(hash, key, value, null);
```

3. 如果数组下标位置元素不为空，则要分情况讨论 

   1. 如果是`JDK1.7`，则先判断是否需要扩容，如果要扩容就进⾏扩容，如果不⽤扩容就⽣成Entry 对象，并使⽤头插法添加到当前位置的链表中 

   2. 如果是`JDK1.8`，则会先判断当前位置上的Node的类型，看是红⿊树Node，还是链表Node 

      1. 如果是红⿊树Node，则将key和value封装为⼀个红⿊树节点并添加到红⿊树中去，在这个过程中会判断红⿊树中是否存在当前key，如果存在则更新value 

      ```java
       e = ((TreeNode<K,V>)p).putTreeVal(this, tab, hash, key, value);
      ```

      2. 如果此位置上的Node对象是链表节点，则将key和value封装为⼀个链表Node并通过尾插法插⼊到链表的最后位置去，因为是尾插法，所以需要遍历链表，在遍历链表的过程中会判断是否存在当前key，如果存在则更新value，当遍历完链表后，将新链表Node插⼊到链表中，插⼊到链表后，会看当前链表的节点个数，如果⼤于等于8，那么则会将该链表转成红⿊树 

      ```java
      for (int binCount = 0; ; ++binCount) {
          if ((e = p.next) == null) {
              p.next = newNode(hash, key, value, null);
              if (binCount >= TREEIFY_THRESHOLD - 1) // -1 for 1st
                  //树
                  treeifyBin(tab, hash);
              break;
          }
          if (e.hash == hash &&
              ((k = e.key) == key || (key != null && key.equals(k))))
              break;
          p = e;
      }
      ```

      

      3. 将key和value封装为Node插⼊到链表或红⿊树中后，再判断是否需要进⾏扩容，如果需要就扩容，如果不需要就结束PUT⽅法

      ```java
      if (++size > threshold)
          resize();
      ```

      