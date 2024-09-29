### 如何处理WebSocket连接

在 Gin 中处理 WebSocket 连接需要使用第三方库，因为 Gin 本身并没有内置 WebSocket 支持。

常用的第三方库包括 `github.com/gorilla/websocket`，这是一个非常流行的 WebSocket 库，提供了丰富的功能来处理 WebSocket 连接。

下面是一个使用 `gorilla/websocket` 在 Gin 中实现 WebSocket 连接的基本示例。

### 安装依赖库

首先，确保你已经安装了 `gorilla/websocket` 库：

```sh
go get github.com/gorilla/websocket
```

### 示例代码

```go
package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"sync"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
)

// Message 代表 WebSocket 消息类型
type Message struct {
	Type    string `json:"type"`
	Message string `json:"message"`
}

// Client 代表一个 WebSocket 客户端连接
type Client struct {
	conn     *websocket.Conn
	sentChan chan []byte
}

// ServeWs 代表 WebSocket 服务端
type ServeWs struct {
	clients    map[*Client]bool // 客户端
	broadcast  chan []byte      // 广播通道
	register   chan *Client     // 注册通道
	unregister chan *Client     // 注销通道
	mu         sync.Mutex
}

// NewServeWs 创建一个新的 WebSocket 服务端实例
func NewServeWs() *ServeWs {
	return &ServeWs{
		clients:    make(map[*Client]bool), // 客户端
		broadcast:  make(chan []byte),      // 广播通道
		register:   make(chan *Client),     // 注册通道
		unregister: make(chan *Client),     // 注销通道
	}
}

// Start 启动 WebSocket 服务端
func (sw *ServeWs) Start() {
	go sw.run()
}

// run 是 WebSocket 服务端的主循环
func (sw *ServeWs) run() {
	for {
		select {
		case client := <-sw.register: // 注册
			sw.mu.Lock()
			sw.clients[client] = true
			sw.mu.Unlock()
		case client := <-sw.unregister: //注销
			sw.mu.Lock()
			if _, ok := sw.clients[client]; ok {
				delete(sw.clients, client)
				close(client.sentChan)
			}
			sw.mu.Unlock()
		case message := <-sw.broadcast: // 广播给所有客户端
			sw.mu.Lock()
			for client := range sw.clients {
				select {
				case client.sentChan <- message:
				default:
					close(client.sentChan)
					delete(sw.clients, client)
				}
			}
			sw.mu.Unlock()
		}
	}
}

// Broadcast 广播消息给所有客户端
func (sw *ServeWs) Broadcast(message []byte) {
	sw.broadcast <- message
}

// wsEndpoint 处理 WebSocket 连接
func wsEndpoint(ws *ServeWs, c *gin.Context) {
	// 升级 HTTP 连接为 WebSocket 连接
	wsConn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		fmt.Println("Upgrade:", err)
		return
	}

	// 创建客户端实例
	client := &Client{conn: wsConn, sentChan: make(chan []byte, 256)}

	// 注册客户端
	ws.register <- client

	// 启动客户端监听服务端准备发送的消息
	go client.writePump()

	// 监听 WebSocket 来自客户端的消息
	client.readPump(ws)
}

// writePump 服务端准备发送的消息
func (cl *Client) writePump() {
	defer cl.conn.Close()
	for {
		select {
		case message, ok := <-cl.sentChan:
			if !ok {
				cl.conn.WriteMessage(websocket.CloseMessage, websocket.FormatCloseMessage(websocket.CloseNormalClosure, ""))
				return
			}
			if err := cl.conn.WriteMessage(websocket.TextMessage, message); err != nil {
				fmt.Println("write:", err)
				return
			}
		}
	}
}

// readPump 来自客户端的消息
func (cl *Client) readPump(ws *ServeWs) {
	defer func() {
		ws.unregister <- cl
		cl.conn.Close()
	}()
	for {
		_, message, err := cl.conn.ReadMessage()
		if err != nil {
			fmt.Println("read:", err)
			break
		}
		fmt.Printf("Received: %s\n", message)
		msg := Message{}
		if err := json.Unmarshal(message, &msg); err == nil {
			fmt.Printf("Parsed Message: %+v\n", msg)

			// 处理消息后广播回客户端
			ws.Broadcast([]byte("ok"))
		}
	}
}

var upgrader = websocket.Upgrader{
	// 允许来自任何来源的连接
	CheckOrigin: func(r *http.Request) bool {
		return true
	},
}

func main() {
	// 创建一个默认的路由引擎实例
	router := gin.Default()

	// 创建 WebSocket 服务端实例
	ws := NewServeWs()

	// 设置 WebSocket 路由
	router.GET("/ws", func(c *gin.Context) {
		wsEndpoint(ws, c)
	})

	// 启动 WebSocket 服务端
	ws.Start()

	// 启动 HTTP 服务，监听在 8080 端口
	router.Run(":8080")
}
```

### 说明

1. **定义消息类型**：创建一个 `Message` 结构体来表示 WebSocket 消息。
2. **定义客户端连接**：创建一个 `Client` 结构体来表示 WebSocket 客户端连接。每个客户端都有一个 WebSocket 连接和一个用于发送消息的通道。
3. **定义 WebSocket 服务端**：创建一个 `ServeWs` 结构体来表示 WebSocket 服务端。它包含客户端列表、广播通道、注册通道和注销通道。
4. **初始化 WebSocket 升级器**：创建一个 `websocket.Upgrader` 实例，用于将 HTTP 连接升级为 WebSocket
   连接。这里设置 `CheckOrigin` 函数为总是返回 `true`，这意味着允许来自任何来源的 WebSocket 连接。在生产环境中，你可能需要更严格的源检查。
5. **设置 WebSocket 路由**：定义一个处理 WebSocket 连接的路由 `/ws`。在这个路由中，使用 `upgrader.Upgrade` 方法将 HTTP
   连接升级为 WebSocket 连接，并处理 WebSocket 消息的读写操作。
6. **启动 WebSocket 服务端**：启动 WebSocket 服务端的主循环，负责注册、注销客户端以及广播消息。
7. **监听消息**：在客户端中，使用 `readPump` 函数监听 WebSocket 消息，并将消息转发给其他客户端。
8. **发送消息**：在客户端中，使用 `writePump` 函数处理消息发送。

### 测试 WebSocket 连接

你可以使用浏览器或者 WebSocket 客户端（如 WebSocket 测试工具）来测试 WebSocket 连接：

#### 使用浏览器测试

1. 在浏览器中打开开发者工具的控制台。
2. 输入以下 JavaScript 代码来建立 WebSocket 连接：

```js
const socket = new WebSocket('ws://localhost:8080/ws');

socket.addEventListener('open', () => {
  console.log('WebSocket connection established');
  
  // 在连接成功建立后发送消息
  socket.send(JSON.stringify({
    type: 'chat',
    message: 'Hello, WebSocket!'
  }));
});

socket.addEventListener('message', (event) => {
  console.log(`Received from server: ${event.data}`);
});
```

### 总结

通过上述示例，你可以使用 `gorilla/websocket` 在 Gin 中实现一个基本的 WebSocket
服务端，能够处理客户端的连接、监听消息、发送消息，并且在关闭连接时进行清理工作。你可以根据具体需求调整和扩展这些示例代码。