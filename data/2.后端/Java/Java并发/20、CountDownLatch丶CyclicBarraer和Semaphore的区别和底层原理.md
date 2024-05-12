# CountDownLatch丶CyclicBarrier和Semaphore的区别和底层原理

> CountDownLatch表示`计数器`，可以给CountDownLatch设置⼀个数字,CountDownLatch是一个`同步工具类`，用来`协调多个线程之间`的同步，或者说起到`线程之间的通信`

- 从名字可以猜出,是做数量减法的一种机制
- CountDownLatch能够使`线程`在`等待另外一些`线程完成各自工作之后，再继续执行。
  - 另外的线程每执行完一个计数器就减一
- 调⽤await()⽅法阻塞线程,是利⽤`AQS排队`,加入阻塞队列
- 其他线程可以调⽤CountDownLatch的`countDown()`⽅法来对 CountDownLatch(计数器)中的数字减⼀
- 当数字被减成0后，`所有await阻塞`的线程都将被唤醒。 
  - 例如一些**核心组件线程和我们的工作线程**
  - 我们可以把`我们的工作线程`用**await()**方法加入到阻塞队列中
  - 然后先执行`依赖的核心组件线程`,每执行完成一个计数器**减一**
  - 直到减完了,我们的工作线程就会`被队列以先进先出的方式全部唤醒`,正常执行

```java
//定义一个计数器,计数器参数表示在计数器阻塞线程执行之前该有多少线程执行
CountDownLatch countDownLatch = new CountDownLatch(2);
//第一个线程
new Thread(() -> {
    //计数器减一,如果计数器为0,则释放所有阻塞线程
    countDownLatch.countDown();
}).start();
//第二个线程
new Thread(() -> {
 	//计数器减一,如果计数器为0,则释放所有阻塞线程
    countDownLatch.countDown();
}).start();
//当前线程加入阻塞队列
countDownLatch.await();
```

- 工作场景: 
  - 前端需要显示全市各个村落的一些聚合信息(平均年龄丶人均占地面积)
  - 先阻塞汇主线程
  - 每次村落的信息对应不同数据库表,我们需要多个线程来统计
  - 统计完成唤醒汇总的主线程,执行最后统计步骤

**相对的还有一个CyclicBarrier**

- CyclicBarrier可以使一组线程等待,当线程数量够时,一起执行
- 利用await()阻塞,每次阻塞一个线程并且计数变量减一
- 当计数变量为0时,将之前阻塞的线程都一起唤醒
  - 当阻塞的线程达到了规定的数量的时候就一起释放

```java
CyclicBarrier barrier = new CyclicBarrier(3, () -> {...});
for (int i = 0; i < 3; i++) {
    new Thread(() -> {
 	//将此线程阻塞并计数器减一,如果计数器为0,则释放所有刚刚阻塞线程
    barrier.await();
	}).start();
}
```

**CountDownLatch是先执行前置的线程,再执行任务线程**

**CyclicBarraer是指定一定数量的线程在某一刻一起执行**

- 工作场景: 
  - 需要计算城市中的农村人口丶农村中的城市人口
  - 需要多个线程先计算出哪些城市人口和哪些农村人口,堵塞优先计算完成线程
  - 保证这所有数据计算完成之后,唤醒所有线程
  - 中间需要线程之间通信,进行数据交换,要保证各个线程达到了加入下一个阶段的要求

> Semaphore表示`信号量`，Semaphore可以控制`同时访问的线程个数`

- 通过`acquire()`来获取许可，如果`没有许可可⽤则线程阻塞`，并通过`AQS`来排队
  - 许可就是**判断同时访问的线程有没有超过指定的限制**
  - 如果同时访问的线程过多,则将申请的线程加入阻塞队列
  - **这是一种共享锁**,AQS的state变量记录的是`共享锁的数量`
  - 不再是独占锁那样,记录的是**0还是大于0去判断是否上锁**
- 可以通过`release() `⽅法来释放许可，当`某个线程执行完释放了某个许可后`，会从AQS中正在排队的`第⼀个线程`开始依次唤醒，`直到没有空闲许可`。 
  - 释放许可就是表示可以使多余的线程执行

```java
//同时访问的线程个数 state=2
private static Semaphore semaphore = new Semaphore(2);
for (int i = 0; i < 5; i++) {
    new Thread(() -> {
        try {
            // 获取令牌尝试进入
            semaphore.acquire();
            // 释放令牌
            semaphore.release();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }).start();
}
```

- 工作场景:
  - 这个任务需要多线程进行,但是为了系统的效率,最多使用2个线程池中的线程来处理任务