# Kafka重复消费

**一、重复消费的原因**

　　消息重复消费的根本原因都在于：**已经消费了数据，但是offset没有成功提交。**

　　**其中很大一部分原因在于发生了再均衡。**

　　　　1）消费者宕机、重启等。导致消息已经消费但是没有提交offset。

　　　　2）消费者使用自动提交offset，但当还没有提交的时候，有新的消费者加入或者移除，发生了rebalance。再次消费的时候，消费者会根据提交的偏移量来，于是重复消费了数据。

　　　　3）消息处理耗时，或者消费者拉取的消息量太多，处理耗时，超过了max.poll.interval.ms的配置时间，导致认为当前消费者已经死掉，触发再均衡。

 

**二、Kafka知识回顾**

　　1、消费者常见参数

　　　　①：fetch.min.bytes，配置Consumer一次拉取请求中能从Kafka中拉取的最小数据量，默认为1B，如果小于这个参数配置的值，就需要进行等待，直到数据量满足这个参数的配置大小。调大可以提交吞吐量，但也会造成延迟

　　　　②：fetch.max.bytes，一次拉取数据的最大数据量，默认为52428800B，也就是50M，但是如果设置的值过小，甚至小于每条消息的值，实际上也是能消费成功的

　　　　③：fetch.wait.max.ms，若是不满足fetch.min.bytes时，等待消费端请求的最长等待时间，默认是500ms

　　　　④：max.poll.records，单次poll调用返回的最大消息记录数，如果处理逻辑很轻量，可以适当提高该值。一次从kafka中poll出来的数据条数,max.poll.records条数据需要在在session.timeout.ms这个时间内处理完，默认值为500

 

　　　　⑤：consumer.poll(100) ，100 毫秒是一个超时时间，一旦拿到足够多的数据（fetch.min.bytes 参数设置），consumer.poll(100)会立即返回 ConsumerRecords<String, String> records。如果没有拿到足够多的数据，会阻塞100ms，但不会超过100ms就会返回

　　　　⑥：session. timeout. ms ，默认值是10s，该参数是 Consumer Group 主动检测 (组内成员comsummer)崩溃的时间间隔。若超过这个时间内没有收到心跳报文，则认为此消费者已经下线。将触发再均衡操作

　　　　⑦：max.poll.interval.ms，两次拉取消息的间隔，默认5分钟；通过消费组管理消费者时，该配置指定拉取消息线程最长空闲时间，若超过这个时间间隔没有发起poll操作，则消费组认为该消费者已离开了消费组，将进行再均衡操作（将分区分配给组内其他消费者成员）

　　　　　　若超过这个时间则报如下异常：

```
org.apache.kafka.clients.consumer.CommitFailedException: Commit cannot be completed since the group has already rebalanced and assigned the partitions to another member. This means that the time between subsequent calls to poll() was longer than the configured max.poll.interval.ms, which typically implies that the poll loop is spending too much time message processing. You can address this either by increasing the session timeout or by reducing the maximum size of batches returned in poll() with max.poll.records.　
```

　　　　　　即：无法完成提交，因为组已经重新平衡并将分区分配给另一个成员。这意味着对poll()的后续调用之间的时间比配置的max.poll.interval.ms长，这通常意味着poll循环花费了太多的时间来处理消息。

　　　　　　　　可以通过增加max.poll.interval.ms来解决这个问题，也可以通过减少在poll()中使用max.poll.records返回的批的最大大小来解决这个问题

 

　　2、poll机制

　　　　①：每次poll的消息处理完成之后再进行下一次poll，是同步操作

　　　　②：每次poll之前检查是否可以进行位移提交，如果可以，那么就会提交上一次轮询的位移

　　　　③：每次poll时，consumer都将尝试使用上次消费的offset作为起始offset，然后依次拉取消息

　　　　④：poll(long timeout)，timeout指等待轮询缓冲区的数据所花费的时间，单位是毫秒

 

　　3、再均衡 rebalance

　　　　将分区的所有权从一个消费者转移到其他消费者的行为称为再均衡（重平衡，rebalance）。

　　　　消费者通过向组织协调者（kafka broker）发送心跳来维护自己是消费者组的一员并确认其拥有的分区。对于不同不的消费群体来说，其组织协调者可以是不同的。只要消费者定期发送心跳，就会认为 消费者是存活的并处理其分区中的消息。当消费者检索记录或者提交它所消费的记录时就会发送心跳。

　　　　如果过了一段时间Kafka停止发送心跳了，会话（session）就会过期，组织协调者就会认为这个consumer已经死亡，就会触发一次重平衡。如果消费者宕机并且停止发送消息，组织协调者会等待几秒钟，确认它死亡了才会触发重平衡。在这段时间里，死亡的消费者将不处理任何消息。在清理消费者时，消费者将通知协调者它要离开群组，组织协调者会触发一次重平衡，尽量降低处理停顿。

　　　　重平衡是一把双刃剑，它为消费者群组带来高可用性和伸缩性的同时，还有有一些明显的缺点(bug)，而这些 bug 到现在社区还无法修改。也就是说，在重平衡期间，消费者组中的消费者实例都会停止消费（Stop The World），等待重平衡的完成。而且重平衡这个过程很慢。

　　　　

　　　触发再均衡的三种情况：

　　　　①：有新的消费者加入消费组、或已有消费者主动离开组

　　　　②：消费者超过session时间未发送心跳（已有 consumer 崩溃了）

　　　　③：一次poll()之后的消息处理时间超过了max.poll.interval.ms的配置时间，因为一次poll()处理完才会触发下次poll() （已有 consumer 崩溃了）

　　　　④：订阅主题数发生变更

　　　　⑤：订阅主题的分区数发生变更

 

**三、重复消费的解决方案**

　　由于网络问题，重复消费不可避免，因此，消费者需要实现消费幂等。

　　方案：

　　　　①：消息表

　　　　②：数据库唯一索引

　　　　③：缓存消费过的消息id

 

**四、项目kafka重复消费的排查**

　重复消费问题1：

　　每次拉取的消息记录数max.poll.records为100，poll最大拉取间隔max.poll.interval.ms为 300s，消息处理过于耗时导致时长大于了这个值，导致再均衡发生重复消费

　　解决办法：

　　　　①：减少每次拉取的消息记录数和增大poll之间的时间间隔

　　　　②：拉取到消息之后异步处理（保证成功消费）