# 关注的性能指标

- CPU 使用情况
- 内存 使用情况
- I/O 使用情况
- goroutine 使用情况: 阻塞
- 锁 使用情况: 死锁

# 工具

## `pprof`性能分析工具包

示例: `https://github.com/luode0320/go-pprof.git`

```go
package main

import (
	"log"
	"net/http"
	_ "net/http/pprof"
	"os"
	"runtime"
	"time"

	"github.com/wolfogre/go-pprof-practice/animal"
)

func main() {
	log.SetFlags(log.Lshortfile | log.LstdFlags)
	log.SetOutput(os.Stdout)

	runtime.SetMutexProfileFraction(1) // 开启锁跟踪
	runtime.SetBlockProfileRate(1)     // 开启阻塞跟踪

	// 通过web采集: http://localhost:6060/debug/pprof/
	go func() {
		if err := http.ListenAndServe(":6060", nil); err != nil {
			log.Fatal(err)
		}
		os.Exit(0)
	}()

	for {
		for _, v := range animal.AllAnimals {
			v.Live()
		}
		time.Sleep(time.Second)
	}
}
```

![image-20240807012932756](../../../picture/image-20240807012932756.png)

## go自带性能分析工具

cmd命令行执行

```cmd
go tool pprof -h
```

![image-20240807012805686](../../../picture/image-20240807012805686.png)

# 使用

## 进入命令行交互

```cmd
go tool pprof http://localhost:6060/debug/pprof/allocs // 所有情况
go tool pprof http://localhost:6060/debug/pprof/block // 阻塞情况
go tool pprof http://localhost:6060/debug/pprof/goroutine // goroutine情况
go tool pprof http://localhost:6060/debug/pprof/heap // 堆情况
go tool pprof http://localhost:6060/debug/pprof/mutex // 锁情况
go tool pprof http://localhost:6060/debug/pprof/profile // cpu情况
go tool pprof http://localhost:6060/debug/pprof/threadcreate // 线程创建情况
go tool pprof http://localhost:6060/debug/pprof/trace // 线程创建情况
```

![image-20240807013031526](../../../picture/image-20240807013031526.png)

## `help`: 帮助指令![image-20240807013159075](../../../picture/image-20240807013159075.png)

```sh
callgrind:	输出调用图（call graph）到 Callgrind 格式。
comments:	输出所有的性能分析注释。
disasm:		输出带有样本注解的汇编代码清单。
dot:		输出调用图到 DOT 图形格式。
eog:		使用 eog 查看器可视化图形。
evince:		使用 evince 查看器可视化图形。
gif:		输出调用图到 GIF 图像格式。
gv:			使用 gv 查看器可视化图形。
kcachegrind:使用 KCachegrind 可视化报告。
list:		输出与正则表达式匹配的函数的带注解的源代码。
pdf:		输出调用图到 PDF 格式。
peek:		输出与正则表达式匹配的函数的调用者和被调用者。
png:		输出调用图到 PNG 图像格式。
proto:		输出性能分析数据到压缩的 Protocol Buffers 格式。
ps:			输出调用图到 PostScript (PS) 格式。
raw:		输出原始性能分析数据的文本表示。
svg:		输出调用图到 SVG 格式。
tags:		输出性能分析中的所有标签。
text:		输出排名靠前的条目到文本格式。
top:		输出排名靠前的条目到文本格式（与 text 命令相同）。
topproto:	输出排名靠前的条目到压缩的 Protocol Buffers 格式。
traces:		输出所有性能分析样本到文本格式。
tree:		输出调用图的文本渲染。
web:		通过 Web 浏览器可视化图形。
weblist:	在 Web 浏览器中显示带注解的源代码。
o/options:	列出选项及其当前值。
q/quit/exit/^D:退出 pprof。
```

## `top`: 查看前10条, 内存倒序

反映运行过程中分配的内存，不是当前占用

![image-20240807013255841](../../../picture/image-20240807013255841.png)

flat：该函数直接分配的内存。

flat%：该函数直接分配的内存占总内存的百分比。

sum%：从顶部累加到当前行的内存百分比。

cum：该函数及其调用链（包括子函数）总共分配的内存。

cum%：累计内存占总内存的百分比。

函数名：内存分配的来源。



## `cpu`: 分析

```sh
# 采集30s
go tool pprof http://localhost:6060/debug/pprof/profile?seconds=30

# 打开
go tool pprof cpu.prof

# 分析
top 10
```

```
(pprof) top 10 
Showing nodes accounting for 5990ms, 58.16% of 10300ms total
Dropped 82 nodes (cum <= 51.50ms)
Showing top 10 nodes out of 60
      flat  flat%   sum%        cum   cum%
    2090ms 20.29% 20.29%     2090ms 20.29%  runtime.stdcall6
     830ms  8.06% 28.35%     3990ms 38.74%  runtime.stealWork
     660ms  6.41% 34.76%      660ms  6.41%  runtime.stdcall1
     550ms  5.34% 40.10%      550ms  5.34%  runtime.(*randomEnum).next
     410ms  3.98% 44.08%     2640ms 25.63%  runtime.runtimer
     370ms  3.59% 47.67%      370ms  3.59%  runtime.(*randomOrder).start
     320ms  3.11% 50.78%      320ms  3.11%  runtime.pMask.read
     310ms  3.01% 53.79%     3240ms 31.46%  runtime.checkTimers
     250ms  2.43% 56.21%      950ms  9.22%  runtime.send
     200ms  1.94% 58.16%      210ms  2.04%  time.Now
```



## `内存`: 分析

```sh
# 采集 -sample_index=alloc_space 表示分析累计分配的内存（默认是当前占用 inuse_space）
go tool pprof -sample_index=inuse_space http://localhost:6060/debug/pprof/heap

# 打开
go tool pprof heap.prof
# 累计分配内存（包括已释放的）
go tool pprof -sample_index=alloc_space heap.prof
# 当前占用内存（未被 GC 释放的）
go tool pprof -sample_index=inuse_space heap.prof
```

```sh
(pprof) top 10
Showing nodes accounting for 332.63MB, 96.18% of 345.86MB total
Dropped 100 nodes (cum <= 1.73MB)
Showing top 10 nodes out of 50
      flat  flat%   sum%        cum   cum%
   82.08MB 23.73% 23.73%   159.19MB 46.03%  ellipal_finance/app/exchange/provider/changenow.(*exchangeProvider).UpdatePairsTask
   61.11MB 17.67% 41.40%    61.11MB 17.67%  reflect.growslice
      51MB 14.75% 56.15%       51MB 14.75%  encoding/json.(*decodeState).literalStore
   40.51MB 11.71% 67.86%    40.51MB 11.71%  reflect.New
   33.04MB  9.55% 77.41%    33.04MB  9.55%  bytes.growSlice
   32.89MB  9.51% 86.92%    32.89MB  9.51%  ellipal_finance/app/exchange/service.(*ExchangeService).mergeMaps
   22.56MB  6.52% 93.45%    55.08MB 15.93%  ellipal_finance/app/exchange/provider/changelly.(*exchangeProvider).UpdatePairsTask
       4MB  1.16% 94.60%        4MB  1.16%  ellipal_finance/app/exchange/provider/changenow.GenChangeNowExchangeKey
    2.93MB  0.85% 95.45%     3.93MB  1.14%  ellipal_finance/app/exchange/service.(*ExchangeService).SavePriceFromProvider
    2.51MB  0.73% 96.18%     2.51MB  0.73%  ellipal_finance/app/exchange/provider/swft.(*exchangeProvider).UpdatePairsTask
```



### `gc`: 分析gc暂停时间



## `list`: 看指定源代码内存占用

![image-20240807013608774](../../../picture/image-20240807013608774.png)



## `web`: 下载svg

`Graphviz` 是一个用于绘制图形和网络图的工具，`pprof` 使用 `Graphviz` 的 `dot` 工具来生成可视化的火焰图和其他类型的图表。

#### 1. 安装 `Graphviz`

确保您已经安装了 `Graphviz`。以下是在不同操作系统上安装 `Graphviz` 的方法：

- **Ubuntu/Debian**

```bash
sudo apt-get update
sudo apt-get install graphviz
```

- **CentOS/RHEL**

```bash
sudo yum install graphviz
```

- **macOS** (使用 Homebrew)

```bash
brew install graphviz
```

- **Windows**
    - 访问 [Graphviz 官方网站](https://graphviz.org/download/) 下载 Windows 安装包。
    - 安装后，确保将 `Graphviz` 的安装目录添加到系统的 `PATH` 环境变量中。

#### 2. 添加 `Graphviz` 到 `PATH`

确保 `Graphviz` 的 `dot` 可执行文件位于系统路径中。通常，安装完成后 `dot` 会在某个目录下，例如 `/usr/bin`
或 `/usr/local/bin`。

**Linux/macOS**: 如果 `dot` 不在默认路径中，您可以通过以下命令找到它：

```bash
which dot
```

如果找不到，您需要手动将 `dot` 的路径添加到 `PATH` 中。例如，如果 `dot` 的路径是 `/usr/local/bin/dot`
，您可以编辑 `~/.bashrc` 或 `~/.zshrc` 文件（取决于您使用的 shell），并添加以下行：

```bash
export PATH=/usr/local/bin:$PATH
```

然后运行 `source ~/.bashrc` 或 `source ~/.zshrc` 使更改生效。

**Windows**: 如果您在 Windows 上安装了 `Graphviz`，请确保将 `Graphviz` 的安装目录添加到 `PATH`
环境变量中。通常安装过程中会有提示是否添加到 `PATH`，如果没有，您需要手动添加。

#### 测试 `Graphviz` 是否正确安装

```bash
dot -V
```

![image-20240807014851765](../../../picture/image-20240807014851765.png)

#### 下载svg

![image-20240807015351890](../../../picture/image-20240807015351890.png)

- 浏览器自动打开

![image-20240807015411396](../../../picture/image-20240807015411396.png)

- 框框越大, 线越粗, 问题越大

# 总结

操作方式很简单。

1. 选择一个分析的情况命令行进入

```sh
go tool pprof http://localhost:6060/debug/pprof/allocs // 所有情况
go tool pprof http://localhost:6060/debug/pprof/block // 阻塞情况
go tool pprof http://localhost:6060/debug/pprof/goroutine // goroutine情况
go tool pprof http://localhost:6060/debug/pprof/heap // 堆情况
go tool pprof http://localhost:6060/debug/pprof/mutex // 锁情况
go tool pprof http://localhost:6060/debug/pprof/profile // cpu情况
go tool pprof http://localhost:6060/debug/pprof/threadcreate // 线程创建情况
go tool pprof http://localhost:6060/debug/pprof/trace // 线程创建情况
```

2. `top`命令查看情况最差的前10个
3. `list`命令查看指定源码的方法位置
4. `web`命令直接查看svg图

