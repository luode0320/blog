# ArrayList和LinkedList区别

**ArrayList：查询快，增删慢**

**LinkedList：查询慢，增删块**

> ⾸先，他们的底层数据结构不同，ArrayList底层是基于数组实现的，LinkedList底层是基于链表实现的 

- 有点类似于ArrayList是把数组结构封装了一遍,LinkedList是把链表结构封装了一遍,让我们更好的去操作数组和链表

> 提示: 任何时候都不要使用 Java 的 LinkedList

**ArrayList**

- ArrayList作为数组有索引,查询起来比较快
- 如果ArrayList在中间插入删除的时候,ArrayList会移动数组节点的位置,所以用ArrayList就行插入删除时效率会较低

**LinkedList**

- LinkedList作为链表,不存在与数组一样的索引,查询只能从头节点或者尾节点开始,遍历查询匹配,查询效率对比ArrayList会低
- 但是链表每个节点储存前一个节点和后一个节点的地址,所以LinkedList进行插入删除的时候,不会跟ArrayList一样需要移动众多数据位置,只需要更改相邻节点的前后属性,插入删除效率会高很多

LinkedList查询都需要从从头节点或者尾节点开始, 所以虽然插入删除的时候不需要移动众多数据位置, 但是他要查询到这个位置数据量大的时候,
也是个垃圾玩具。

