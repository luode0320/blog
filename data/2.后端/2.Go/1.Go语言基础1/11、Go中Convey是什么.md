# 简介

GoConvey 是一个为 Go (Golang) 语言设计的单元测试框架，它提供了一种行为驱动开发 (Behavior Driven Development, BDD)
风格的测试方式。

GoConvey 引入了一种易于阅读和编写的测试语法，使得测试更加清晰和直观。

# 特点

GoConvey 的主要特点包括：

1. **BDD 风格的测试**：GoConvey 使用类似于自然语言的语法来描述测试案例，这使得测试更易于理解和编写，即使是非技术人员也能读懂测试的意图。
2. **实时反馈**：GoConvey 可以在开发过程中提供实时的测试结果反馈，当代码发生变化时，它会自动运行受影响的测试，并在 Web
   界面上显示测试结果，便于开发者快速定位问题。
3. **丰富的断言**：GoConvey 提供了一系列丰富的断言方法，简化了测试用例的编写过程，使开发者可以专注于测试逻辑本身，而不是复杂的断言语法。
4. **自动化测试运行**：GoConvey 支持自动运行测试，当源代码发生改变时，它能够检测到这些变化并自动重新运行相关测试，加快了开发和测试的迭代速度。
5. **Web UI**：GoConvey 包含一个 Web 界面，可以直观地展示测试结果，包括测试覆盖度等信息，使得测试状态对团队成员透明。
6. **集成与标准测试库**：GoConvey 直接与 Go 的标准测试库集成，可以与 `testing` 包无缝协作，这意味着你可以利用 GoConvey
   的特性来增强标准测试库的功能，同时保持代码的兼容性。

GoConvey 一般用于编写和执行单元测试，它可以帮助开发者确保代码的正确性、稳定性和健壮性。它尤其适用于那些需要频繁重构或维护的项目，因为它可以提供快速的反馈循环，帮助开发者在引入新功能或修复
bug 时保持代码的质量。

# 示例

`main_test.go`

```go
package main

import (
	"github.com/smartystreets/goconvey/convey"
	"testing"
)

// 这里定义 add 函数
func add(a, b int) int {
	return a + b
}

func TestAdd(t *testing.T) {
	convey.Convey("Given two numbers to add", t, func() {
		a := 2
		b := 3

		convey.Convey("When adding them together", func() {
			result := add(a, b)

			convey.Convey("Then the result should be correct", func() {
				convey.So(result, convey.ShouldEqual, 5)
			})
		})
	})
}

```

运行结果:

```go
=== RUN   TestAdd
.
1 total assertion

--- PASS: TestAdd (0.00s)
PASS
```

