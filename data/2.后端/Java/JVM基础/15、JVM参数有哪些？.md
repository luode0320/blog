# JVM参数有哪些？ 

**1. 堆参数**

- -Xms: 初始化堆内存
- -Xmx: 最大堆内存
- -Xmn: 设置新生代内存,剩余的为老年代的

**2. 回收器参数**

- -XX:Use收集器名称
  - SerialGC丶ParallerGC丶ParallerOldGC丶ConcMarkSweep丶G1GC