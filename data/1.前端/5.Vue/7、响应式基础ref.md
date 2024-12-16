## 声明响应式状态

## `ref()`

在组合式 API 中，推荐使用 [`ref()`](https://cn.vuejs.org/api/reactivity-core.html#ref) 函数来声明响应式状态：

```js
import { ref } from 'vue'

const count = ref(0)
```

`ref()` 接收参数，并将其包裹在一个带有 `.value` 属性的 ref 对象中返回：

```js
const count = ref(0)

console.log(count) // { value: 0 }
console.log(count.value) // 0

count.value++
console.log(count.value) // 1
```

要在组件模板中访问 ref，请从组件的 `setup()` 函数中声明并返回它们( vue3 中有新的语法糖可以不用声明)：

```js
import { ref } from 'vue'

export default {
  // `setup` 是一个特殊的钩子，专门用于组合式 API。
  setup() {
    

    // 将 ref 暴露给模板
    return {
      count
    }
  }
}
```

```vue
<div>{{ count }}</div>
```

注意，在模板中使用 ref 时，我们**不**需要附加 `.value`。为了方便起见，当在模板中使用时，ref 会自动解包 (有一些[注意事项](https://cn.vuejs.org/guide/essentials/reactivity-fundamentals.html#caveat-when-unwrapping-in-templates))。

当然, 在 vue3 中有新的语法糖可以不用声明, 自动暴露给模板:

```vue
<script setup>
import { ref } from 'vue'

const count = ref(0)
</script>
```



你也可以直接在事件监听器中改变一个 ref：

```vue
<button @click="count++">
  {{ count }}
</button>
```

对于更复杂的逻辑，我们可以在同一作用域内声明更改 ref 的函数，并将它们作为方法与状态一起公开：

```vue
<script setup>
import { ref } from 'vue'

const count = ref(0)

function increment() {
    // 在 JavaScript 中需要 .value
    count.value++
}
</script>
```

然后，暴露的方法可以被用作事件监听器：

```vue
<button @click="increment">
  {{ count }}
</button>
```



### 为什么要使用 ref？

通过 getter 和 setter 方法来拦截对象属性的 get 和 set 操作。

该 `.value` 属性给予了 Vue 一个机会来检测 ref 何时被访问或修改。

在其内部，Vue 在它的 getter 中执行追踪，在它的 setter 中执行触发。

从概念上讲，你可以将 ref 看作是一个像这样的对象：

```js
// 伪代码，不是真正的实现
const myRef = {
  _value: 0,
  get value() {
    track() // 跟踪
    return this._value
  },
  set value(newValue) {
    this._value = newValue
    trigger() // 触发
  }
}
```

### 深层响应性

Ref 可以持有任何类型的值，包括深层嵌套的对象、数组或者 JavaScript 内置的数据结构，比如 `Map`。

Ref 会使它的值具有深层响应性。这意味着即使改变嵌套对象或数组时，变化也会被检测到：

```js
import { ref } from 'vue'

const obj = ref({
  nested: { count: 0 },
  arr: ['foo', 'bar']
})

function mutateDeeply() {
  // 以下都会按照期望工作
  obj.value.nested.count++
  obj.value.arr.push('baz')
}
```

非原始值将通过 [`reactive()`](https://cn.vuejs.org/guide/essentials/reactivity-fundamentals.html#reactive) 转换为响应式代理，该函数将在后面讨论。

也可以通过 [shallow ref](https://cn.vuejs.org/api/reactivity-advanced.html#shallowref) 来放弃深层响应性。



### DOM 更新时机

当你修改了响应式状态时，DOM 会被自动更新。但是需要注意的是，DOM 更新不是同步的(不是立刻更新的 	)。

Vue 会在“next tick”更新周期中缓冲所有状态的修改，以确保不管你进行了多少次状态修改，每个组件都只会被更新一次。

要等待 DOM 更新完成后再执行额外的代码，可以使用 [nextTick()](https://cn.vuejs.org/api/general.html#nexttick) 全局 API：

```js
import { nextTick } from 'vue'

async function increment() {
  count.value++
  await nextTick()
  // 现在 DOM 已经更新了
}
```

Vue 使用了一个称为“异步更新队列”的机制来优化性能。

- 当你修改响应式状态（例如改变 `ref` 或 `reactive` 对象的值）时，Vue 不会立即更新 DOM。
- 相反，它会将这些更改收集到一个队列中，并在一个合适的时机批量更新 DOM。
- 这样可以避免不必要的多次重新渲染，提高应用性能。

### “next tick” 更新周期

Vue 会在下一个“tick”中批量处理所有状态的修改。这里的“tick”指的是 JavaScript 事件循环中的一个轮次。

简单来说，Vue 会等待当前任务完成，然后在下一轮事件循环中执行 DOM 更新。



## `reactive()`

还有另一种声明响应式状态的方式，即使用 `reactive()` API。

与 `ref()` 不同，`reactive()` 直接使整个对象及其嵌套属性都具有响应性, 修改这些属性会触发相关的视图更新

在模板中使用：

```vue
<template>
  <div>
    <p>Count: {{ state.count }}</p>
    <button @click="state.count++">增加计数</button>

    <p>用户名: {{ state.user.name }}</p>
    <p>年龄: {{ state.user.age }}</p>
  </div>
</template>

<script setup>
import { reactive } from 'vue'

const state = reactive({
  count: 0,
  user: {
    name: 'Alice',
    age: 25
  }
})
</script>
```

### `reactive()` vs `ref()`

`reactive`

- **优点**：适用于复杂对象，能够深层地转换对象，使其所有嵌套属性都具有响应性。
- **缺点**：不能直接用于原始类型（如字符串、数字等），因为它们没有可拦截的属性。

`ref()`

- **优点**：可以用于原始类型（如字符串、数字等），也可以用于对象。
- **缺点**：对于对象来说，`ref()` 内部会调用 `reactive()` 来处理对象的响应性，但对于简单值（如数字、字符串），你需要通过 `.value` 访问其值。

```js
// 使用 ref()
import { ref } from 'vue'

const count = ref(0) // 必须通过 count.value 访问和修改
count.value++

// 使用 reactive()
import { reactive } from 'vue'

const state = reactive({ count: 0 }) // 可以直接访问和修改 state.count
state.count++
```

### `reactive()` 的限制

- **不能直接用于原始类型**：如果你尝试将一个原始类型（如字符串或数字）传递给 `reactive()`，它不会使其成为响应式的。

  因此，对于原始类型，你应该使用 `ref()`。

```js
import { reactive } from 'vue'
const num = reactive(1) // 这样做是没有效果的
```

- **不可变性**：一旦使用 `reactive()` 创建了一个响应式对象，你不应该再将其替换为另一个对象。相反，应该修改现有的对象属性。



值得注意的是，`reactive()` 返回的是一个原始对象的 [Proxy](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Proxy)，它和原始对象是不相等的：

```js
import { reactive } from 'vue'
const raw = {}
const proxy = reactive(raw)

// 代理对象和原始对象不是全等的
console.log(proxy === raw) // false
```

只有代理对象是响应式的，更改原始对象不会触发更新。因此，使用 Vue 的响应式系统的最佳实践是**仅使用你声明对象的代理版本**。

为保证访问代理的一致性，对同一个原始对象调用 `reactive()` 会总是返回同样的代理对象，而对一个已存在的代理对象调用 `reactive()` 会返回其本身：

```js
import { reactive } from 'vue'
const raw = {}
const proxy = reactive(raw)

// 在同一个对象上调用 reactive() 会返回相同的代理
console.log(reactive(raw) === proxy) // true

// 在一个代理上调用 reactive() 会返回代理它自己(也就是单例的)
console.log(reactive(proxy) === proxy) // true
```

这个规则对嵌套对象也适用。依靠深层响应性，响应式对象内的嵌套对象依然是代理：

```js
const proxy = reactive({})

const raw = {}
proxy.nested = raw // 就算是赋值, 比较时获取出来的 nested 也会是一个被代理的对象 

console.log(proxy.nested === raw) // false
```

### `reactive()` 的局限性

`reactive()` API 有一些局限性：

1. **有限的值类型**：它只能用于对象类型 (对象、数组和如 `Map`、`Set` 这样的[集合类型](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects#keyed_collections))。它不能持有如 `string`、`number` 或 `boolean` 这样的[原始类型](https://developer.mozilla.org/en-US/docs/Glossary/Primitive)。

2. **不能替换整个对象**：由于 Vue 的响应式跟踪是通过属性访问实现的，因此我们必须始终保持对响应式对象的相同引用。

   这意味着我们不能轻易地“替换”响应式对象，因为这样的话与第一个引用的响应性连接将丢失：

   ```js
   let state = reactive({ count: 0 })
   
   // 上面的 ({ count: 0 }) 引用将不再被追踪
   // (响应性连接已丢失！)
   state = reactive({ count: 1 })
   ```

3. **对解构操作不友好**：当我们将响应式对象的原始类型属性解构为本地变量时，或者将该属性传递给函数时，我们将丢失响应性连接：

```js
const state = reactive({ count: 0 })

// 当解构时，count 已经与 state.count 断开连接
let { count } = state
// 不会影响原始的 state
count++ // 这个操作只修改了局部变量 count，不影响 state.count

// 该函数接收到的是一个普通的数字
// 并且无法追踪 state.count 的变化
// 我们必须传入整个对象以保持响应性
callSomeFunction(state.count) // 输出: 0
callSomeFunction(count) // 输出: 1
```

当你从一个 `reactive` 对象中解构出原始类型的属性（如数字、字符串等），这些解构出来的值不再是响应式的。

这是**因为它们只是原始值的副本，而不是引用**。因此，对这些副本的修改不会反映到原始的响应式对象上。

由于这些限制，我们建议使用 `ref()` 作为声明响应式状态的主要 API。



## 额外的 ref 解包细节

### 作为 reactive 对象的属性

一个 ref 会在作为响应式对象的属性被访问或修改时自动解包, 不需要 `.value` 获取

换句话说，它的行为就像一个普通的属性：

```js
const count = ref(0)
const state = reactive({
  count
})

console.log(state.count) // 0

state.count = 1
console.log(count.value) // 1
```

如果将一个新的 ref 赋值给一个关联了已有 ref 的属性，那么它会替换掉旧的 ref：

```js
const otherCount = ref(2)

state.count = otherCount
console.log(state.count) // 2
// 原始 ref 现在已经和 state.count 失去联系
console.log(count.value) // 1
```



### 数组和集合的注意事项

与 reactive 对象不同的是，当 ref 作为响应式数组或原生集合类型 (如 `Map`) 中的元素被访问时，它**不会**被解包(需要 `.value`)：

```js
const books = reactive([ref('Vue 3 Guide')])
// 这里需要 .value
console.log(books[0].value)

const map = reactive(new Map([['count', ref(0)]]))
// 这里需要 .value
console.log(map.get('count').value)
```



### 在模板中解包的注意事项

在模板渲染上下文中，只有顶级的 ref 属性才会被解包。

在下面的例子中，`count` 和 `object` 是顶级属性，但 `object.id` 不是：

```js
const count = ref(0)
const object = { id: ref(1) }
```

因此，这个表达式按预期工作：

```js
{{ count + 1 }}
```

...但这个**不会**：

```js
{{ object.id + 1 }}
```

渲染的结果将是 `[object Object]1`，因为在计算表达式时 `object.id` 没有被解包，仍然是一个 ref 对象。

为了解决这个问题，我们可以将 `id` 解构为一个顶级属性：

```js
const { id } = object
```

```js
{{ id + 1 }}
```

现在渲染的结果将是 `2`。

另一个需要注意的点是，如果 ref 是文本插值的最终计算值 (即 `{{ }}` 标签)，那么它将被解包，因此以下内容将渲染为 `1`：

```js
{{ object.id }}
```

该特性仅仅是文本插值的一个便利特性，等价于 `{{ object.id.value }}`。