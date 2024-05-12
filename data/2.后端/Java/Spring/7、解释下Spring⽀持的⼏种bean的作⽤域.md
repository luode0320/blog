# 解释下Spring⽀持的⼏种bean的作⽤域

- `singleton`：默认，单例Bean,再**确定Id的情况下,只有一个Bean匹配**。

- `prototype`：非单例Bean。**每获取一次都重新创建一个新的**。

- `request`：bean被定义为在**每个HTTP请求中创建⼀个单例对象**，每个HTTP请求都会创建一个新的专门给这个请求复用使用，HTTP请求结束，Bean销毁。 

- `session`：**每个请求的session中有⼀个专门的bean的实例**，在session过期后，Bean销毁。 