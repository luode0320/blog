# 模板语法

Vue 使用一种基于 HTML 的模板语法，使我们能够声明式地将其组件实例的数据绑定到呈现的 DOM 上。

所有的 Vue 模板都是语法层面合法的 HTML，可以被符合规范的浏览器和 HTML 解析器解析。

 

## 文本插值{{}}

最基本的数据绑定形式是文本插值，它使用的是“Mustache”语法 (即双大括号)：

```html
<span>使用文本插值: {{ msg }}</span>
```

双大括号标签会被替换为相应组件实例中 `msg` 属性的值(下一章会讲到)。同时每次 `msg` 属性更改时它也会同步更新。



## 原始 HTML v-html

双大括号会将数据解释为纯文本，而不是 HTML。若想插入 HTML，你需要使用 `v-html` 指令：

```html
<p>使用文本插值: {{ rawHtml }}</p>
<p>使用v-html指令: <span v-html="rawHtml"></span></p>
```

这里我们遇到了一个新的概念。

- 这里看到的 `v-html` 被称为一个**指令**。
- 指令由 `v-` 作为前缀，表明它们是一些由 Vue 提供的特殊 attribute 属性，你可能已经猜到了，它们将为渲染的 DOM 应用特殊的响应式行为。
- 这里我们做的事情简单来说就是：在当前组件实例上，将此元素的 innerHTML 与 `rawHtml` 值保持同步。

`span` 的内容将会被替换为 `rawHtml` 的值，插值为纯 HTML 格式。



## Attribute (元素)绑定v-bind

双大括号不能在 HTML attributes (元素)中使用。想要响应式地绑定一个 attribute (元素)，应该使用 `v-bind` 指令：

```vue
<div v-bind:id="dynamicId"></div>
```

`v-bind` 指令指示 Vue 将元素的 `id` attribute 与组件的 `dynamicId` 值保持一致。

如果绑定的值是 `null` 或者 `undefined`，那么该 attribute 将会从渲染的元素上移除。

因为 `v-bind` 非常常用，我们提供了特定的简写语法：

```vue
<div :id="dynamicId"></div>
```

如果 attribute 的名称与绑定的 JavaScript 值的名称相同，那么可以进一步简化语法，省略 attribute 值：

```vue
<!-- 与 :id="id" 相同 -->
<div :id></div>

<!-- 这也同样有效 -->
<div v-bind:id></div>
```

这与在 JavaScript 中声明对象时使用的属性简写语法类似。请注意，这是一个**只在 Vue 3.4 及以上版本**中可用的特性。

## 动态绑定多个值v-bind

如果你有像这样的一个包含多个 attribute 的 JavaScript 对象：

```js
const objectOfAttrs = {
  id: 'container',
  class: 'wrapper',
  style: 'background-color:green'
}
```

通过不带参数的 `v-bind`，你可以将它们绑定到单个元素上：

```vue
<div v-bind="objectOfAttrs"></div>
```

理解 `v-bind` 的不同用法确实可能有些混淆，尤其是当你从单个属性绑定转向多个属性的动态绑定时。

- `:id` 是 `v-bind:id` 的简写形式，它告诉 Vue 将 `dynamicId` 的值绑定到 `<div>` 元素的 `id` 属性上。

- 如果你有多个属性需要单独绑定，你可以重复这个过程：

  ```vue
  <div :id="dynamicId" :class="dynamicClass" :style="dynamicStyle">
  </div>
  ```

然而，当你要绑定很多属性时，代码会变得冗长且难以维护。

这时，Vue 提供了 `v-bind` 不带参数的形式，可以一次性绑定一个对象中的所有属性。

这不仅简化了代码，还提高了可读性, 当然和一个一个效果写是一样的。

```vue
<div v-bind="objectOfAttrs"></div>
```

## 布尔型 Attribute

布尔型 attribute 依据 true / false 值来决定 attribute 是否应该存在于该元素上。`disabled` 就是最常见的例子之一。

`v-bind` 在这种场景下的行为略有不同：

```vue
<button :disabled="isButtonDisabled">Button</button>
```

当 `isButtonDisabled` **为 真值 或一个空字符串** (即 `<button disabled="">`) 时，元素会包含这个 `disabled` attribute 元素。

而当其为其他 假值 时 attribute 将被忽略。

## 使用 JavaScript 表达式

至此，我们仅在模板中绑定了一些简单的属性名。但是 Vue 实际上在所有的数据绑定中都支持完整的 JavaScript 表达式：

```vue
{{ number + 1 }}

{{ ok ? 'YES' : 'NO' }}

{{ message.split('').reverse().join('') }}

<div :id="`list-${id}`"></div>
```

这些表达式都会被作为 JavaScript ，以当前组件实例为作用域解析执行。

在 Vue 模板内，JavaScript 表达式可以被使用在如下场景上：

- 在文本插值中 (双大括号)
- 在任何 Vue 指令 (以 `v-` 开头的特殊 attribute) attribute 的值中



更多示例: 

### **1.文本插值**

```vue
<template>
  <div>
    <!-- 简单的数值运算 -->
    <p>{{ number + 1 }}</p>

    <!-- 条件判断 -->
    <p>{{ ok ? 'YES' : 'NO' }}</p>

    <!-- 字符串操作 -->
    <p>{{ message.split('').reverse().join('') }}</p>

    <!-- 使用三元运算符 -->
    <p>{{ age >= 18 ? '成年人' : '未成年人' }}</p>

    <!-- 调用方法 -->
    <p>{{ greetUser(name) }}</p>
  </div>
</template>

<script setup>
<!-- ref后续会讲, 其实就类似一个初始化new函数 -->
import { ref } from 'vue'

const number = ref(1)
const ok = ref(true)
const message = ref('Hello')
const age = ref(20)
const name = ref('Alice')

function greetUser(user) {
  return `你好, ${user}`
}
</script>
```

### 2. **属性绑定**

```vue
<template>
  <div>
    <!-- 动态 ID -->
    <div :id="`list-${id}`"></div>

    <!-- 动态类名 -->
    <div :class="{ active: isActive, 'text-danger': hasError }"></div>

    <!-- 动态样式 -->
    <div :style="{ color: activeColor, fontSize: fontSize + 'px' }"></div>

    <!-- 绑定布尔属性 -->
    <input type="text" v-bind:disabled="isDisabled">
  </div>
</template>

<script setup>
<!-- ref后续会讲, 其实就类似一个初始化new函数 -->
import { ref } from 'vue'

const id = ref(1)
const isActive = ref(true)
const hasError = ref(false)
const activeColor = ref('green')
const fontSize = ref(16)
const isDisabled = ref(true)
</script>
```

## 仅支持表达式

每个绑定仅支持**单一表达式**，也就是一段能够被求值的 JavaScript 代码。

**一个简单的判断方法是是否可以合法地写在 `return` 后面。**

因此，下面的例子都是**无效**的：

```vue
<!-- 这是一个语句，而非表达式 -->
{{ var a = 1 }}

<!-- 条件控制也不支持，请使用三元表达式 -->
{{ if (ok) { return message } }}
```

## 调用函数toTitleDate(date)

可以在绑定的表达式中使用一个组件暴露的方法：

```vue
<time :title="toTitleDate(date)" :datetime="date">
  {{ formatDate(date) }}
</time>
```

## 受限的全局访问

模板中的表达式将被沙盒化，仅能够访问到有限的全局对象列表。

该列表中会暴露常用的内置全局对象，比如 `Math` 和 `Date`。

没有显式包含在列表中的全局对象将不能在模板内表达式中访问，例如用户附加在 `window` 上的属性。

然而，你也可以自行在 `app.config.globalProperties`上显式地添加它们，供所有的 Vue 表达式使用。

## 指令 Directives

指令是带有 `v-` 前缀的特殊 attribute。Vue 提供了许多[内置指令](https://cn.vuejs.org/api/built-in-directives.html)，包括上面我们所介绍的 `v-bind` 和 `v-html`。

指令 attribute 属性的期望值为一个 JavaScript 表达式 (除了少数几个例外，即之后要讨论到的 `v-for`、`v-on` 和 `v-slot`)。

一个指令的任务是在其表达式的值变化时响应式地更新 DOM。

以 [`v-if`](https://cn.vuejs.org/api/built-in-directives.html#v-if) 为例：

```vue
<p v-if="seen">Now you see me</p>
```

这里，`v-if` 指令会基于表达式 `seen` 的值的真假来移除/插入该 `<p>` 元素。

## 参数 Arguments

某些指令会需要一个“参数”，在指令名后通过一个冒号隔开做标识。

例如用 `v-bind` 指令来响应式地更新一个 HTML attribute：

```vue
<a v-bind:href="url"> ... </a>

<!-- 简写 -->
<a :href="url"> ... </a>
```

这里 `href` 就是一个参数，它告诉 `v-bind` 指令将表达式 `url` 的值绑定到元素的 `href` attribute 上。

在简写中，参数前的一切 (例如 `v-bind:`) 都会被缩略为一个 `:` 字符。

另一个例子是 `v-on` 指令，它将监听 DOM 事件：

```vue
<a v-on:click="doSomething"> ... </a>

<!-- 简写 -->
<a @click="doSomething"> ... </a>
```

这里的参数是要监听的事件名称：`click`。

`v-on` 有一个相应的缩写，即 `@` 字符。我们之后也会讨论关于事件处理的更多细节。



## 动态参数[attributeName]

同样在指令参数上也可以使用一个 JavaScript 表达式，需要包含在一对方括号内：

```vue
<!--
注意，参数表达式有一些约束，
参见下面“动态参数值的限制”与“动态参数语法的限制”解释
-->
<a v-bind:[attributeName]="url"> ... </a>

<!-- 简写 -->
<a :[attributeName]="url"> ... </a>
```

这里的 `attributeName` 会作为一个 JavaScript 表达式被动态执行，计算得到的值会被用作最终的参数。

举例来说，如果你的组件实例有一个数据属性 `attributeName`，其值为 `"href"`，那么这个绑定就等价于 `v-bind:href`。

相似地，你还可以将一个函数绑定到动态的事件名称上：

```vue
<a v-on:[eventName]="doSomething"> ... </a>

<!-- 简写 -->
<a @[eventName]="doSomething"> ... </a>
```

在此示例中，当 `eventName` 的值是 `"focus"` 时，`v-on:[eventName]` 就等价于 `v-on:focus`。



## 动态参数值的限制

动态参数中表达式的值应当是一个字符串，或者是 `null`。特殊值 `null` 意为显式移除该绑定。其他非字符串的值会触发警告。

## 动态参数语法的限制

动态参数表达式因为某些字符的缘故有一些语法限制，比如空格和引号，在 HTML attribute 名称中都是不合法的。例如下面的示例：

```vue
<!-- 这会触发一个编译器警告 -->
<a :['foo' + bar]="value"> ... </a>
```

如果你需要传入一个复杂的动态参数，我们推荐使用[计算属性](https://cn.vuejs.org/guide/essentials/computed.html)替换复杂的表达式，也是 Vue 最基础的概念之一，我们很快就会讲到。

当使用 DOM 内嵌模板 (直接写在 HTML 文件里的模板) 时，我们需要避免在名称中使用大写字母，因为**浏览器会强制将其转换为小写**：

```vue
<a :[someAttr]="value"> ... </a>
```

上面的例子将会在 DOM 内嵌模板中被转换为 `:[someattr]`。

如果你的组件拥有 “someAttr” 属性而非 “someattr”，这段代码将不会工作。单文件组件内的模板**不**受此限制。

可以使用 `-`, `_`不推荐使用下划线



### 修饰符 Modifiers

修饰符是以点开头的特殊后缀，表明指令需要以一些特殊的方式被绑定。

例如 `.prevent` 修饰符会告知 `v-on` 指令对触发的事件调用 `event.preventDefault()`：

```vue
<form @submit.prevent="onSubmit">...</form>
```

`preventDefault()`主要用于阻止默认行为，例如表单提交时页面刷新或链接跳转。

### 其他常用的事件修饰符

除了 `.prevent`，Vue 还提供了其他一些有用的事件修饰符：

- **`.stop`**：调用 `event.stopPropagation()`，阻止事件冒泡。
- **`.capture`**：添加事件侦听器为捕获模式。
- **`.self`**：只有当事件是从侦听器绑定的元素本身触发时才触发回调。
- **`.once`**：只触发一次事件。
- **`.passive`**：以被动的方式监听事件，提高滚动性能。

```vue
<!-- 阻止默认行为并且阻止事件冒泡 -->
<a href="https://example.com" @click.prevent.stop="doSomething">链接</a>
```

