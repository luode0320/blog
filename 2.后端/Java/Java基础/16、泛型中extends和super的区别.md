# 泛型中extends和super的区别

```java
class B extends A{}
							 -> A > B > C
class C extends B{}	
```

> <? extends B>表示包括B在内的任何B的⼦类`(B和C)`

> <? super B>表示包括B在内的任何B的⽗类  `(B和A)`

