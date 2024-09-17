### 启动geth客户端会在屏幕上输出大量文字，应该如何减少输出信息

可以将 **--verbosity 日志详细度**设置为较低的数字（默认值为3=info）

启动 Geth 客户端时，默认情况下它会输出很多日志信息，这有助于调试和监控节点的状态。

然而，在某些情况下，你可能希望减少屏幕上的输出信息，使控制台更加简洁。可以通过调整日志级别和配置日志输出来实现这一点。

### 设置日志级别

Geth 使用了一个基于级别的日志系统，允许你控制不同组件的日志输出级别。

```
--verbosity value                   (default: 3)                       (%GETH_VERBOSITY%)
	日志详细度：0=silent, 1=error, 2=warn, 3=info, 4=debug, 5=detail
```

#### 示例命令

如果你希望仅显示错误信息：

```sh
geth --datadir /path/to/data/folder --verbosity 1  console
```

