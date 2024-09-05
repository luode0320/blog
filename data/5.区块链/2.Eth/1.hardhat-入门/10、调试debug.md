# debug调试

如果你不愿意一直写脚本测试, 我们提供了一个 自动化 html 页面模拟 `remix` 的调试流程.可以利用这个自动生成的 html 进行可视化调试.

<img src="../../../picture/image-20240902032805880.png" alt="image-20240902032805880"  />

## 调试准备阶段:

在调试之前, 请在 vscode 安装一个 http 服务器的插件 `Live Server`.

安装完成之后会在右下角有一个 `Go Live` 按钮, 点击之后会生成一个 `http://localhost:5500` 的服务.

## 启动一个网络节点

新开一个终端执行:

```shell
yarn hardhat node
```

## 部署合约到本地网络

你可以不编写调用合约部分的代码, 直接部署合约到本地网络.

```shell
yarn hardhat run scripts/deploy.ts --network localhost
```

## Live Server 调试

点击右下角  `Go Live` 按钮, 自动加载 `index.html` 页面(或者手动选择此 `index.html` 后在点击按钮) 进行调试.

Live Server 启动一次可以多次使用, 只要是同一个路径的  `index.html` , 修改后会热部署 html, 不用重复启动。

