### TCP三次握手

三次握手是TCP协议为了**确保收发双方的接收与发送能力**而设计的一个流程。

作为一个经典的面试题, 主要的原因是你需要考虑客户端和服务端双方, 而不是仅仅考虑某一方。

- 如果先考虑**确认一方的接收与发送能力**
    - 我在一张纸条上写上1发给另一方, 另一方看到之后告诉我纸条上是1
    - 那么我就可以确定, 另一方可以接受到纸条, 并且另一方可以回应告诉我纸条上是1
    - 表示对方有接受和发送的能力
- 然后再考虑**确认另一方的接收与发送能力**
    - 同样作为另一方在一张纸条上写上2发给我, 我看到之后告诉另一方纸条上是2
    - 那么另一方就可以确定, 我可以接受到纸条, 并且我可以回应告诉另一方纸条上是2
    - 表示我有接受和发送的能力
- 最后将两个步骤整合一下
    1. 我在一张纸条上写上1发给另一方, 另一方看到之后告诉我纸条上是1
    2. 另一方接受到纸条, 并且另一方可以回应告诉我纸条上是1
    3. 另一方在一张纸条上写上2发给我, 我看到之后告诉另一方纸条上是2
    4. 我接受到纸条, 并且我可以回应告诉另一方纸条上是2
- 然后优化一下步骤, **发现 2 3 的步骤之间是不需要等待或者做其他事的**, 可以合在一起就变成
    1. 我在一张纸条上写上1发给另一方, 另一方看到之后告诉我纸条上是1
    2. 另一方接受到纸条, 并且另一方可以回应告诉我纸条上是1, 同时另一方在一张纸条上写上2发给我
    3. 我接受到纸条, 并且我可以回应告诉另一方纸条上是2

### 状态和步骤

- **SYN(同步)**: 在三次握手的第一步中，客户端发送的第一个SYN段。

- **SYN(同步) + ACK (确认)**：在三次握手的第二步中，服务器向客户端发送的SYN-ACK段。
- **ACK (确认)**：在三次握手的第三步中，客户端向服务器发送的ACK段。

**这些状态通常 1 表示真, 0 表示假。**

### 第一步：SYN（同步序列编号）

客户端向服务端发送一个SYN（同步）段，表示客户端想要建立连接。

这个段包含了一个随机初始化的序列号，用于后续的数据传输。序列号就会根据数据段的发送和确认来**动态调整**。具体来说：

1. **发送数据段**：每当发送一个新的数据段时，序列号会递增相应的长度。例如，如果发送了一个包含100个字节的数据段，则序列号会递增100。
2. **确认数据段**：当接收到对端的ACK确认时，序列号也会相应地更新。ACK确认号告诉发送方哪些数据已经被成功接收，这样发送方就可以知道下一个需要发送的数据的序列号。

```c
/*
static int：声明这是一个静态的整型函数。static关键字意味着这个函数只能在这个文件内部调用。
tcp_v4_connect：函数名称，表示这是一个处理TCP连接建立的函数。
struct sock *sk：函数接受一个指向sock结构体的指针作为参数，sock结构体通常表示一个网络套接字。
*/
static int tcp_v4_connect(struct sock *sk)
{
    /* 声明一个指向tcp_sock结构体的指针，并将其初始化为sk所指向的套接字的TCP部分。  */
    struct tcp_sock *tp = tcp_sk(sk);
    /* 声明一个指向sk_buff结构体的指针，用于构建和发送数据包  */
    struct sk_buff *skb;
    /* 声明一个指向tcphdr结构体的指针，用于访问TCP头部信息  */
    struct tcphdr *th;
	
    /* 分配一个新的sk_buff结构体，并将其赋值给skb。tcp_skbuff函数通常用于从内核的内存池中获取一个空的数据包结构。 */
    skb = tcp_skbuff(sk);
    /* 获取skb中的TCP头信息，并将其赋值给th。tcp_hdr函数返回指向skb中的TCP头部的指针。 */
    th = tcp_hdr(skb);

    /* 设置序列号 */
    /* 
    	tp->write_seq：表示下一个待发送的数据的序列号。
		tp->seq_cnt.seq：表示当前连接的序列号。
		+1：因为发送SYN段时，序列号会被递增一次。所以write_seq实际上是发送完SYN段后，下一个数据段的序列号。
    */
    tp->write_seq = tp->seq_cnt.seq + 1; /* 初始化的序列号 */
    
    /* 构造SYN段
    	tcp_set_SYN_flag(sk, skb, th)：设置skb中的TCP头部的SYN标志。这个函数可能负责填充其他必要的字段。
		th->syn = 1;：显式地设置TCP头部的SYN标志为1，表示这是一个SYN段。
    */
    tcp_set_SYN_flag(sk, skb, th);
    th->syn = 1;
    
    /* 发送SYN段: 发送构造好的skb数据包。tcp_transmit_skb函数负责将数据包发送到网络层。 */
    tcp_transmit_skb(sk, skb, 0, sk->sk_dst_cache);

    return 0;
}
```

### 第二步：SYN-ACK（同步并确认）

服务端接收到SYN后，会回应一个SYN+ACK段，表示同意建立连接

并且包含了**自己的初始序列号**以及对**客户端序列号的确认**。

```c
/*
static void：声明这是一个静态的无返回值的函数。static关键字意味着这个函数只能在这个文件内部调用。
tcp_v4_rcv：函数名称，表示这是一个处理TCP v4接收的函数。
struct sk_buff *skb：指向一个sk_buff结构体的指针，表示接收到的数据包。
struct sock *sk：指向一个sock结构体的指针，表示与数据包相关的套接字。
struct net *netns：指向一个net结构体的指针，表示网络命名空间。
*/
static void tcp_v4_rcv(struct sk_buff *skb, struct sock *sk,
                       struct net *netns)
{
    /* 声明一个指向tcphdr结构体的指针，并将其初始化为skb中的TCP头部。 */
    struct tcphdr *th = tcp_hdr(skb);
    /* 声明一个指向tcp_sock结构体的指针，并将其初始化为sk中的TCP套接字部分 */
    struct tcp_sock *tp = tcp_sk(sk);

    /* 检查SYN标志是否设置
    	th->syn：检查TCP头部的SYN(同步)标志是否设置为1。
		th->rst：检查TCP头部的RST(重置)标志是否设置为1。
		if (th->syn && !th->rst)：条件判断语句，只有当SYN标志设置为1且RST标志未设置时才进入该分支
    */
    if (th->syn && !th->rst) {
        /* 设置序列号和确认号 
        	1.设置接收序列号的下一个期望值为接收到的序列号加1
        	2.设置发送序列号的下一个值为当前序列号加1
        */
        tp->rcv_nxt = ntohl(th->seq) + 1;
        tp->write_seq = tp->seq_cnt.seq + 1;
        
        /* 构造SYN-ACK段 */
        /* 从sk中获取一个sk_buff结构体，用于构造新的数据包 */
        skb = tcp_skbuff(sk);
        /* 从新的sk_buff结构体中获取TCP头部 */
        th = tcp_hdr(skb);
        /* 设置TCP头部的SYN标志为1 */
        th->syn = 1;
        /* 设置TCP头部的ACK标志为1 */
        th->ack = 1;
        
        /* 发送SYN-ACK段 */
        tcp_transmit_skb(sk, skb, 0, sk->sk_dst_cache);
    }
}
```

### 第三步：ACK（确认）

客户端接收到SYN-ACK后，再次发送一个ACK段，表示已经收到了服务端的SYN-ACK，并且准备好了开始数据传输。

```c
/*
static void：声明这是一个静态的无返回值的函数。static关键字意味着这个函数只能在这个文件内部调用。
tcp_ack：函数名称，表示这是一个处理TCP ACK（确认）的函数。
struct sock *sk：指向一个sock结构体的指针，表示与数据包相关的套接字。
struct sk_buff *skb：指向一个sk_buff结构体的指针，表示接收到的数据包。
*/
static void tcp_ack(struct sock *sk, struct sk_buff *skb)
{
    /*
    	struct tcphdr *th：声明一个指向tcphdr结构体的指针，并将其初始化为skb中的TCP头部。
		struct tcp_sock *tp：声明一个指向tcp_sock结构体的指针，并将其初始化为sk中的TCP套接字部分。
    */
    struct tcphdr *th = tcp_hdr(skb);
    struct tcp_sock *tp = tcp_sk(sk);

    /* 
    	th->ack：检查TCP头部的ACK标志是否设置为1。
		if (th->ack)：条件判断语句，只有当ACK标志设置为1时才进入该分支。
    */
    if (th->ack) {
        /* 设置接收序列号的下一个期望值为接收到的确认号加1。 */
        tp->rcv_nxt = ntohl(th->ack_seq) + 1;
        
        /* 构造ACK段 */
        /* 从sk中获取一个sk_buff结构体，用于构造新的数据包。 */
        skb = tcp_skbuff(sk);
        /* 从新的sk_buff结构体中获取TCP头部。 */
        th = tcp_hdr(skb);
        /* 设置TCP头部的ACK标志为1 */
        th->ack = 1;
        
        /* 发送ACK段 */
        tcp_transmit_skb(sk, skb, 0, sk->sk_dst_cache);
    }
}
```

### 提示

**设置TCP头部的ACK标志为1**:  在TCP的连接中, 所有的交互除了第一次连接请求不需要带上 ACK 确认, 其他任何时候都需要 ACK
确认之前接收到的所有数据段 

