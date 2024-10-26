# 有HashMap为什么还要有HashSet?

**Set的作用大概就是无序丶去重,但是这写概念其实用Map也能做到,为什么还要有Set呢?**

> HashSet本来就是HashMap,只不过value是一个默认值罢了,那我用Map去操作,value给一个默认值不就行了吗?

- 实际上HashSet就是一个优化版本的HashMap,就是为了简化`不用操心value只操心key`的一个简化版本
- `去重更方便`了,不用自己使用Map的时候put默认搞一个value,而多一些操作
  - 就像`HashMap与HashTable`一样,我只要给HashMap的每次操作之前都自己手动加一个锁就行,那还要HashTable干什么?
  - 其实就是为了简化加锁这个步骤罢了
- 所以HashSet就是为了`简化HashMap只使用key的一个简化操作类`
- 因为如果我自己要实现,那操作HashMap时,手动把value赋值一个默认值就好了嘛!!!

