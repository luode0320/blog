### 概述

为了满足特定的安全需求，本文档描述了如何在Hyperledger Fabric区块链框架中实现基于国家密码局标准（国密）的TLS加密。

这将确保通信双方能够使用符合中国密码标准的安全协议进行数据交换。

### 国密算法支持

国密标准通常包含一系列算法，如SM2公钥私钥加密算法、SM3哈希算法、SM4对称密钥等。

在TLS握手过程中，需要确保使用这些算法来生成和验证证书。

### 握手流程

TLS握手是客户端和服务端之间建立安全连接的过程。在这个过程中，双方会协商使用哪些加密算法，并交换必要的信息来创建一个安全的会话密钥。

以下是简化的国密TLS握手步骤：

1. **客户端Hello**：客户端发送一个包含其支持的TLS版本、加密套件、压缩方法等信息的消息。
2. **服务器Hello**：服务器回应一个包含服务器支持选择的TLS版本、加密套件等信息的消息。
3. **证书交换**：服务器发送其证书给客户端，以证明自己的身份。
4. **服务器Hello Done**：服务器通知客户端已完成其初始消息的发送。
5. **客户端密钥交换**：客户端计算一个预主密钥（Pre-Master Secret），并使用服务器证书中的公钥对其进行加密，然后发送给服务器。
6. **变更密码规范**：客户端和服务器分别通知对方它们将开始使用新的加密密钥。
7. **完成握手**：客户端和服务器分别发送一个包含“Finished”消息的加密数据包，表明握手已完成。

### 源码

### 配置选项

在进行国密TLS配置时，以下是一些重要的配置选项及其用途：

```go
case gmtls.Config:
    conf.GMSupport = &gmtls.GMSupport{}  // 使用GMSSL（国密SSL）的支持
    conf.SessionTicketsDisabled = true   // 禁用会话票据（Session Tickets）
    conf.PreferServerCipherSuites = true // 优先使用服务器端的密码套件
    // 包含两个GMSSL密码套件的切片
    conf.CipherSuites = []uint16{gmtls.GMTLS_SM2_WITH_SM4_SM3, gmtls.GMTLS_ECDHE_SM2_WITH_SM4_SM3}
    conf.NextProtos = alpnProtoStr       // 应用层协议（ALPN）
    conf.MinVersion = gmtls.VersionGMSSL // 最低支持的SSL版本
    return &TLSConfig{
        gmconfig: &conf,
    }
```

- `conf.GMSupport`：启用对国密的支持，告诉TLS库我们希望使用国密算法来进行加密通信。
- `conf.SessionTicketsDisabled`：设置为`true`表示禁用TLS会话票（Session Tickets）。这是因为会话票通常包含非对称加密的信息，而这里我们专注于使用国密算法。
- `conf.PreferServerCipherSuites`：设置为`true`表示服务器在握手期间会优先发送它支持的密码套件列表，而不是由客户端决定。
- `conf.CipherSuites`
  ：定义了一个数组，其中包含了支持的密码套件。这里指定了两个基于SM2算法的密码套件，分别是基于静态密钥的`GMTLS_SM2_WITH_SM4_SM3`
  和基于ECDHE（椭圆曲线Diffie-Hellman密钥交换）的`GMTLS_ECDHE_SM2_WITH_SM4_SM3`。
- `conf.NextProtos`：定义了应用层协议名称（ALPN），用于指示支持的应用层协议列表。
- `conf.MinVersion`：设置最低支持的TLS版本为国密版本（`VersionGMSSL`）。

### 应用层客户端握手入口

```go
// ClientHandshake 用于为客户端进行TLS握手。
// 方法接收者：DynamicClientCredentials
// 输入参数：
//   - ctx：上下文对象。
//   - authority：服务器的授权信息。
//   - rawConn：原始的网络连接。
//
// 返回值：
//   - net.Conn：握手完成后的网络连接。
//   - credentials.AuthInfo：身份验证信息。
//   - error：握手过程中的错误，如果没有错误则为 nil。
func (dtc *DynamicClientCredentials) ClientHandshake(ctx context.Context, authority string, rawConn net.Conn) (net.Conn, credentials.AuthInfo, error) {
    ...
    // 获取最新的配置
    config := dtc.latestConfig().(*gmtls.Config)

    // 创建 GMTLS TransportCredentials
    creds := gmcredentials.NewTLS(config)
    start := time.Now()
    l.Infof("客户端TLS握手")
    // 进行客户端TLS握手
    conn, auth, err := creds.ClientHandshake(ctx, authority, rawConn)
    if err != nil {
        l.Errorf("客户端TLS握手在 %s 后失败，出现错误: %s", time.Since(start), err)
    }
	...
}
```

客户端握手实现:

`gmtls/gmcredentials/credentials.go`

```go
func (c *tlsCreds) ClientHandshake(ctx context.Context, addr string, rawConn net.Conn) (_ net.Conn, _ credentials.AuthInfo, err error) {
	// 使用本地配置副本，避免在使用多个端点时覆盖ServerName
	cfg := cloneTLSConfig(c.config)
	if cfg.ServerName == "" {
		// 如果没有指定ServerName，则从地址中解析出来（默认使用冒号前的部分作为ServerName）
		colonPos := strings.LastIndex(addr, ":")
		if colonPos == -1 {
			colonPos = len(addr)
		}
		cfg.ServerName = addr[:colonPos]
	}
	// 创建一个新的国密TLS客户端连接
	conn := gmtls.Client(rawConn, cfg)
	// 创建一个错误通道，用于异步处理Handshake的结果
	errChannel := make(chan error, 1)
	
	// 启动一个新的goroutine来执行Handshake握手
	go func() {
		errChannel <- conn.Handshake()
	}()
	
	// 使用select语句等待Handshake完成或上下文取消
	select {
	case err := <-errChannel:
		// 如果Handshake失败，返回错误
		if err != nil {
			return nil, nil, err
		}
	case <-ctx.Done():
		// 如果上下文被取消，返回上下文的错误
		return nil, nil, ctx.Err()
	}

	// Handshake成功后，返回TLS连接和认证信息
	return conn, TLSInfo{conn.ConnectionState()}, nil
}
```

`conn.Handshake()`: 启动一个新的goroutine来执行Handshake握手

**这是一个通用的握手函数, 客户端和服务端都会走这个函数自行握手, 我们下面就会详细从这里入手。**

### 应用层服务器握手入口

```go
// ServerHandshake 用于为服务器进行身份验证握手。
// 方法接收者：serverCreds
// 输入参数：
//   - rawConn：原始的网络连接。
//
// 返回值：
//   - net.Conn：握手完成后的网络连接。
//   - credentials.AuthInfo：身份验证信息。
//   - error：握手过程中的错误，如果没有错误则为 nil。
func (sc *serverCreds) ServerHandshake(rawConn net.Conn) (net.Conn, credentials.AuthInfo, error) {
    ...
    // 如果服务器配置类型是 gmtls.Config，则使用 gmtls.Server 进行握手
    server := gmtls.Server(rawConn, &conf)
    l := sc.logger.With("远程地址", server.RemoteAddr().String())

    start := time.Now()
    l.Infof("服务器TLS握手")
    if err := server.Handshake(); err != nil {
        l.Errorf("服务器TLS握手失败 %s 有错误 %s", time.Since(start), err)
        return nil, nil, err
    }
    ...
}
```

**服务端握手实现就是底层通用握手入口!**

### 底层通用握手入口

`gmtls/conn.go`

```go
// Handshake 运行客户端或服务器的握手协议（如果尚未运行的话）。
// 大多数使用此包的情况无需显式调用 Handshake：首次 Read 或 Write 会自动调用它。
func (c *Conn) Handshake() error {
	// 加锁以确保在执行握手期间不会发生并发修改
	c.handshakeMutex.Lock()
	defer c.handshakeMutex.Unlock()

	// 如果之前已经记录了错误，则直接返回该错误
	if err := c.handshakeErr; err != nil {
		return err
	}
	// 如果握手已经完成，则直接返回无错误
	if c.handshakeComplete() {
		return nil
	}

	// 加锁以保护内部状态不受并发访问影响
	c.in.Lock()
	defer c.in.Unlock()

	// 根据是否为客户端来决定调用哪个握手函数
	if c.isClient {
		// 对于客户端，调用客户端握手函数
		fmt.Println("调用客户端握手函数")
		c.handshakeErr = c.clientHandshake()
	} else {
		// 对于服务器，检查是否启用了国密支持
		if c.config.GMSupport == nil {
			fmt.Println("调用普通服务器握手函数")
			// 如果没有国密支持，调用普通服务器握手函数
			c.handshakeErr = c.serverHandshake()
		} else {
			fmt.Println("调用国密服务器握手函数")
			// 如果启用了国密支持，调用国密服务器握手函数
			c.handshakeErr = c.serverHandshakeGM()
		}
	}

	// 如果握手成功，则增加握手次数计数器
	if c.handshakeErr == nil {
		c.handshakes++
	} else {
		// 如果握手过程中发生错误，则尝试清除缓冲区中可能遗留的警报信息
		c.flush()
		fmt.Println("handshake error :", c.handshakeErr)
	}

	// 如果握手成功但握手完成标志未设置，则抛出异常
	if c.handshakeErr == nil && !c.handshakeComplete() {
		panic("handshake should have had a result.")
	}

	// 返回握手过程中遇到的任何错误
	return c.handshakeErr
}
```

- `c.handshakeErr = c.clientHandshake()`: 调用客户端握手函数
- `c.handshakeErr = c.serverHandshakeGM()`: 调用国密服务器握手函数

### 1.客户端准备开始握手

`c.handshakeErr = c.clientHandshake()`: 调用客户端握手函数

`gmtls/handshake_client.go`

```go
func (c *Conn) clientHandshake() error {
	// 如果没有配置就用默认配置
	if c.config == nil {
		c.config = defaultConfig()
	}

	// 这可能是重新协商握手，在这种情况下，某些字段需要重置。
	c.didResume = false

	var hello *clientHelloMsg
	var err error
	if c.config.GMSupport != nil {
		// 如果启用了国密支持，则使用国密版本
		c.vers = VersionGMSSL
		// 创建一个国密客户端Hello消息。
		hello, err = makeClientHelloGM(c.config)
	} else {
		// 如果没有启用国密支持，则使用普通的ClientHello消息创建函数
		hello, err = makeClientHello(c.config)
	}
	if err != nil {
		return err
	}

	if c.handshakes > 0 {
		// 如果已经是第二次握手（即重新协商），则设置secureRenegotiation标志
		hello.secureRenegotiation = c.clientFinished[:]
	}

	var session *ClientSessionState
	var cacheKey string
	sessionCache := c.config.ClientSessionCache
	// 如果禁用了会话票，则不使用缓存
	if c.config.SessionTicketsDisabled {
		sessionCache = nil
	}

	// 如果使用会话票，则设置支持会话票的标志
	if sessionCache != nil {
		hello.ticketSupported = true
	}

	// 如果正在进行第二次重新协商，则不允许会话恢复，因为重新协商主要用于允许客户端发送证书。
	if sessionCache != nil && c.handshakes == 0 {
		// 尝试恢复之前协商的TLS会话（如果可用）
		cacheKey = clientSessionCacheKey(c.conn.RemoteAddr(), c.config)
		candidateSession, ok := sessionCache.Get(cacheKey)
		if ok {
			// 检查之前会话使用的密码套件/版本是否仍然有效
			cipherSuiteOk := false
			for _, id := range hello.cipherSuites {
				if id == candidateSession.cipherSuite {
					cipherSuiteOk = true
					break
				}
			}

			versOk := candidateSession.vers >= c.config.minVersion() &&
				candidateSession.vers <= c.config.maxVersion()
			if versOk && cipherSuiteOk {
				session = candidateSession
			}
		}
	}

	if session != nil {
		// 设置会话票
		hello.sessionTicket = session.sessionTicket
		// 使用随机会话ID来检测服务器是否接受会话票并恢复会话（参见RFC 5077）
		hello.sessionId = make([]byte, 16)
		if _, err := io.ReadFull(c.config.rand(), hello.sessionId); err != nil {
			return errors.New("tls: short read from Rand: " + err.Error())
		}
	}

	if c.config.GMSupport != nil {
		// 初始化国密客户端握手状态
		hs := &clientHandshakeStateGM{
			c:       c,
			hello:   hello,
			session: session,
		}
		if err = hs.handshake(); err != nil {
			return err
		}
		// 如果握手成功并且hs.session与已缓存的不同，则缓存新的会话
		if sessionCache != nil && hs.session != nil && session != hs.session {
			sessionCache.Put(cacheKey, hs.session)
		}
	} else {
		// 初始化普通的客户端握手状态
		hs := &clientHandshakeState{
			c:       c,
			hello:   hello,
			session: session,
		}
		if err = hs.handshake(); err != nil {
			return err
		}
		// 如果握手成功并且hs.session与已缓存的不同，则缓存新的会话
		if sessionCache != nil && hs.session != nil && session != hs.session {
			sessionCache.Put(cacheKey, hs.session)
		}
	}

	return nil
}
```

这里的重点:

1. makeClientHelloGM 创建一个国密客户端Hello消息。
2. hs.handshake 开始握手

### 1.1创建一个国密客户端Hello消息

`gmtls/gm_handshake_client_double.go`

```go
// makeClientHelloGM 创建一个国密客户端Hello消息。
func makeClientHelloGM(config *Config) (*clientHelloMsg, error) {
	if len(config.ServerName) == 0 && !config.InsecureSkipVerify {
		// 如果没有指定ServerName并且没有禁用验证，则返回错误
		return nil, errors.New("tls: either ServerName or InsecureSkipVerify must be specified in the tls.Config")
	}

	// 创建一个客户端Hello消息
	hello := &clientHelloMsg{
		vers:               config.GMSupport.GetVersion(), // 设置TLS版本为国密版本
		compressionMethods: []uint8{compressionNone},// 设置压缩方法为无压缩
		random:             make([]byte, 32), // 创建一个长度为32字节的随机数
	}
	// 获取可能的密码套件列表
	possibleCipherSuites := getCipherSuites(config)
	// 初始化密码套件列表
	hello.cipherSuites = make([]uint16, 0, len(possibleCipherSuites))

	// 遍历可能的密码套件列表
NextCipherSuite:
	for _, suiteId := range possibleCipherSuites {
		for _, suite := range config.GMSupport.cipherSuites() {
			// 如果当前密码套件ID不匹配，则继续下一个
			if suite.id != suiteId {
				continue
			}
			// 添加匹配的密码套件ID
			hello.cipherSuites = append(hello.cipherSuites, suiteId)
			continue NextCipherSuite
		}
	}

	// 从随机源读取32字节的随机数据填充random字段
    // 随机数确保每次握手都是唯一的, 随机数用于生成后续的加密密钥
	_, err := io.ReadFull(config.rand(), hello.random)
	// 如果读取随机数失败，则返回错误
	if err != nil {
		return nil, errors.New("tls: short read from Rand: " + err.Error())
	}

	// 返回构建好的客户端Hello消息
	return hello, nil
}
```

### 1.2开始握手

这个握手的方法步骤比较多, 我们一步一步说明, 先看入口方法:

`gmtls/gm_handshake_client_double.go`

```go
// handshake 执行握手过程，既可以是完整的握手也可以恢复旧的会话。
// 需要设置 hs.c, hs.hello 和可选的 hs.session。
func (hs *clientHandshakeStateGM) handshake() error {
	c := hs.c

	// 1. 客户端Hello: 客户端发送一个包含其支持的TLS版本、加密套件、压缩方法等信息的消息

	// 发送 ClientHello 消息
	if _, err := c.writeRecord(recordTypeHandshake, hs.hello.marshal()); err != nil {
		return err
	}

	// 2. 服务器Hello：服务器回应一个包含服务器支持选择的TLS版本、加密套件等信息的消息。

	// 接收并解析服务器的响应消息
	msg, err := c.readHandshake()
	if err != nil {
		return err
	}

	var ok bool
	// 如果不是 ServerHello 消息，则发送错误警报
	if hs.serverHello, ok = msg.(*serverHelloMsg); !ok {
		c.sendAlert(alertUnexpectedMessage)
		return unexpectedMessageError(hs.serverHello, msg)
	}

	// 检查服务器选择的协议版本是否为国密版本
	if hs.serverHello.vers != VersionGMSSL {
		hs.c.sendAlert(alertProtocolVersion)
		return fmt.Errorf("tls: server selected unsupported protocol version %x, while expecting %x", hs.serverHello.vers, VersionGMSSL)
	}

	// 选择密码套件
	if err = hs.pickCipherSuite(); err != nil {
		return err
	}

	// 处理 ServerHello 消息，并确定是否为会话恢复
	isResume, err := hs.processServerHello()
	if err != nil {
		return err
	}

	// 初始化完成散列计算, 这是一个空对象
	hs.finishedHash = newFinishedHashGM(hs.suite)

	// 如果是会话恢复，或者没有配置证书，则不需要签名握手消息
	if isResume || (len(c.config.Certificates) == 0 && c.config.GetClientCertificate == nil) {
		hs.finishedHash.discardHandshakeBuffer()
	}

	// 计算“Finished”消息中的哈希，从而验证握手过程的完整性
	// 通过比较双方计算得到的哈希，可以验证握手过程是否被篡改或受到中间人攻击。
	hs.finishedHash.Write(hs.hello.marshal()) //  将客户端Hello消息写入散列对象。
	hs.finishedHash.Write(hs.serverHello.marshal()) // 将服务器Hello消息写入散列对象。

	// 开始缓冲握手消息
	c.buffering = true
	if isResume {
		// 如果是会话恢复
		if err := hs.establishKeys(); err != nil {
			return err
		}
		if err := hs.readSessionTicket(); err != nil {
			return err
		}
		if err := hs.readFinished(c.serverFinished[:]); err != nil {
			return err
		}
		c.clientFinishedIsFirst = false
		if err := hs.sendFinished(c.clientFinished[:]); err != nil {
			return err
		}
		if _, err := c.flush(); err != nil {
			return err
		}
	} else {
		// 客户端执行完整的握手
		// 3. 证书交换：服务器发送其证书给客户端，以证明自己的身份。
		// 4. 服务器Hello Done：服务器通知客户端已完成其初始消息的发送。
		// 5. 客户端密钥交换：客户端计算一个预主密钥（Pre-Master Secret），并使用服务器证书中的公钥对其进行加密，然后发送给服务器。
		// 6. 变更密码规范：客户端和服务器分别通知对方它们将开始使用新的加密密钥。
		if err := hs.doFullHandshake(); err != nil {
			return err
		}
		
		// 建立密钥材料。
		if err := hs.establishKeys(); err != nil {
			return err
		}

		// 7. 完成握手：客户端和服务器分别发送一个包含“Finished”消息的加密数据包，表明握手已完成。

		// 发送客户端完成消息。
		if err := hs.sendFinished(c.clientFinished[:]); err != nil {
			return err
		}
		// 刷新网络缓冲区
		if _, err := c.flush(); err != nil {
			return err
		}
		c.clientFinishedIsFirst = true
		// 读取会话票，以便后续会话恢复
		if err := hs.readSessionTicket(); err != nil {
			return err
		}
		// 读取服务器完成消息。
		if err := hs.readFinished(c.serverFinished[:]); err != nil {
			return err
		}
	}

	// 根据握手过程中的随机数生成加密密钥材料。
	c.ekm = ekmFromMasterSecret(c.vers, hs.suite, hs.masterSecret, hs.hello.random, hs.serverHello.random)
	// 标记握手是否为会话恢复。
	c.didResume = isResume
	// 更新握手状态。
	atomic.StoreUint32(&c.handshakeStatus, 1)

	return nil
}
```

这里我们要关注的重点:

1. 客户端发送一个包含其支持的TLS版本、加密套件、压缩方法等信息的消息
2. 服务器回应一个包含服务器支持选择的TLS版本、加密套件等信息的消息。

- 等下我们会按照步骤依次讲到服务端的代码

3. 完整的握手, 包含验证服务器证书, 使用一个随机数构建的预密钥(对称密钥)通过服务器公钥加密，然后发送给服务器
4. 完成握手

### 1.2.1 发送客户端Hello消息

```go
	// 发送 ClientHello 消息
	if _, err := c.writeRecord(recordTypeHandshake, hs.hello.marshal()); err != nil {
		return err
	}
```

这里没什么多说的, 我们不用研究是怎么发送的什么的。

### 1.2.2 服务端接受客户端Hello消息

从上面说的底层通用握手入口得知, 服务端的代码位置

```go
// Handshake 运行客户端或服务器的握手协议（如果尚未运行的话）。
// 大多数使用此包的情况无需显式调用 Handshake：首次 Read 或 Write 会自动调用它。
func (c *Conn) Handshake() error {
    ...
	// 根据是否为客户端来决定调用哪个握手函数
	if c.isClient {
		// 对于客户端，调用客户端握手函数
        ...
	} else {
		// 对于服务器，检查是否启用了国密支持
		if c.config.GMSupport == nil {
            ...
		} else {
			fmt.Println("调用国密服务器握手函数")
			// 如果启用了国密支持，调用国密服务器握手函数
			c.handshakeErr = c.serverHandshakeGM()
		}
	}
    ...
}
```

### 2. 服务器开始握手

`gmtls/gm_handshake_server_double.go`

```go
// serverHandshakeGM 作为服务器执行TLS握手。
func (c *Conn) serverHandshakeGM() error {
	// 如果这是第一次服务器握手，我们生成一个随机密钥来加密票据。
	c.config.serverInitOnce.Do(func() { c.config.serverInit(nil) })

	// 初始化服务器握手状态
	hs := serverHandshakeStateGM{
		c: c,
	}

	// 1. 客户端Hello: 客户端发送一个包含其支持的TLS版本、加密套件、压缩方法等信息的消息
	// 2. 服务器Hello：服务器回应一个包含服务器支持选择的TLS版本、加密套件、服务器证书等信息的消息。

	// 服务器获取客户端的hello, 并构建回应客户端的数据, 此时并没发送, 第三步才发送
	isResume, err := hs.readClientHello()
	if err != nil {
		return err
	}

	// 关于TLS握手的概述，请参阅 https://tools.ietf.org/html/rfc5246#section-7.3
	c.buffering = true
	if isResume {
		// 恢复会话
		if err := hs.doResumeHandshake(); err != nil {
			return err
		}
		if err := hs.establishKeys(); err != nil {
			return err
		}
		if hs.hello.ticketSupported {
			if err := hs.sendSessionTicket(); err != nil {
				return err
			}
		}
		if err := hs.sendFinished(c.serverFinished[:]); err != nil {
			return err
		}
		if _, err := c.flush(); err != nil {
			return err
		}
		c.clientFinishedIsFirst = false
		if err := hs.readFinished(nil); err != nil {
			return err
		}
		c.didResume = true
	} else {
		// 服务端执行完整的握手。
		// 2. 服务器Hello：服务器回应一个包含服务器支持选择的TLS版本、加密套件、服务器证书等信息的消息。
		// 3. 证书交换：服务器发送其证书给客户端，以证明自己的身份。
		// 4. 服务器Hello Done：服务器通知客户端已完成其初始消息的发送。
		// 5. 客户端密钥交换：客户端计算一个预主密钥（Pre-Master Secret），并使用服务器证书中的公钥对其进行加密，然后发送给服务器。
		// 6. 变更密码规范：客户端和服务器分别通知对方它们将开始使用新的加密密钥。
		if err := hs.doFullHandshake(); err != nil {
			return err
		}
		if err := hs.establishKeys(); err != nil {
			return err
		}

		// 7. 完成握手：客户端和服务器分别发送一个包含“Finished”消息的加密数据包，表明握手已完成。

		if err := hs.readFinished(c.clientFinished[:]); err != nil {
			return err
		}
		c.clientFinishedIsFirst = true
		c.buffering = true
		// 发送会话票据。
		if err := hs.sendSessionTicket(); err != nil {
			return err
		}
		// 发送服务器完成消息。
		if err := hs.sendFinished(nil); err != nil {
			return err
		}
		if _, err := c.flush(); err != nil {
			return err
		}
	}

	// 根据握手过程中的随机数生成加密密钥材料。
	c.ekm = ekmFromMasterSecret(c.vers, hs.suite, hs.masterSecret, hs.clientHello.random, hs.hello.random)
	// 更新握手状态。
	atomic.StoreUint32(&c.handshakeStatus, 1)

	return nil
}
```

这里我们要关注的重点:

1. 服务器收到了客户端的hello, 然后开始构建回应的数据, TLS版本、加密套件、服务器证书等
2. 服务器回应一个包含服务器支持选择的TLS版本、加密套件、服务端证书等信息的消息。
3. 完整的握手, 包含验证服务器证书, 使用一个随机数构建的预密钥(对称密钥)通过服务器公钥加密，然后发送给服务器
4. 完成握手

### 2.1 服务器收到了客户端的hello

服务器收到了客户端的hello, 然后开始构建回应的数据, TLS版本、加密套件、服务器证书等

```go
	// 1. 客户端Hello: 客户端发送一个包含其支持的TLS版本、加密套件、压缩方法等信息的消息
	// 2. 服务器Hello：服务器回应一个包含服务器支持选择的TLS版本、加密套件、服务器证书等信息的消息。

	// 服务器获取客户端的hello, 并构建回应客户端的数据, 此时并没发送, 第三步才发送
	isResume, err := hs.readClientHello()
	if err != nil {
		return err
	}
```

### 2.2 服务端接受客户端发送的ClientHello消息

这个方法也很长, 我们只关心主要的步骤:

```go
// readClientHello 读取客户端发送的ClientHello消息
func (hs *serverHandshakeStateGM) readClientHello() (isResume bool, err error) {
	c := hs.c

	// 1. 读取客户端hello握手消息
	msg, err := c.readHandshake()
	if err != nil {
		return false, err
	}
	var ok bool

	// 2. 解析ClientHello消息
	hs.clientHello, ok = msg.(*clientHelloMsg)
	// 如果不是ClientHello消息，则发送错误警报
	if !ok {
		c.sendAlert(alertUnexpectedMessage)
		return false, unexpectedMessageError(hs.clientHello, msg)
	}
	...
	// 3. 确定客户端和服务器支持的tls共同版本
	c.vers, ok = c.config.mutualVersion(hs.clientHello.vers)
	if !ok {
		c.sendAlert(alertProtocolVersion)
		return false, fmt.Errorf("tls: client offered an unsupported, maximum protocol version of %x", hs.clientHello.vers)
	}
	c.haveVers = true

	// 4. 创建ServerHello消息
	hs.hello = new(serverHelloMsg)
	...
	// 设置ServerHello版本和随机数
	// 随机数确保每次握手都是唯一的, 随机数用于生成后续的加密密钥
	hs.hello.vers = c.vers
	hs.hello.random = make([]byte, 32)
	_, err = io.ReadFull(c.config.rand(), hs.hello.random)
	if err != nil {
		c.sendAlert(alertInternalError)
		return false, err
	}
	...
	// 设置ServerHello的其他字段
	hs.hello.secureRenegotiationSupported = hs.clientHello.secureRenegotiationSupported
	hs.hello.compressionMethod = compressionNone
	if len(hs.clientHello.serverName) > 0 {
		c.serverName = hs.clientHello.serverName
	}
	...

	// 5. 测试代码：获取服务端证书信息
	// 服务器接收到客户端的 ClientHello 消息之后，根据客户端提供的信息（例如服务器名称）来选择适当的证书和密钥，以便进行身份验证
	// 如果服务器托管多个虚拟主机（即多个域名），则根据客户端提供的 SNI 信息来选择正确的证书。
	// getCertificate 回调函数可以根据客户端提供的信息（如 SNI）来选择最合适的服务端证书返回给客户端。
	c.config.getCertificate(hs.clientHelloInfo())
	hs.cert = c.config.Certificates

	// 检查证书数量是否满足要求
	if len(hs.cert) < 2 {
		c.sendAlert(alertInternalError)
		return false, fmt.Errorf("tls: amount of server certificates must be greater than 2, which will sign and encipher respectively")
	}

	...
	// 6. 选择合适的密码套件
	var preferenceList, supportedList []uint16
	if c.config.PreferServerCipherSuites {
		preferenceList = getCipherSuites(c.config)
		supportedList = hs.clientHello.cipherSuites
	} else {
		preferenceList = hs.clientHello.cipherSuites
		supportedList = getCipherSuites(c.config)
	}

	for _, id := range preferenceList {
		if hs.setCipherSuite(id, supportedList, c.vers) {
			break
		}
	}

	if hs.suite == nil {
		c.sendAlert(alertHandshakeFailure)
		return false, errors.New("tls: no cipher suite supported by both client and server")
	}
	...

	return false, nil
}
```

1. 读取客户端hello握手消息

2. 解析ClientHello消息

3. 确定客户端和服务器支持的tls共同版本

4. 创建ServerHello消息

5. 测试代码：获取证书信息

6. 选择合适的密码套件

这里面比较重要的就是 **获取服务端证书信息** 了

### 2.3 获取服务端证书信息

```go
	// 5. 测试代码：获取服务端证书信息
	// 服务器接收到客户端的 ClientHello 消息之后，根据客户端提供的信息（例如服务器名称）来选择适当的证书和密钥，以便进行身份验证
	// 如果服务器托管多个虚拟主机（即多个域名），则根据客户端提供的 SNI 信息来选择正确的证书。
	// getCertificate 回调函数可以根据客户端提供的信息（如 SNI）来选择最合适的服务端证书返回给客户端。
	c.config.getCertificate(hs.clientHelloInfo())
```

根据客户端提供的信息（如 SNI）来选择最合适的服务端证书返回给客户端

```go
// getCertificate 根据给定的 ClientHelloInfo 返回最适合的证书，
// 默认情况下返回 c.Certificates 中的第一个元素。
func (c *Config) getCertificate(clientHello *ClientHelloInfo) (*Certificate, error) {
	// 如果 GetCertificate 回调函数存在，并且没有配置证书或客户端提供了服务器名称，
	if c.GetCertificate != nil &&
		(len(c.Certificates) == 0 || len(clientHello.ServerName) > 0) {
		// 调用 GetCertificate 回调函数来获取证书
		cert, err := c.GetCertificate(clientHello)
		if cert != nil || err != nil {
			return cert, err
		}
	}

	// 如果没有配置任何证书，则返回错误
	if len(c.Certificates) == 0 {
		return nil, errors.New("tls: no certificates configured")
	}

	// 如果只有一个证书，或者没有根据名称映射到证书的逻辑，
	if len(c.Certificates) == 1 || c.NameToCertificate == nil {
		// There's only one choice, so no point doing any work.
		return &c.Certificates[0], nil
	}

	// 处理服务器名称
	name := strings.ToLower(clientHello.ServerName)
	for len(name) > 0 && name[len(name)-1] == '.' {
		name = name[:len(name)-1]
	}

	// 如果根据服务器名称找到了对应的证书，则返回该证书
	if cert, ok := c.NameToCertificate[name]; ok {
		return cert, nil
	}

	// 尝试将名称中的标签替换为通配符，直到找到匹配项
	labels := strings.Split(name, ".")
	for i := range labels {
		labels[i] = "*"// 替换为通配符
		candidate := strings.Join(labels, ".")// 构建候选名称
		if cert, ok := c.NameToCertificate[candidate]; ok {
			return cert, nil
		}
	}

	// 如果没有任何匹配项，则返回第一个证书
	return &c.Certificates[0], nil
}
```

如果你已经在通信之前配置好了, 就可以直接用, 如果没有你可以写一个回调来动态获取。

### 3. 服务器发送其证书给客户端证明自己的身份

当然这里是好几步都在一个方法里面

```go
		// 服务端执行完整的握手。
		// 2. 服务器Hello：服务器回应一个包含服务器支持选择的TLS版本、加密套件、服务器证书等信息的消息。
		// 3. 证书交换：服务器发送其证书给客户端，以证明自己的身份。
		// 4. 服务器Hello Done：服务器通知客户端已完成其初始消息的发送。
		// 5. 客户端密钥交换：客户端计算一个预主密钥（Pre-Master Secret），并使用服务器证书中的公钥对其进行加密，然后发送给服务器。
		// 6. 变更密码规范：客户端和服务器分别通知对方它们将开始使用新的加密密钥。
		if err := hs.doFullHandshake(); err != nil {
			return err
		}
```

```go
// doFullHandshake 服务端执行完整的TLS握手过程。
// 2. 服务器Hello：服务器回应一个包含服务器支持选择的TLS版本、加密套件、服务器证书等信息的消息。
// 3. 证书交换：服务器发送其证书给客户端，以证明自己的身份。
// 4. 服务器Hello Done：服务器通知客户端已完成其初始消息的发送。
// 5. 客户端密钥交换：客户端计算一个预主密钥（Pre-Master Secret），并使用服务器证书中的公钥对其进行加密，然后发送给服务器。
// 6. 变更密码规范：客户端和服务器分别通知对方它们将开始使用新的加密密钥。
func (hs *serverHandshakeStateGM) doFullHandshake() error {
	c := hs.c

	// 如果客户端支持OCSP装订，并且证书中包含了OCSP响应，则启用OCSP装订。
	if hs.clientHello.ocspStapling && len(hs.cert[0].OCSPStaple) > 0 {
		hs.hello.ocspStapling = true
	}

	// 设置是否支持会话票（Session Tickets）。
	hs.hello.ticketSupported = hs.clientHello.ticketSupported && !c.config.SessionTicketsDisabled
	hs.hello.cipherSuite = hs.suite.id

	// 初始化用于计算握手过程摘要的哈希对象。
	hs.finishedHash = newFinishedHashGM(hs.suite)
	if c.config.ClientAuth == NoClientCert {
		// 如果不需要客户端证书，则不需要保留握手过程的完整记录。
		hs.finishedHash.discardHandshakeBuffer()
	}
	hs.finishedHash.Write(hs.clientHello.marshal())// 更新哈希对象，包含客户端发送的ClientHello消息。
	hs.finishedHash.Write(hs.hello.marshal())// 更新哈希对象，并发送ServerHello消息。

	// 2. 服务器Hello：服务器回应一个包含服务器支持选择的TLS版本、加密套件、服务器证书等信息的消息。

	if _, err := c.writeRecord(recordTypeHandshake, hs.hello.marshal()); err != nil {
		return err
	}

	// 3. 证书交换：服务器发送其证书给客户端，以证明自己的身份。

	// 创建证书对象。
	certMsg := new(certificateMsg)
	// 遍历所有证书，并将其添加到证书消息中。
	for i := 0; i < len(hs.cert); i++ {
		certMsg.certificates = append(certMsg.certificates, hs.cert[i].Certificate...)
	}
	hs.finishedHash.Write(certMsg.marshal())
	// 发送证书
	if _, err := c.writeRecord(recordTypeHandshake, certMsg.marshal()); err != nil {
		return err
	}

	// 如果启用了OCSP装订，则发送OCSP响应。
	if hs.hello.ocspStapling {
		certStatus := new(certificateStatusMsg)
		certStatus.statusType = statusTypeOCSP
		certStatus.response = hs.cert[0].OCSPStaple
		hs.finishedHash.Write(certStatus.marshal())
		if _, err := c.writeRecord(recordTypeHandshake, certStatus.marshal()); err != nil {
			return err
		}
	}

	// 生成服务器密钥交换消息。这个密钥实际上是一个被服务器用私钥签名的一个数, 客户端也会利用签名发送的证书去验证
	// 这样做是为了确保服务器的身份真实可信，并且没有中间人攻击（MITM）发生, 并不适合为了生成预主密钥
	keyAgreement := hs.suite.ka(c.vers)
	skx, err := keyAgreement.generateServerKeyExchange(c.config, &hs.cert[0], &hs.cert[1], hs.clientHello, hs.hello)
	if err != nil {
		c.sendAlert(alertHandshakeFailure)
		return err
	}
	if skx != nil {
		hs.finishedHash.Write(skx.marshal())
		if _, err := c.writeRecord(recordTypeHandshake, skx.marshal()); err != nil {
			return err
		}
	}

	// 如果配置要求客户端证书，则请求客户端证书。一般来说, fabric中双方都是需要密钥的
	if c.config.ClientAuth >= RequestClientCert {
		// Request a client certificate
		certReq := new(certificateRequestMsgGM)
		certReq.certificateTypes = []byte{
			byte(certTypeRSASign),
			byte(certTypeECDSASign),
		}
		// 如果配置了受信任的证书颁发机构列表，则发送这些信息。
		if c.config.ClientCAs != nil {
			certReq.certificateAuthorities = c.config.ClientCAs.Subjects()
		}
		hs.finishedHash.Write(certReq.marshal())
		// 请求获取客户端证书
		if _, err := c.writeRecord(recordTypeHandshake, certReq.marshal()); err != nil {
			return err
		}
	}

	// 4. 服务器Hello Done：服务器通知客户端已完成其初始消息的发送。

	// 发送ServerHelloDone消息。
	helloDone := new(serverHelloDoneMsg)
	hs.finishedHash.Write(helloDone.marshal())
	if _, err := c.writeRecord(recordTypeHandshake, helloDone.marshal()); err != nil {
		return err
	}

	...

	var pub crypto.PublicKey // 客户端身份验证的公钥，如果有的话

	// 5. 客户端密钥交换：客户端计算一个预主密钥（Pre-Master Secret），并使用服务器证书中的公钥对其进行加密，然后发送给服务器。

	// 读取下客户端计算的预主密钥
	msg, err := c.readHandshake()
	if err != nil {
		fmt.Println("readHandshake error:", err)
		return err
	}

	var ok bool
	// 如果请求了客户端证书，则客户端必须发送证书消息，即使它是空的。一般来说, fabric中双方都是需要密钥的
	if c.config.ClientAuth >= RequestClientCert {
		if certMsg, ok = msg.(*certificateMsg); !ok {
			c.sendAlert(alertUnexpectedMessage)
			return unexpectedMessageError(certMsg, msg)
		}
		hs.finishedHash.Write(certMsg.marshal())

		if len(certMsg.certificates) == 0 {
			// 客户端实际上没有发送证书
			switch c.config.ClientAuth {
			case RequireAnyClientCert, RequireAndVerifyClientCert:
				c.sendAlert(alertBadCertificate)
				return errors.New("tls: client didn't provide a certificate")
			}
		}

		// 处理客户端发来的证书。
		pub, err = hs.processCertsFromClient(certMsg.certificates)
		if err != nil {
			return err
		}

		// 读取下一个握手消息。
		msg, err = c.readHandshake()
		if err != nil {
			return err
		}
	}

	// 获取客户端密钥交换消息。
	ckx, ok := msg.(*clientKeyExchangeMsg)
	if !ok {
		c.sendAlert(alertUnexpectedMessage)
		return unexpectedMessageError(ckx, msg)
	}
	hs.finishedHash.Write(ckx.marshal())

	// 处理客户端密钥交换消息，并生成预主密钥。
	// 使用服务器持有的私钥来解密客户端密钥交换消息中的内容，得到原始的预主密钥。
	preMasterSecret, err := keyAgreement.processClientKeyExchange(c.config, &hs.cert[1], ckx, c.vers)
	if err != nil {
		c.sendAlert(alertHandshakeFailure)
		return err
	}
	// 计算主密钥。
    // 负责从预主密钥、客户端随机数（ClientHello.random）和服务器随机数（ServerHello.random）生成主密钥。
    // 主密钥不会直接用于加密数据，而是用于派生对称密钥。
    // 这些对称密钥用于加密实际的数据传输。对称密钥的生成通常在握手过程的后续阶段完成，并且是由主密钥通过特定算法派生出来的。
    // 类似于区块链钱包的助记词, 可以派生对称密钥。
	hs.masterSecret = masterFromPreMasterSecret(c.vers, hs.suite, preMasterSecret, hs.clientHello.random, hs.hello.random)
	// 将计算的对称密钥存在本地日志中,这个步骤不是必需的，但它有助于后续分析握手过程中的数据
	if err := c.config.writeKeyLog(hs.clientHello.random, hs.masterSecret); err != nil {
		c.sendAlert(alertInternalError)
		return err
	}

	// 如果收到了客户端证书，则客户端会立即发送一个证书验证消息。一般来说, fabric中双方都是需要密钥的
	if len(c.peerCertificates) > 0 {
		msg, err = c.readHandshake()
		if err != nil {
			return err
		}
		certVerify, ok := msg.(*certificateVerifyMsg)
		if !ok {
			c.sendAlert(alertUnexpectedMessage)
			return unexpectedMessageError(certVerify, msg)
		}

		// 确定签名类型。
		_, sigType, hashFunc, err := pickSignatureAlgorithm(pub, []SignatureScheme{certVerify.signatureAlgorithm}, supportedSignatureAlgorithms, c.vers)
		if err != nil {
			c.sendAlert(alertIllegalParameter)
			return err
		}

		var digest []byte
		if digest, err = hs.finishedHash.hashForClientCertificate(sigType, hashFunc, hs.masterSecret); err == nil {
			err = verifyHandshakeSignature(sigType, pub, hashFunc, digest, certVerify.signature)
		}
		if err != nil {
			c.sendAlert(alertBadCertificate)
			return errors.New("tls: could not validate signature of connection nonces: " + err.Error())
		}

		// 更新哈希对象，包含证书验证消息。
		hs.finishedHash.Write(certVerify.marshal())
	}
	...

	return nil
}
```

这里主要的地方在于

5. 生成服务器密钥交换消息。

```go
	// 生成服务器密钥交换消息。这个密钥实际上是一个被服务器用私钥签名的一个数, 客户端也会利用签名发送的证书去验证
	keyAgreement := hs.suite.ka(c.vers)
	skx, err := keyAgreement.generateServerKeyExchange(c.config, &hs.cert[0], &hs.cert[1], hs.clientHello, hs.hello)
```

`gmtls/gm_key_agreement.go`

```go
// generateServerKeyExchange 用于生成服务器密钥交换消息。这个密钥实际上是一个被服务器用私钥签名的一个数, 客户端也会利用签名发送的证书去验证
func (ka *eccKeyAgreementGM) generateServerKeyExchange(config *Config, signCert, cipherCert *Certificate,
	clientHello *clientHelloMsg, hello *serverHelloMsg) (*serverKeyExchangeMsg, error) {
	// 计算用于签名的数据摘要。
	// 注意：这里假设cipherCert.Certificate[0]包含了用于加密的公钥证书。
	digest := ka.hashForServerKeyExchange(clientHello.random, hello.random, cipherCert.Certificate[0])

	// 获取签名证书的私钥。
	priv, ok := signCert.PrivateKey.(crypto.Signer)
	if !ok {
		return nil, errors.New("tls: certificate private key does not implement crypto.Signer")
	}
	// 使用私钥对摘要进行签名。
	sig, err := priv.Sign(config.rand(), digest, nil)
	if err != nil {
		return nil, err
	}

	// 计算签名长度。
	len := len(sig)

	// 创建服务器密钥交换消息。
	ske := new(serverKeyExchangeMsg)

	// 构建消息结构体。
	// 前两个字节表示签名长度，剩下的字节存放签名数据。
	ske.key = make([]byte, len+2)
	ske.key[0] = byte(len >> 8) // 高位字节
	ske.key[1] = byte(len)      // 低位字节
	copy(ske.key[2:], sig)      // 复制签名数据

	// 返回构建好的服务器密钥交换消息。
	return ske, nil
}
```

5. 客户端密钥交换：客户端计算一个预主密钥（Pre-Master Secret），并使用服务器证书中的公钥对其进行加密，然后发送给服务器。

```go
	// 处理客户端密钥交换消息，并生成预主密钥。
	// 使用服务器持有的私钥来解密客户端密钥交换消息中的内容，得到原始的预主密钥。
	preMasterSecret, err := keyAgreement.processClientKeyExchange(c.config, &hs.cert[1], ckx, c.vers)
	if err != nil {
		c.sendAlert(alertHandshakeFailure)
		return err
	}
	// 计算主密钥。
    // 负责从预主密钥、客户端随机数（ClientHello.random）和服务器随机数（ServerHello.random）生成主密钥。
    // 主密钥不会直接用于加密数据，而是用于派生对称密钥。
    // 这些对称密钥用于加密实际的数据传输。对称密钥的生成通常在握手过程的后续阶段完成，并且是由主密钥通过特定算法派生出来的。
    // 类似于区块链钱包的助记词, 可以派生对称密钥。
	hs.masterSecret = masterFromPreMasterSecret(c.vers, hs.suite, preMasterSecret, hs.clientHello.random, hs.hello.random)
	// 将计算的对称密钥存在本地日志中,这个步骤不是必需的，但它有助于后续分析握手过程中的数据
	if err := c.config.writeKeyLog(hs.clientHello.random, hs.masterSecret); err != nil {
		c.sendAlert(alertInternalError)
		return err
	}
```

### 4. 客户端计算一个预主密钥加密发送给服务器

继续回到客户端部分

```go
		// 客户端执行完整的握手
		// 3. 证书交换：服务器发送其证书给客户端，以证明自己的身份。
		// 4. 服务器Hello Done：服务器通知客户端已完成其初始消息的发送。
		// 5. 客户端密钥交换：客户端计算一个预主密钥（Pre-Master Secret），并使用服务器证书中的公钥对其进行加密，然后发送给服务器。
		// 6. 变更密码规范：客户端和服务器分别通知对方它们将开始使用新的加密密钥。
		if err := hs.doFullHandshake(); err != nil {
			return err
		}
```

**客户端执行完整的握手**

```go
// doFullHandshake 客户端执行完整的TLS握手过程。
// 3. 证书交换：服务器发送其证书给客户端，以证明自己的身份。
// 4. 服务器Hello Done：服务器通知客户端已完成其初始消息的发送。
// 5. 客户端密钥交换：客户端计算一个预主密钥（Pre-Master Secret），并使用服务器证书中的公钥对其进行加密，然后发送给服务器。
// 6. 变更密码规范：客户端和服务器分别通知对方它们将开始使用新的加密密钥。
func (hs *clientHandshakeStateGM) doFullHandshake() error {
	c := hs.c

	// 3. 证书交换：服务器发送其证书给客户端，以证明自己的身份。

	// 服务器证书信息
	msg, err := c.readHandshake()
	if err != nil {
		return err
	}
	// 解析证书消息。
	certMsg, ok := msg.(*certificateMsg)
	if !ok || len(certMsg.certificates) == 0 {
		c.sendAlert(alertUnexpectedMessage)
		return unexpectedMessageError(certMsg, msg)
	}

	// 根据GMT0024规范，证书长度必须大于2（即至少有两个证书）。
	if len(certMsg.certificates) < 2 {
		c.sendAlert(alertInsufficientSecurity)
		return fmt.Errorf("tls: length of certificates in GMT0024 must great than 2")
	}

	// 更新哈希对象，包含证书消息。
	hs.finishedHash.Write(certMsg.marshal())

	// 如果这是连接上的第一次握手，则处理并验证服务器的证书。
	if c.handshakes == 0 {
		certs := make([]*x509.Certificate, len(certMsg.certificates))
		// 解析每个证书，并检查公钥类型和KeyUsage。
		for i, asn1Data := range certMsg.certificates {
			cert, err := x509.ParseCertificate(asn1Data)
			if err != nil {
				c.sendAlert(alertBadCertificate)
				return errors.New("tls: failed to parse certificate from server: " + err.Error())
			}

			// 检查公钥类型是否为SM2。
			pubKey, _ := cert.PublicKey.(*ecdsa.PublicKey)
			if pubKey.Curve != sm2.P256Sm2() {
				c.sendAlert(alertUnsupportedCertificate)
				return fmt.Errorf("tls: pubkey type of cert is error, expect sm2.publicKey")
			}

			// 检查KeyUsage。
			switch i {
			case 0:
				if cert.KeyUsage == 0 || (cert.KeyUsage&(x509.KeyUsageDigitalSignature|cert.KeyUsage&x509.KeyUsageContentCommitment)) == 0 {
					c.sendAlert(alertInsufficientSecurity)
					return fmt.Errorf("tls: the keyusage of cert[0] does not exist or is not for KeyUsageDigitalSignature/KeyUsageContentCommitment, value:%d", cert.KeyUsage)
				}
			case 1:
				if cert.KeyUsage == 0 || (cert.KeyUsage&(x509.KeyUsageDataEncipherment|x509.KeyUsageKeyEncipherment|x509.KeyUsageKeyAgreement)) == 0 {
					c.sendAlert(alertInsufficientSecurity)
					return fmt.Errorf("tls: the keyusage of cert[1] does not exist or is not for KeyUsageDataEncipherment/KeyUsageKeyEncipherment/KeyUsageKeyAgreement, value:%d", cert.KeyUsage)
				}
			}

			certs[i] = cert
		}

		// 验证证书链。
		if !c.config.InsecureSkipVerify {
			opts := x509.VerifyOptions{
				Roots:         c.config.RootCAs,
				CurrentTime:   c.config.time(),
				DNSName:       c.config.ServerName,
				Intermediates: x509.NewCertPool(),
			}
			if opts.Roots == nil {
				opts.Roots = x509.NewCertPool()
			}

			// 添加根证书。
			for _, rootca := range getCAs() {
				opts.Roots.AddCert(rootca)
			}
			// 使用客户端本地的根证书验证服务端的证书
			for i, cert := range certs {
				c.verifiedChains, err = certs[i].Verify(opts)
				if err != nil {
					c.sendAlert(alertBadCertificate)
					return err
				}
				if i == 0 || i == 1 {
					continue
				}
				opts.Intermediates.AddCert(cert)
			}

		}

		// 自定义证书验证函数。
		if c.config.VerifyPeerCertificate != nil {
			if err := c.config.VerifyPeerCertificate(certMsg.certificates, c.verifiedChains); err != nil {
				c.sendAlert(alertBadCertificate)
				return err
			}
		}

		// 检查公钥类型。
		switch certs[0].PublicKey.(type) {
		case *sm2.PublicKey, *ecdsa.PublicKey, *rsa.PublicKey:
			break
		default:
			c.sendAlert(alertUnsupportedCertificate)
			return fmt.Errorf("tls: server's certificate contains an unsupported type of public key: %T", certs[0].PublicKey)
		}

		// 保存解析后的证书链。
		c.peerCertificates = certs
	} else {
		// 如果这是重新协商的握手，则确保服务器的身份未改变。
		if !bytes.Equal(c.peerCertificates[0].Raw, certMsg.certificates[0]) {
			c.sendAlert(alertBadCertificate)
			return errors.New("tls: server's identity changed during renegotiation")
		}
	}

	// 4. 服务器密钥交换: 服务器用私钥签名生成服务器密钥交换消息, 发送给客户端, 客户端可以用收到的证书公钥验证

	// 读取服务器通知客户端已完成
	msg, err = c.readHandshake()
	if err != nil {
		return err
	}

	// 初始化密钥协议对象。
	keyAgreement := hs.suite.ka(c.vers)
	// 将服务端的证书赋值给这个 keyAgreement 对象
	if ka, ok := keyAgreement.(*eccKeyAgreementGM); ok {
		ka.encipherCert = c.peerCertificates[1]
	}

	// 解析服务器密钥交换消息。
	skx, ok := msg.(*serverKeyExchangeMsg)
	if ok {
		hs.finishedHash.Write(skx.marshal())
		// 客户端可以用收到的服务器证书公钥验证密钥交换消息
		// 这样做是为了确保服务器的身份真实可信，并且没有中间人攻击（MITM）发生, 并不适合为了生成预主密钥
		err = keyAgreement.processServerKeyExchange(c.config, hs.hello, hs.serverHello, c.peerCertificates[0], skx)
		if err != nil {
			c.sendAlert(alertUnexpectedMessage)
			return err
		}

		// 读取是否需要发送客户端证书给服务端的msg
		msg, err = c.readHandshake()
		if err != nil {
			return err
		}
	}

	// 解析证书请求消息。
	var chainToSend *Certificate
	var certRequested bool
	certReq, ok := msg.(*certificateRequestMsgGM)
	if ok {
		certRequested = true
		hs.finishedHash.Write(certReq.marshal())

		// 获取要发送的客户端证书链。
		if chainToSend, err = hs.getCertificate(certReq); err != nil {
			c.sendAlert(alertInternalError)
			return err
		}

		// 4. 服务器Hello Done：服务器通知客户端已完成其初始消息的发送。

		// 读取下一个握手消息。
		msg, err = c.readHandshake()
		if err != nil {
			return err
		}
	}

	// 解析ServerHelloDone消息。
	shd, ok := msg.(*serverHelloDoneMsg)
	if !ok {
		c.sendAlert(alertUnexpectedMessage)
		return unexpectedMessageError(shd, msg)
	}
	hs.finishedHash.Write(shd.marshal())

	// 如果服务器请求了需要客户端证书，则发送客户端证书消息。
	if certRequested {
		certMsg = new(certificateMsg)
		certMsg.certificates = chainToSend.Certificate
		hs.finishedHash.Write(certMsg.marshal())
		if _, err := c.writeRecord(recordTypeHandshake, certMsg.marshal()); err != nil {
			return err
		}
	}

	// 5. 客户端密钥交换：客户端计算一个预主密钥（Pre-Master Secret），并使用服务器证书中的公钥对其进行加密，然后发送给服务器。

	// 生成客户端密钥交换消息。用服务端的证书的公钥加密, 得到预主密钥
	preMasterSecret, ckx, err := keyAgreement.generateClientKeyExchange(c.config, hs.hello, c.peerCertificates[1])
	if err != nil {
		c.sendAlert(alertInternalError)
		return err
	}
	if ckx != nil {
		hs.finishedHash.Write(ckx.marshal())
		// 发送预主密钥给服务端
		if _, err := c.writeRecord(recordTypeHandshake, ckx.marshal()); err != nil {
			return err
		}
	}

	// 如果发送了证书，则发送证书验证消息。
	if chainToSend != nil && len(chainToSend.Certificate) > 0 {
		certVerify := &certificateVerifyMsg{}

		// 获取私钥并生成签名。
		key, ok := chainToSend.PrivateKey.(crypto.Signer)
		if !ok {
			c.sendAlert(alertInternalError)
			return fmt.Errorf("tls: client certificate private key of type %T does not implement crypto.Signer", chainToSend.PrivateKey)
		}

		digest := hs.finishedHash.client.Sum(nil)

		certVerify.signature, err = key.Sign(c.config.rand(), digest, nil)
		if err != nil {
			c.sendAlert(alertInternalError)
			return err
		}

		hs.finishedHash.Write(certVerify.marshal())
		if _, err := c.writeRecord(recordTypeHandshake, certVerify.marshal()); err != nil {
			return err
		}
	}

	// 计算主密钥。
	// 负责从预主密钥、客户端随机数（ClientHello.random）和服务器随机数（ServerHello.random）生成主密钥。
	// 主密钥不会直接用于加密数据，而是用于派生对称密钥。
	// 这些对称密钥用于加密实际的数据传输。对称密钥的生成通常在握手过程的后续阶段完成，并且是由主密钥通过特定算法派生出来的。
	// 类似于区块链钱包的助记词, 可以派生对称密钥。
	hs.masterSecret = masterFromPreMasterSecret(c.vers, hs.suite, preMasterSecret, hs.hello.random, hs.serverHello.random)
	// 记录日志
	if err := c.config.writeKeyLog(hs.hello.random, hs.masterSecret); err != nil {
		c.sendAlert(alertInternalError)
		return errors.New("tls: failed to write to key log: " + err.Error())
	}

	// 清除握手缓冲区。
	hs.finishedHash.discardHandshakeBuffer()

	return nil
}
```

