# 谈谈你对AQS的理解，AQS如何实现可重⼊锁？ 

- AQS是⼀个JAVA线程同步的核心组件。是JDK中很多`锁⼯具的核心组件`。 
- AQS的锁是`先尝试CAS乐观锁`去获取锁，获取不到，才会转换为`悲观锁`
- 在AQS中，维护了⼀个`信号量state`丶`加锁线程变量`和⼀个线程组成的`双向链表队列`。
  - 其中，这个线程队列，就是⽤来给线程排队的
  - 加锁线程变量就是`当前加锁的线程`
  - ⽽state就像是⼀个红绿灯，⽤来控制线程排队或者放⾏的。 
    - 这个加锁的过程，直接就是用`CAS`操作将state值从0变为1。
    - **预计为0,修改+1**
- **如果是同一个线程,多次加锁state就会叠加**,不会出现死锁
- 在可重⼊锁这个场景下，state就⽤来表示加锁的次数。
  - 0标识⽆锁，每加⼀次锁，state就加1。释放锁state就减1。 

> state变量在AQS类中`private volatile int state;`
>
> 双向链表队列变量在AQS类中`private transient volatile Node head;`
>
> 加锁线程变量在**`AOS`**类中`private transient Thread exclusiveOwnerThread;`

