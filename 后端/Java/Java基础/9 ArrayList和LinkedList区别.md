# ArrayList和LinkedList区别

**ArrayList：查询快，增删慢**

**LinkedList：查询慢，增删块**

> ⾸先，他们的底层数据结构不同，ArrayList底层是基于数组实现的，LinkedList底层是基于链表实现的 

- 有点类似于ArrayList是把数组结构封装了一遍,LinkedList是把链表结构封装了一遍,让我们更好的去操作数组和链表

> 由于底层数据结构不同，他们所适⽤的场景也不同，ArrayList更适合随机查找，LinkedList更适合 删除和添加，查询、添加、删除的时间复杂度不同 

**ArrayList**

- ArrayList作为数组有索引,查询起来比较快
- 如果ArrayList在中间插入删除的时候,ArrayList会移动数组节点的位置,所以用ArrayList就行插入删除时效率会较低

**LinkedList**

- LinkedList作为链表,不存在与数组一样的索引,查询只能从头节点或者尾节点开始,遍历查询匹配,查询效率对比ArrayList会低
- 但是链表每个节点储存前一个节点和后一个节点的地址,所以LinkedList进行插入删除的时候,不会跟ArrayList一样需要移动众多数据位置,只需要更改相邻节点的前后属性,插入删除效率会高很多

```
如果数据需要经常增删,那么选择LinkedList会比ArrayList好很多。

如果不知道要储存多少数据,可能需要add很多次时（几万几十万）,
考虑到ArrayList作为数组需要扩容,选择LinkedList会优于ArrayList。

如果没有什么花里胡哨的东西，默认使用ArrayList就可以
```

> 另外ArrayList和LinkedList都实现了List接⼝，但是LinkedList还额外实现了Deque接⼝，所以LinkedList还可以当做队列来使⽤

- 队列：先进先出，后进后出
- 只对链表的头和尾进行增删操作就可以模拟队列的结构