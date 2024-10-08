# 简介

> 消息积压的直接原因，一定是系统中的某个部分出现了性能问题，来不及处理上游发送的消息，才会导致消息积压



前提是: 

- **消息已经在一个分区积压了**, 此时加消费者组, 加消费者都无任何意义了

- 只有在没积压之前, 对同一种消费负载到多个分区, 增加消费者组, 加消费者才有意义

- 如果是某个分区已经积压数据, 导致消费太慢, 是不能通过加消费者处理的

在Kafka中，每个分区的数据都是有序的，并且一个分区的数据只能由一个消费者消费（在同一个消费者组内）

如果你的一个分区已经有大量积压的消息，增加额外的消费者或消费者组并不会直接帮助解决这个问题，因为这些额外的消费者无法并行处理该分区的消息。

- 在一个**给定的消费者组**内，**每个分区只分配给一个消费者**。因此，即使你消费者组增加了更多的消费者，这些消费者也只能消费那些尚未被分配的分区。
- 在**多个消费者组**中, 某条消息可以被多个不同消费者组的消费者消费, 这更不能解决挤压问题解决



# 消息积压的原因

> 能导致积压突然增加，最粗粒度的原因，只有两种：
>
> - 要么是发送变快了，要么是消费变慢了。



消息积压属于一个业务上的问题, 不同的系统、不同的情况有不同的原因，不能一概而论。

但是，我们排查消息积压原因，是有一些相对固定而且比较有效的方法的。



## 发送消息增多

1. 赶上大促或者抢购, 短时间内不太可能优化消费端的代码来提升消费性能，唯一的方法是通过扩容消费端的实例数来提升总体的消费能力
   - 服务器扩容, 增加服务器资源，如CPU、内存、存储和网络带宽，以提高整体处理能力
   - 限流减少发送方发送的数据量, 最低限度让系统还能正常运转
   - 关闭不重要的消息业务, 全力支持主要业务的消息队列使用
2. 有人胡乱压测, 攻击服务器
   - 防火墙规则调整、DDoS缓解措施、封禁恶意IP
   - 限流, 速率限制，防止攻击流量进一步涌入系统
   - 紧急增加服务器资源，如CPU、内存、存储和网络带宽，以提高整体处理能力
   - 调整代理负载, 流量负载到备用/测试服务器, 避免破坏生产环境
   - 数据备份，以防万一系统遭受破坏时能够快速恢复。同时，考虑是否有快速恢复消费服务的预案。
   - 事件过后，修复已知漏洞，并优化防御策略
3. 新增分区, 让后来的消息先发送到新分区中处理, 不让消息继续堆到同一个积压的分区



## 消费消息变慢

1. 服务器系统资源用尽
   - 服务器扩容, 增加服务器资源，如CPU、内存、存储和网络带宽，以提高整体处理能力
   - 检查是否是其他业务程序导致服务器资源消耗, 间接导致kafka消费慢
2. 中间件资源用尽
   - 关闭一些不重要的业务,  全力支持主要业务的消息队列使用
   - 扩容中间件的负载均衡
3. 新增消费者, 用新的消费者去消费新分区里面的新数据, 旧消费者全力消费积压的数据
4. 检查是不是有某类消息反复消费，这种情况也会拖慢整个系统的消费速度
5. 检查一下日志是否有大量的消费错误, 检查错误情况
6. 是否出现某些资源并发读写长时间加锁等待




