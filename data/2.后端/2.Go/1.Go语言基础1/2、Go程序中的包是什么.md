# 简介

在 Go 语言中，"包"（package）是组织代码的基本单元，类似于其他编程语言中的模块或命名空间。

包用于封装相关的函数、类型、变量和常量，提供了一种管理代码复杂度、避免命名冲突以及控制公共和私有接口的方式。

# 包的基本概念

1. **定义包**： 每个 Go 文件的开头都必须声明其所属的包。例如：

   ```go
   package main
   ```

   或者：

   ```go
   package mypackage
   ```

   `main` 包是特殊的，它是程序执行的入口点。


2. **导入包**： 使用 `import` 关键字来导入其他包，以便在当前包中使用它们的功能。

   例如，导入标准库中的 `fmt` 包：

   ```go
   import "fmt"
   ```


3. **包的作用域**： 包内的标识符（如变量、函数、类型等）默认是私有的，除非首字母大写，这样其他包才能访问它们。

   这种规则简化了命名策略，减少了命名冲突的可能性。


4. **包的初始化**： 包可以包含一个或多个名为 `init()` 的函数，这些函数会在包被导入时自动调用，用于执行一些初始化任务。

# 包的使用示例

假设你有一个项目，其中包含两个包：`mypackage` 和 `main`。

`mypackage/package.go`:

```go
package mypackage

// 大写开头: 公共函数
func Greet(name string) string {
    return "Hello, " + name
}
```

`main/main.go`:

```go
package main

// 引入包
import (
    "fmt"
    "mypackage"
)

func main() {
    // 调用公共函数
    fmt.Println(mypackage.Greet("World"))
}
```

在这个例子中，`mypackage` 提供了一个公共函数 `Greet`，`main` 包通过导入 `mypackage` 来使用这个函数。

# 包的组织和管理

Go 语言使用 GOPATH 和 Go Modules 来管理包的依赖关系。

在 Go 1.11 之后，推荐使用 Go Modules 来处理依赖，它允许每个项目独立地管理其依赖项，避免了全局 GOPATH 的限制。