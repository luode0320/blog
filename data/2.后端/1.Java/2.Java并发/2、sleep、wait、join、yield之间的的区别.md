# sleep()、wait()、join()、yield()之间的的区别 

> **内部锁**

- 每个对象都有`内部锁`,内部锁会维护**两个集合结构**
- `Entry Set(网上有叫锁池)`: 多个线程抢锁,没抢到的线程加入锁池(Entry Set)
- `Wait Set(网上有叫等待池)`: 调用**wait⽅法阻塞的线程**,会加入这个等待池Wait Set
- 一个线程只能加入锁池或者等待池,线程不管加入哪个池,都代表此时已经不在持有锁了
  - 没抢到锁的,不持有锁,调用wait方法的也不持有锁

1. sleep 是 Thread 类的静态本地⽅法，wait 则是 Object 类的本地⽅法。 
   - 为什么wait 是 Object 类的本地⽅法?
   - 看这着篇[为什么wait 是 Object 类的本地⽅法?]()

2. sleep⽅法不会释放lock，但是wait会释放，⽽且sleep⽅法会加⼊到等待队列中。
   - sleep就是把cpu的执⾏资格和执⾏权释放出去，不再运⾏此线程，当定时时间结束再取回cpu资源

3. sleep⽅法不依赖于同步器synchronized，但是wait需要依赖synchronized关键字。 
   - 为什么wait需要依赖synchronized关键字?
   - 看这着篇[为什么wait需要依赖synchronized关键字?]()

4. sleep不需要被唤醒（休眠之后推出阻塞），但是wait需要（不指定时间需要被别⼈中断）。 
   - wait需要用notify唤醒的原因是可以进行`线程通信`

5. sleep ⼀般⽤于当前线程休眠，或者轮循暂停操作，wait 则多⽤于多线程之间的通信。 

6. yield（）执⾏后线程直接进⼊就绪状态，⻢上`释放了cpu的执⾏权`，但不释放锁

7. join（）执⾏后当前线程进⼊阻塞状态，强制执行指定的线程
   - join方法内部也是调用wait方法阻塞当前线程