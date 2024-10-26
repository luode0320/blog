# 简介

`sync.Once`的原理基于一个`sync.Once`结构体和一个`sync.Once.Do`方法来实现。

- `sync.Once`结构体内部包含一个`done`字段，用来标记初始化是否已经完成。
- `sync.Once`的`Do`方法会通过CAS(Compare-And-Swap)原子操作来确保只有第一个调用`Do`时才执行传入的函数，后续的调用则直接返回而不执行。



# 源码解析

`src/sync/once.go`

## 数据结构

```go
// Once 是一个仅执行一次操作的对象。
//
// 一个 Once 在第一次使用后不应再复制。
type Once struct {
	done uint32 // done 表示操作是否已经执行。
	m    Mutex  // 同步锁
}
```



# Do()调用函数

```go
// Do 方法只有在首次针对该 Once 实例调用 Do 时才调用函数 f。
func (o *Once) Do(f func()) {
	// 原子操作, 判断是否为 0, 未调用
	if atomic.LoadUint32(&o.done) == 0 {
		// 已实现慢路径以允许快路径内联。
		o.doSlow(f)
	}
}
```



### doSlow()加锁双重判定后调用回调

```go
func (o *Once) doSlow(f func()) {
	o.m.Lock()
	defer o.m.Unlock()

	// 加锁, 双重判断, 类似于单例模式
	if o.done == 0 {
		// 原子操作, 修改为, 已调用
		defer atomic.StoreUint32(&o.done, 1)

		f()
	}
}
```

