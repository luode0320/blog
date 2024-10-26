# ==和equals方法之前的区别 

>  == :
>
> 对⽐的是栈中的值，基本数据类型是变量值，引⽤类型是堆中内存对象的地址 

>  equals：
>
> object中默认也是采⽤==⽐较，也就是实际上默认equals和==是一个东西
>
> 但是这个方法大多数类会`重写`,重新构造不同的比较逻辑,重写过的不同很正常,不然重写干嘛

Object 

```java
public boolean equals(Object obj) { 
    return (this == obj); 
}
```

String 

```java
public boolean equals(Object anObject) {
        if (this == anObject) {
            return true;
        }
        if (anObject instanceof String) {
            String anotherString = (String) anObject;
            int n = value.length;
            //把要比较的那两字符串,一个一个拆成字符去比较,有一个不相等就false
            if (n == anotherString.value.length) {
                char v1[] = value;
                char v2[] = anotherString.value;
                int i = 0;
                while (n-- != 0) {
                    if (v1[i] != v2[i]) {
                        return false;
                    }
                    i++;
                }
                return true;
            }
        }
        return false;
    }
```

上述代码可以看出，String类中被复写的equals()⽅法其实是⽐较两个字符串的内容。 

```java
public static void main(String args[]) {
    String str1 = "Hello";//常量池中,有固定地址
    String str2 = new String("Hello");//新对象,新内存地址
    String str3 = str2; // 引⽤传递,传递地址
    System.out.println(str1 == str2); // false ,地址不同
    System.out.println(str1 == str3); // false ,地址不同
    System.out.println(str2 == str3); // true ,地址相同
    System.out.println(str1.equals(str2)); // true ,一个个字符比较,相同
    System.out.println(str1.equals(str3)); // true ,一个个字符比较,相同
    System.out.println(str2.equals(str3)); // true ,一个个字符比较,相同
}
```

