# ReentrantLock中tryLock()和lock()⽅法的区别 

>  tryLock()表示尝试加锁，可能加到，也可能加不到，该⽅法不会阻塞线程，如果加到锁则返回 true，没有加到则返回false 

- 这个方法可以选择一个参数,表示超时时间
- 可以用这个方法搞一个`获取锁的时间期限`,避免死锁
  - 用循环来设置

```java
while (lock.tryLock()) {
	//时间控制,延时函数
}
lock.unlock();
```

> lock()表示阻塞加锁，线程会阻塞直到加到锁，⽅法也没有返回值 

```java
lock.lock();
try {
    return currentFuture.isCancelled();
} finally {
    lock.unlock();
}
```

