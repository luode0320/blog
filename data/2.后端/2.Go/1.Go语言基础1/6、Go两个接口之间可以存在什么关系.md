# 实现关系

一个接口可以被另一个类型（包括结构体、其他接口）实现。

如果一个类型实现了接口中定义的所有方法，那么这个类型就自动实现了该接口。

例如：

```go
package main

import (
	"fmt"
)

type Animal1 interface {
	Speak() string
}

type Animal2 interface {
	Speak() string
}

type Dog struct{}

func (d Dog) Speak() string {
	return "Woof!"
}

func main() {
    // dog实现了Speak()方法, 即可以是 Animal1 也可以是 Animal2
    // Animal1 和 Animal2 是等价的
	var a1 Animal1 = Dog{}
	var a2 Animal2 = Dog{}
	fmt.Println(a1.Speak())
	fmt.Println(a2.Speak())
}
```

输出结果:

```go
Woof!
Woof!
```

# 子集关系

一个接口可以是另一个接口的子集。

也就是说，如果接口 A 包含了接口 B 的所有方法，那么任何实现了接口 A 的类型也自动实现了接口 B。

例如：

```go
package main

import (
	"fmt"
)

type Animal interface {
	Speak() string
}

type SwimmingAnimal interface {
	Speak() string
	Swim() string
}

type Dog struct{}

func (d Dog) Speak() string {
	return "Speak!"
}

func (d Dog) Swim() string {
	return "Swim!"
}

func main() {
    // dog 可以赋值给 Animal 调用 Speak, 也可以赋值给 SwimmingAnimal 调用 Speak
    // 说明 dog 不仅仅实现了 SwimmingAnimal 的 Speak 和 Swim, 实现了 SwimmingAnimal 接口
    // 同样顺便实现了 Animal 接口
	var a1 Animal = Dog{}
	var a2 SwimmingAnimal = Dog{}
	fmt.Println(a1.Speak())
	fmt.Println(a2.Speak())
}
```

执行结果:

```go
Speak!
Speak!
```

在这个例子中，`SwimmingAnimal` 接口包含 `Animal` 接口的所有方法，并添加了一个额外的 `Swim` 方法。

任何实现了 `SwimmingAnimal` 接口的类型也会自动实现 `Animal` 接口。

# 空接口

空接口（`interface{}`）是一个特殊类型的接口，它不包含任何方法。

由于它没有定义任何方法，所以任何类型都可以实现空接口。

这使得空接口成为了一种通用的类型，可以存储任何类型的值。

# 嵌入关系

一个接口可以嵌入另一个接口。

这类似于子集关系，但语法略有不同。

你可以在接口中直接嵌入另一个接口，而不是显式地列出所有方法。

例如：

```go
type Animal interface {
    Speak() string
}

type WalkingAnimal interface {
    Animal
    Walk() string
}

type WalkingSwimmingAnimal interface {
    WalkingAnimal
    Swim() string
}
```

在这个例子中，`WalkingAnimal` 和 `WalkingSwimmingAnimal` 接口中都通过嵌入 `Animal` 接口来继承其方法。

