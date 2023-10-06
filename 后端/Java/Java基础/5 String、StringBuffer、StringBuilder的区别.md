# String、StringBuffer、StringBuilder的区别 

- String是不可变的，如果尝试去修改，会新⽣成⼀个字符串对象，StringBuffer和StringBuilder是可变的 

- StringBuffer是线程安全的，StringBuilder是线程不安全的，所以在单线程环境下StringBuilder效率会更⾼ 

> 你不会以为面试就这么回答吧！15s就没了？你回去等通知吧！！！

**String**

```java
public final class String {
    /** 该值用于字符存储. */
    private final char value[];
}
```

- String的底层是一个不可变的char[ ]，且操作String都会直接new一个新的String
  - 每一个String初始化后就是不可变的，变化了char型数组地址变了就是另一个字符串
- 如果我们用拼接字符串的方式`“str” + “ing”`实际上内存开辟了2个String的地址 + 一个结果String地址
  - 最后用作拼接的两个String用完就没用了
  - 所以过多的这样拼接会造成大量浪费有限的内存空间
- StringBuffer类和StringBuild类就是为了解决这个问题产生的

**StringBuffer和StringBuild**

```java
public final class StringBuffer extends AbstractStringBuilder{ 
	/**
     * 构造一个字符串生成器，其中不包含任何字符，并且
	 * 初始容量为16个字符。
     */
     public StringBuffer() {
        super(16);
    }
}

public final class StringBuilder extends AbstractStringBuilder{
    public StringBuilder() {
        //AbstractStringBuilder的构造器
        super(16);
    }
}
abstract class AbstractStringBuilder implements Appendable, CharSequence {
    //不是final，说明甚至可以换个数组依然是用一个对象
    char[] value;
    AbstractStringBuilder(int capacity) {
        value = new char[capacity];
    }
}
```

- StringBuffer类和StringBuild类底层是一个可变的char[ ]，且操作StringBuffer和StringBuild是在改变这个数组的内容，并不是重新new一个新的对象
  - 所以操作StringBuffer类和StringBuild类不会随意开辟内存，不容易浪费内存空间
  - 如果拼接字符串长度大于16，会扩容`(value.length << 1) + 2`(（当前容量*2）+2)

**StringBuffer是线程安全的，StringBuilder是线程不安全的**

```java
@Override
public synchronized StringBuffer append(Object obj) {
    toStringCache = null;
    super.append(String.valueOf(obj));
    return this;
}
```

```java
@Override
public StringBuilder append(Object obj) {
    return append(String.valueOf(obj));
}
```

> 很简单了，StringBuffer方法加了synchronized关键字，StringBuilder没加
>
> StringBuffer是加过Buff的！！！