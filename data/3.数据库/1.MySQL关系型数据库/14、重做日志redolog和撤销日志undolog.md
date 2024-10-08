### redolog和undolog

为了支持事务处理（ACID属性），其中最重要的两种日志是重做日志（Redo Log）和撤销日志（Undo Log）。

这两种日志各自承担着不同的职责，下面详细介绍它们的作用和工作机制。

### 1. **重做日志（Redo Log）**

#### 作用

重做日志的主要作用是在**系统崩溃后能够恢复尚未写入磁盘的数据**。

通过重做日志，InnoDB可以重新执行（redo）那些**已经提交但尚未写入数据文件**的更改，从而保证数据的**持久性**。

#### 工作机制

1. **缓冲池（Buffer Pool）**：InnoDB使用缓冲池来**缓存数据页和索引页**。这意味着数据修改后**首先写入内存中的缓冲池**
   ，而不是直接写入磁盘。
2. **重做日志记录**：每当事务对数据进行修改时，InnoDB会将修改记录**写入重做日志**中。这些记录包含了如何重新执行（redo）修改的信息。
3. **检查点（Checkpoint）**：InnoDB会**周期性地**将缓冲池中的脏页（dirty pages）**写入磁盘**
   ，并记录一个检查点。检查点记录了当前的重做日志位置，用于后续的恢复。
4. **崩溃恢复**：如果系统崩溃，InnoDB可以从最新的检查点开始，重做日志记录中所有尚未写入磁盘的更改，从而恢复数据的一致性和持久性。

#### 文件

重做日志文件通常分为多个文件组，每个文件组包含一个或多个文件。文件名通常为 `ib_logfile0`、`ib_logfile1` 等。

#### 参数

- `innodb_log_file_size`：控制每个日志文件的大小。
- `innodb_log_files_in_group`：控制日志文件组中的文件数量。
- `innodb_log_buffer_size`：控制重做日志缓冲区的大小。

### 2. **撤销日志（Undo Log）**

#### 作用

撤销日志的主要作用是在事务回滚时撤销已经执行的操作。撤销日志记录了事务执行前的数据状态，以便在**需要时回滚事务**。

相当于一个临时的操作步骤记录吗, 撤销日志（Undo Log）通常是在内存中维护的，而不是像重做日志（Redo Log）那样写入磁盘文件。

#### 工作机制

1. **事务开始**：当事务开始时，InnoDB会记录事务开始前的数据状态。
2. **事务执行**：事务执行期间，InnoDB会**记录每一步的更改信息**，包括如何撤销（undo）这些更改。
3. **事务回滚**：如果事务需要回滚，InnoDB可以**根据撤销日志恢复数据到事务开始前的状态**。
4. **多版本并发控制（MVCC）**：撤销日志还用于实现多版本并发控制（MVCC），允许事务看到一致的数据快照。

#### 文件

撤销日志通常存储在共享撤销段（shared undo segment）中，这些段可以存储在缓冲池内或外部磁盘上。

#### 参数

- `innodb_undo_directory`：控制撤销日志文件的存储目录。
- `innodb_undo_logs`：控制撤销段的数量。
- `innodb_undo_tablespaces`：控制撤销日志是否存储在独立的撤销表空间中。

### 总结

- **重做日志（Redo Log）**：用于保证数据的持久性，即在系统崩溃后能够恢复尚未写入磁盘的数据。通过记录修改前后的状态，重做日志使得InnoDB能够在崩溃后重新执行这些修改。
- **撤销日志（Undo Log）**：用于支持事务回滚和多版本并发控制。撤销日志记录了事务执行前的数据状态，使得事务可以在需要时回滚到初始状态。

通过这两种日志机制，InnoDB能够有效地支持事务处理，保证数据的一致性和持久性。合理配置这些日志相关的参数，可以进一步优化数据库的性能和可靠性。