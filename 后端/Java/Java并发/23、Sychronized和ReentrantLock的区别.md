# Sychronized和ReentrantLock的区别

- ReentrantLock是⼀个类 ,sychronized是⼀个关键字,作为关键字,我们是没有办法过多干预的,就拿来就用,不用想那么多
- sychronized会`⾃动的加锁与释放锁`，ReentrantLock需要程序员`⼿动加锁与释放`
  - Lock锁会忘记释放啊什么什么鬼的
  - 在**JDK版本比较低的时候Lock锁的效率还会高一点**
  - 都是现在大家都用1.8了,sychronized`也有偏向锁和轻量锁了,所以sychronized确实好用`
  - sychronized差不多都把Lock锁的优点加上去了
- sychronized是`⾮公平锁`，ReentrantLock可以`选择公平锁或⾮公平锁 `
  - 某些时候,我们需要加锁并且又需要保证一定的执行顺序,就需要使用到公平锁,就不能继续使用synchronized了
  - 因为synchronized是非公平的,我们只有使用ReentrantLock设置为公平锁来实现
- Lock锁还有一些特殊的方法,比如tryLock这样的可以选择时间控制、循环获取锁
- Lock锁可以手动设置中断,避免死锁
- sychronized锁的是对象，`锁信息保存在对象头`中，ReentrantLock通过代码中int类型的state标识来标识锁的状态 
- sychronized底层有⼀个锁升级的过程,升级过程中可能会产生那么`一丁点的STW`,暂停所有线程
- 一般好像都是用sychronized就好了

