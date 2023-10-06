# Java中的异常体系是怎样的 

- Java中的所有异常都来⾃顶级⽗类`Throwable`。 

- Throwable下有两个⼦类`Exception`和`Error`。 

- Error是程序⽆法处理的错误，⼀旦出现这个错误，则程序将被迫停⽌运⾏。 
  - 这是没有办法了,比如说内存不够了,这你没办法...

- Exception不会导致程序停⽌，⼜分为两个部分`RunTimeException运⾏时异常`和`CheckedException检查异常`。 
  - `RunTimeException`也叫`非检查型异常`,常常发⽣在程序运⾏过程中，会导致程序当前线程执⾏失败。
    - 强制转换异常丶空指针异常丶超出数组下标异常啊! 这些异常应该人为去解决掉的
  - `CheckedException`常常发⽣在程序编译过程中,还没有运行，会导致程序编译不通过。
    - 类没有找到异常丶文件没有找到异常丶方法找不到异常(Spring创建Bean的时候找不到构造方法)等

