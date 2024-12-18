# 原生 DOM 事件详解

在 Web 开发中，**DOM 事件**（Document Object Model Events）是用户与网页交互时触发的一些行为。

原生 DOM 事件是浏览器提供的标准事件机制，用于监听和处理用户在页面上的各种交互操作，如点击、键盘按键、鼠标移动等。

本文将介绍原生 DOM 事件的基础知识、常用的事件类型以及如何通过 JavaScript 处理这些事件。

## 什么是 DOM 事件？

DOM 事件是 JavaScript 提供的一种机制，允许开发者在 Web 页面的元素上监听和响应用户的交互。

例如，点击按钮、鼠标悬停、表单提交等操作都可以触发相应的事件。

### 事件对象

当一个事件被触发时，浏览器会自动创建一个 **事件对象**，并将其传递给事件处理函数。

事件对象包含了与事件相关的详细信息，例如事件类型、触发事件的目标元素、鼠标的坐标等。

在事件处理函数中，可以通过参数获取这个事件对象。

```js
function handleClick(event) {
  console.log(event)  // 输出事件对象
}
```

### 事件处理函数中的 `event` 参数

事件处理函数的第一个参数通常是 `event`（也可能是 `e`，视浏览器而定）。该参数是一个原生事件对象，包含了事件发生时的所有相关信息。

例如，在 `click` 事件中，`event` 对象会包含：

- 事件类型 (`event.type`)
- 触发事件的元素 (`event.target`)
- 鼠标的 X、Y 坐标 (`event.clientX`, `event.clientY`)
- 键盘的按键代码（对于 `keydown` 和 `keyup` 事件）

## 常见的原生 DOM 事件类型

以下是一些常见的原生 DOM 事件类型及其描述：

### 鼠标事件

- `click`：鼠标点击事件
- `dblclick`：鼠标双击事件
- `mousedown`：鼠标按下事件
- `mouseup`：鼠标释放事件
- `mouseover`：鼠标指针悬停在元素上时触发
- `mouseout`：鼠标指针离开元素时触发
- `mousemove`：鼠标在元素上移动时触发

### 键盘事件

- `keydown`：按下键盘上的任意键时触发
- `keypress`：按下并保持按键时触发
- `keyup`：释放键盘上的键时触发

### 表单事件

- `submit`：表单提交时触发
- `input`：输入框内容变化时触发
- `change`：表单控件的值发生改变时触发
- `focus`：元素获得焦点时触发
- `blur`：元素失去焦点时触发

### 触摸事件（针对移动设备）

- `touchstart`：手指触摸屏幕时触发
- `touchend`：手指离开屏幕时触发
- `touchmove`：手指在屏幕上移动时触发

## 事件监听与绑定

### 1. 通过 `addEventListener` 绑定事件

`addEventListener` 是一种标准的事件绑定方法，允许我们将事件处理函数与 DOM 元素关联起来。它的语法如下：

```js
element.addEventListener(eventType, callback, useCapture);
```

`eventType`：事件的类型，如 `'click'`, `'keydown'` 等。

`callback`：事件发生时要执行的回调函数。

`useCapture`（可选）：是否在捕获阶段执行事件处理函数，默认为 `false`，即在冒泡阶段执行。

```js
const button = document.getElementById('myButton');
button.addEventListener('click', function(event) {
  alert('Button clicked!');
});
```

### 2. 通过事件属性绑定事件（不推荐）

你也可以通过直接设置 HTML 元素的事件属性来绑定事件，这种方式被称为内联事件绑定。例如：

```html
<button onclick="alert('Button clicked!')">Click Me</button>
```

然而，内联事件绑定存在一些问题，比如无法解绑事件、代码不够灵活等。因此，推荐使用 `addEventListener` 来绑定事件。

## 事件传播

在浏览器中，事件的传播分为两个阶段：

1. **捕获阶段**：事件从 `document` 开始，逐层向下传递到目标元素。
2. **冒泡阶段**：事件从目标元素开始，逐层向上传递到 `document`。

### 事件冒泡

默认情况下，事件是沿着 DOM 树进行冒泡的。也就是说，当一个元素触发事件时，这个事件会逐步向上传播到其父元素，直到 `document` 为止。

```js
document.getElementById('parent').addEventListener('click', function() {
  alert('Parent clicked');
});
document.getElementById('child').addEventListener('click', function() {
  alert('Child clicked');
});
```

当你点击子元素时，`child` 元素的 `click` 事件会先触发，然后冒泡到 `parent` 元素，触发其 `click` 事件。

### 阻止事件传播

你可以通过调用 `event.stopPropagation()` 来阻止事件的传播，这样事件将不会冒泡到父元素或捕获阶段。

```js
document.getElementById('child').addEventListener('click', function(event) {
  alert('Child clicked');
  event.stopPropagation();  // 阻止冒泡
});
```

### 阻止默认行为

某些事件（如 `submit` 或 `a` 标签的点击）会触发浏览器的默认行为。

你可以通过调用 `event.preventDefault()` 来阻止这些默认行为。

```js
document.getElementById('form').addEventListener('submit', function(event) {
  event.preventDefault();  // 阻止表单提交
  alert('Form submission prevented!');
});
```

阻止默认行为是指 **阻止浏览器对某些事件执行它的默认操作**。每当用户在网页上触发某些事件时，浏览器通常会自动执行一些预定义的动作。例如：

- **点击链接 (`<a>` 标签)**：浏览器默认会导航到 `href` 属性指定的 URL。
- **提交表单 (`<form>` 标签)**：浏览器默认会将表单数据提交到指定的 `action` URL。
- **按下回车键**：在表单的输入框中，按下回车通常会触发表单的提交。
- **右键点击**：浏览器默认会弹出右键菜单。

通过调用 `event.preventDefault()`，我们可以阻止这些浏览器的默认行为，通常用于自定义操作或者防止不必要的页面刷新或导航。

#### 1. **阻止表单提交**

表单的 `submit` 事件默认会触发表单的提交行为，也就是将表单数据发送到服务器。如果你希望在提交之前先进行一些自定义验证或操作，可以使用 `event.preventDefault()` 来阻止表单提交。

```html
<form id="myForm">
  <input type="text" id="name" placeholder="Enter your name">
  <button type="submit">Submit</button>
</form>

<script>
  document.getElementById('myForm').addEventListener('submit', function(event) {
    event.preventDefault();  // 阻止表单的默认提交行为
    alert('Form submission prevented!');

    // 这里可以进行自定义的表单验证或其他操作
    const name = document.getElementById('name').value;
    if (name.trim() === '') {
      alert('Name is required!');
    } else {
      alert('Form submitted with name: ' + name);
    }
  });
</script>
```

在这个例子中，点击 "Submit" 按钮时，表单的提交行为被阻止，弹出 `Form submission prevented!`，然后可以执行一些自定义的操作（例如验证输入框内容）

#### 2. **阻止链接的默认跳转**

如果你点击一个链接（`<a>` 标签），浏览器默认会根据 `href` 属性的值跳转到对应的页面。

如果你希望在点击链接时执行其他操作（比如发送 Ajax 请求），而不进行页面跳转，可以使用 `event.preventDefault()`。

```html
<a href="https://www.example.com" id="myLink">Go to Example</a>

<script>
  document.getElementById('myLink').addEventListener('click', function(event) {
    event.preventDefault();  // 阻止默认的链接跳转行为
    alert('Link click prevented!');
    
    // 可以在这里执行其他操作，比如发送 Ajax 请求等
  });
</script>
```

在这个例子中，当点击链接时，浏览器不会跳转到 `https://www.example.com`，而是弹出 `Link click prevented!` 提示。



## 事件对象的常用属性

在事件处理函数中，`event` 对象包含了大量有用的信息。以下是一些常用的属性：

- `event.target`：事件目标，即触发事件的 DOM 元素。
- `event.type`：事件的类型（例如 `'click'`, `'keydown'`）。
- `event.clientX` / `event.clientY`：鼠标指针相对于浏览器视口的位置。
- `event.key`：按下的键（对于 `keydown` 或 `keyup` 事件）。
- `event.altKey` / `event.ctrlKey` / `event.shiftKey`：在按下修饰键（如 `Alt`, `Ctrl`, `Shift`）时返回 `true` 或 `false`。

## 小结

原生 DOM 事件是网页开发中处理用户交互的重要机制。理解事件对象、事件绑定、事件传播以及如何控制事件的默认行为和传播方式，是每个开发者的必备技能。

### 小提示

- 推荐使用 `addEventListener` 绑定事件，这种方式更具灵活性，支持解绑事件。
- 理解事件传播机制（捕获和冒泡）有助于处理更复杂的事件交互。
- 使用 `event.preventDefault()` 和 `event.stopPropagation()` 控制事件的默认行为和传播，避免不必要的副作用。