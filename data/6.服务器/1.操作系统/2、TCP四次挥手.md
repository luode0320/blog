### TCP四次挥手

TCP四次挥手是指在TCP连接终止时的四个步骤。这四个步骤**确保了连接的双方都能正确地结束连接**，并且没有数据丢失。

作为一个经典的面试题, 主要的原因是你需要考虑客户端和服务端双方, 而不是仅仅考虑某一方。

- 如果先考虑**确认一方正确地结束连接**
    - 我在一张纸条上写上 **数据发送完毕准备结束** 发给另一方
    - 另一方看到之后发给我 **已经收到所有数据, 请等我的响应数据发完**
- 然后再考虑**确认另一方正确地结束连接**
    - 同样作为另一方在一张纸条上写上 **响应数据发送完毕准备结束** 发给我
    - 我看到之后发给另一方 **我已经收到所有响应数据,确认结束**
- 整合一下
    1. 客户端发送 **数据发送完毕准备结束** 的信息给服务端
    2. 服务端发送 **已经收到所有数据, 请等我的响应数据发完** 的信息给客户端
    3. 服务端发送 **响应数据发送完毕准备结束** 的信息给客户端
    4. 客户端发送 **我已经收到所有响应数据,确认结束** 的信息给服务端

因为步骤 2 3 之间是需要等待或者做ita事情的, 所以 2 3 步骤不能像三次握手那样合并。

### 状态和步骤

- **FIN(结束)**: 在四次挥手的第一步中，**客户端**决定关闭连接，并**发送**一个FIN标志位设置为1的段，通知服务器端准备关闭连接。

- **ACK (确认)**：在四次挥手的第二步中，**服务器**接收到FIN段后，**发送**一个ACK段，确认接收到客户端的FIN段
- **FIN(结束)**：在四次挥手的第三步中，**服务器**发送完所有数据后，也**发送**一个FIN标志位设置为1的段，通知客户端准备关闭连接。
- **ACK (确认)**：在四次挥手的第四步中，**客户端**接收到服务器的FIN段后，**发送**一个ACK段，确认接收到服务器的FIN段。

**这些状态通常 1 表示真, 0 表示假。**

#### 第一步：客户端发送FIN段

假设客户端决定关闭连接，并发送一个FIN标志位设置为1的段。这一步通常发生在应用程序调用`close()`函数时触发。

```c
static void tcp_fin(struct sock *sk)
{
    struct tcp_sock *tp = tcp_sk(sk);
    struct sk_buff *skb;
    struct tcphdr *th;

    /* 构造FIN段 */
    skb = tcp_skbuff(sk);
    th = tcp_hdr(skb);
    /* 设置TCP头部的FIN标志位为1 */
    th->fin = 1;
    /* 设置TCP头部的ACK标志位为1: 同时也确认了之前接收到的所有数据段 */
    th->ack = 1;

    /* 设置下一个待发送的数据的序列号 */
    tp->write_seq = tp->seq_cnt.seq + 1; /* Initialize sequence number */

    /* 发送FIN段 */
    tcp_transmit_skb(sk, skb, 0, sk->sk_dst_cache);
}
```

#### 第二步：服务器发送ACK段

服务器接收到客户端的FIN段后，发送一个ACK段确认接收到FIN段。

```c
static void tcp_v4_rcv(struct sk_buff *skb, struct sock *sk,
                       struct net *netns)
{
    struct tcphdr *th = tcp_hdr(skb);
    struct tcp_sock *tp = tcp_sk(sk);

    /* 检查FIN(结束)标志是否为true,检查RST(重置)标志是否为false */
    if (th->fin && !th->rst) {
        /* 设置序列号和确认号 */
        tp->rcv_nxt = ntohl(th->seq) + 1;
        tp->write_seq = tp->seq_cnt.seq + 1;
        
        /* 构造ACK段 */
        skb = tcp_skbuff(sk);
        th = tcp_hdr(skb);
        /* 设置TCP头部的ACK标志位为1 */
        th->ack = 1;
        
        /* 发送ACK段 */
        tcp_transmit_skb(sk, skb, 0, sk->sk_dst_cache);
    }
}
```

#### 第三步：服务器发送FIN段

服务器发送完所有数据后，也发送一个FIN标志位设置为1的段。

```c
static void tcp_fin(struct sock *sk)
{
    struct tcp_sock *tp = tcp_sk(sk);
    struct sk_buff *skb;
    struct tcphdr *th;

    /* 构造FIN段 */
    skb = tcp_skbuff(sk);
    th = tcp_hdr(skb);
    /* 设置TCP头部的FIN标志位为1 */
    th->fin = 1;
    /* 设置TCP头部的ACK标志位为1 */
    th->ack = 1;

    /* 设置序列号 */
    tp->write_seq = tp->seq_cnt.seq + 1; /* Initialize sequence number */

    /* 发送FIN段 */
    tcp_transmit_skb(sk, skb, 0, sk->sk_dst_cache);
}
```

#### 第四步：客户端发送ACK段

客户端接收到服务器的FIN段后，发送一个ACK段确认接收到FIN段。

```c
static void tcp_v4_rcv(struct sk_buff *skb, struct sock *sk,
                       struct net *netns)
{
    struct tcphdr *th = tcp_hdr(skb);
    struct tcp_sock *tp = tcp_sk(sk);

    /* 检查FIN标志是否设置 */
    if (th->fin && !th->rst) {
        /* 设置序列号和确认号 */
        tp->rcv_nxt = ntohl(th->seq) + 1;
        tp->write_seq = tp->seq_cnt.seq + 1;
        
        /* 构造ACK段 */
        skb = tcp_skbuff(sk);
        th = tcp_hdr(skb);
   		/* 设置TCP头部的ACK标志位为1: 同时也确认了之前接收到的所有数据段 */
        th->ack = 1;
        
        /* 发送ACK段 */
        tcp_transmit_skb(sk, skb, 0, sk->sk_dst_cache);
    }
}
```

### 提示

**设置TCP头部的ACK标志为1**:  在TCP的连接中, 所有的交互除了第一次连接请求不需要带上 ACK 确认, 其他任何时候都需要 ACK
确认之前接收到的所有数据段 