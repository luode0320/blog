# 简介

在 Go 语言中，`new` 是一个内建函数，用于为给定的类型分配内存。

`new` 函数并不会调用任何构造函数或初始化方法，它仅仅分配内存并将内存中的所有字节设置为零值（即它们类型的零值）。

`new` 返回的是指向新分配内存的指针。

# 基本语法

`new` 函数的基本语法如下：

```go
func new(Type) *Type
```

这里的 `type` 是你需要分配内存的类型的名称。例如，如果你想为整型分配内存，你可以这样使用 `new`：

```go
p := new(int)
```

在这个例子中，`p` 是一个指向整型的指针。由于 `new` 将内存设置为零值，`*p` 的值将为 `0`。

如果你想为一个结构体类型分配内存，你可以这样使用 `new`：

```go
type Person struct {
    Name string
    Age  int
}

p := new(Person)
```

在这里，`p` 是一个指向 `Person` 类型的指针。由于 `new` 将内存设置为零值，`p.Name` 将为 `""`（空字符串），`p.Age` 将为 `0`。

下面是一个更具体的例子，演示如何使用 `new` 分配内存给一个自定义的结构体类型，并访问它的字段：

```go
package main

import "fmt"

type Employee struct {
    ID   int
    Name string
}

func main() {
    emp := new(Employee)
    fmt.Printf("ID: %d, Name: %s\n", (*emp).ID, (*emp).Name)

    // 或者使用点运算符访问指针的字段
    emp.ID = 1
    emp.Name = "John Doe"
    fmt.Printf("ID: %d, Name: %s\n", emp.ID, emp.Name)
}
```

在这个例子中，我们首先使用 `new` 分配内存给 `Employee` 类型，并创建了一个指向 `Employee` 的指针 `emp`。

然后，我们访问并修改了 `emp` 指向的 `Employee` 对象的字段。

请注意，当你使用 `new` 时，你通常会得到一个指向新分配内存的指针。这意味着你需要使用指针解引用来访问或修改新分配的对象的字段。

运行结果:

```go
ID: 0, Name:
ID: 1, Name: John Doe
```

