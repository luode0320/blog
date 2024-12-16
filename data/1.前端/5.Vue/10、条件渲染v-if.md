## 条件渲染

## `v-if`

`v-if` 指令用于条件性地渲染一块内容。这块内容只会在指令的表达式返回真值时才被渲染。

```vue
<h1 v-if="awesome">Vue is awesome!</h1>
```

## `v-else`

你也可以使用 `v-else` 为 `v-if` 添加一个“else 区块”。

```vue
/ * !awesome 取的是 awesome 变量的布尔值的反向值，然后将这个值重新赋给 awesome, 这样就会形成点击状态同时变化 */
<button @click="awesome = !awesome">Toggle</button>

<h1 v-if="awesome">Vue is awesome!</h1>
<h1 v-else>Oh no 😢</h1>
```

一个 `v-else` 元素必须跟在一个 `v-if` 或者 `v-else-if` 元素后面，否则它将不会被识别。

## `v-else-if`

顾名思义，`v-else-if` 提供的是相应于 `v-if` 的“else if 区块”。它可以连续多次重复使用：

```vue
<div v-if="type === 'A'">
  A
</div>
<div v-else-if="type === 'B'">
  B
</div>
<div v-else-if="type === 'C'">
  C
</div>
<div v-else>
  Not A/B/C
</div>
```

和 `v-else` 类似，一个使用 `v-else-if` 的元素必须紧跟在一个 `v-if` 或一个 `v-else-if` 元素后面。

## `<template>` 上的 `v-if`

因为 `v-if` 是一个指令，他必须依附于某个元素。但如果我们想要切换不止一个元素呢？

在这种情况下我们可以在一个 `<template>` 元素上使用 `v-if`，这只是一个不可见的包装器元素，最后渲染的结果并不会包含这个 `<template>` 元素。

```vue
<template v-if="ok">
  <h1>Title</h1>
  <p>Paragraph 1</p>
  <p>Paragraph 2</p>
</template>
```

`v-else` 和 `v-else-if` 也可以在 `<template>` 上使用。

在 Vue 中，`<template>` 是一个 **虚拟元素**，它本身不会被渲染到 DOM 中，但可以作为一个容器来包含多个元素。

- 它的作用类似于一个 **逻辑容器**，可以帮助你组织模板中的多个元素，而不产生额外的 DOM 节点。

- `<template>` 标签本身 **不会被渲染成 HTML 元素**，而是仅仅作为一个容器，允许你在 Vue 模板中包裹多个子元素。
- 它特别适用于需要 **条件渲染** 或 **循环渲染** 的场景，因为你不能直接在 Vue 的模板中使用多个根元素，但是可以使用 `<template>` 来解决这个问题。

上续的例子中: 

- `<template v-if="ok">` 包裹了三个元素（`<h1>` 和两个 `<p>` 标签），当 `ok` 为 `true` 时，这三个元素会被渲染到 DOM 中；当 `ok` 为 `false` 时，三个元素都不会被渲染到 DOM 中。

- 由于 `<template>` 标签本身不会渲染为 DOM 元素，因此不会在 HTML 中出现 `<template>` 标签，它只作为 Vue 内部的一个逻辑容器。



## `v-show`

另一个可以用来按条件显示一个元素的指令是 `v-show`。其用法基本一样：

```vue
<h1 v-show="ok">Hello!</h1>
```

不同之处在于 `v-show` 会在 DOM 渲染中保留该元素；`v-show` 仅切换了该元素上名为 `display` 的 CSS 属性。

`v-show` 不支持在 `<template>` 元素上使用，也不能和 `v-else` 搭配使用。



## `v-if`  vs. `v-show`

`v-if` 是“真实的”按条件渲染，因为它确保了在切换时，条件区块内的事件监听器和子组件都会被销毁与重建。

`v-if` 也是**惰性**的：如果在初次渲染时条件值为 false，则不会做任何事。条件区块只有当条件首次变为 true 时才被渲染。

相比之下，`v-show` 简单许多，元素无论初始条件如何，始终会被渲染，只有 CSS `display` 属性会被切换。

总的来说，`v-if` 有更高的切换开销，而 `v-show` 有更高的初始渲染开销。

因此，如果需要频繁切换，则使用 `v-show` 较好；如果在运行时绑定条件很少改变，则 `v-if` 会更合适。



## `v-if` 和 `v-for`

> 同时使用 `v-if` 和 `v-for` 是**不推荐的**，因为这样二者的优先级不明显。请查看[风格指南](https://cn.vuejs.org/style-guide/rules-essential.html#avoid-v-if-with-v-for)获得更多信息。

当 `v-if` 和 `v-for` 同时存在于一个元素上的时候，`v-if` 会首先被执行。请查看[列表渲染指南](https://cn.vuejs.org/guide/essentials/list.html#v-for-with-v-if)获取更多细节。.