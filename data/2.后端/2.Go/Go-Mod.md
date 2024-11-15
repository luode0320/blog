`go mod` 命令是 Go 语言用来管理依赖和模块的工具，以下是一些常用的 `go mod` 子命令及其说明：

### 1. 初始化模块

```
go mod init <module-name>
```

初始化一个新的模块，会生成一个 `go.mod` 文件。`<module-name>` 通常是你的项目路径，例如 `github.com/username/projectname`。

### 2. 下载依赖

```
go mod tidy
```

整理依赖项，添加缺少的模块并移除不再需要的模块。此命令会自动更新 `go.mod` 和 `go.sum` 文件。

```
go mod download
```

下载所有依赖的模块，并将它们缓存到本地 `GOPATH/pkg/mod` 目录下。

### 3. 更新依赖

```
go get <module>
```

获取或更新指定模块的依赖。例如，`go get example.com/pkg` 会将 `example.com/pkg` 作为依赖添加到项目中。

```
go get -u
```

更新所有模块的依赖到最新的次要版本。例如，`go get -u` 会将所有依赖更新到它们的最新版本。

```
go get -u=patch
```

更新所有依赖项到最新的补丁版本，保持主版本和次版本不变。

### 4. 显示依赖关系

```
go mod graph
```

显示当前模块的依赖图，输出所有直接和间接依赖关系。

### 5. 校验依赖

```
go mod verify
```

检查 `go.sum` 中的模块是否被正确下载，如果有损坏或被篡改的模块，将输出错误信息。

### 6. 切换为模块依赖的 vendoring 模式

```
go mod vendor
```

将所有依赖复制到项目的 `vendor` 目录中。此模式可以锁定依赖版本，适用于希望确保依赖一致性的项目。

### 7. 列出模块信息

```
go list -m all
```

列出项目的所有模块依赖，包括直接和间接依赖。

### 8. 修改模块的 Go 版本

```
go mod edit -go=1.20
```

将 `go.mod` 文件中的 Go 版本修改为 1.20。