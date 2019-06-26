# HDWindowLoggerSwift

![](./ReadmeImage/cocoapodTool.png)

iOS端将输出日志log悬浮显示在屏幕上，可以生成日志文件分享，便于在真机没有连接xcode的情况下调试信息。可以分享、筛选log等操作

The iOS side displays the output log log on the screen, and can generate log file sharing, which is convenient for debugging information when the real machine is not connected to xcode. Log information can be filtered and shared

### [Document for English](#english) | [Objective-C Version](https://github.com/DamonHu/HDWindowLogger)

### [中文文档](#chinese) | [Objective-C版本](https://github.com/DamonHu/HDWindowLogger)



<span id = "english"></span>

## Introduction to English


Project address: [https://github.com/DamonHu/HDWindowLoggerSwift](https://github.com/DamonHu/HDWindowLoggerSwift)

Display effect gif:

![](./ReadmeImage/demo.gif)

In addition to displaying on the screen, you can set whether to automatically scroll the log for debugging, or you can share the output log to WeChat, twitter, etc. for offline viewing. At the same time, you can search for output content, handle it yourself, etc.

![](./ReadmeImage/2.png)

## I. Installation

You can choose to install using cocoaPod, or you can download the source file directly into the project.

### 1.1, cocoaPod installation

```
pod 'HDWindowLoggerSwift'
```

### 1.2, file installation

You can drag the files in the `HDWindowLoggerSwift` folder into the project under the project.

## II. Use

Import header file

```
Import HDWindowLoggerSwift
```

### 2.1, then you can use the following functions as you like.

1, display the floating window

```
HDWindowLoggerSwift.show()
```

2, get the log information content

```
HDWindowLoggerSwift.defaultWindowLogger.mLogDataArray
```
3, according to the output type of the log to output the corresponding log, different log types are not the same color

```
HDWindowLoggerSwift.printLog(log: "mmmmmm" as AnyObject, logType: HDLogType.kHDLogTypeNormal)

///The same effect can be achieved with a simple function.
HDNormalLog(log: "mmmmmmm" as AnyObject)
```

4, delete the log

```
HDWindowLoggerSwift.cleanLog()
```

5, hide the entire log window

```
HDWindowLoggerSwift.hide()
```

6, only hide the log output window

```
HDWindowLoggerSwift.hideLogWindow()
```

7, set the log maximum number of records, the default 100, 0 is not limited

```
HDWindowLoggerSwift.setMaxLogCount(logCount: 100)
```

For the convenience of output, a three macro definition is encapsulated, corresponding to the different types of printLog.

```
HDNormalLog(log)

HDWarnLog(log)

HDErrorLog(log)
```

### 2.1, use example

The following two ways of using the output log are equivalent.

```
HDWindowLoggerSwift.printLog(log: "mmmmmm" as AnyObject, logType: HDLogType.kHDLogTypeNormal)
HDWarnLog(log: "mmmmmmm" as AnyObject)
```

## III. Other instructions

1. For the convenience of viewing, it is divided into three types: normal, warning and error. It corresponds to three different colors for easy viewing.
2. Click the corresponding cell to copy the output log directly to the system clipboard.
3. Share the system share that is called. Which software you can share depends on which software is installed on your phone.

<span id = "chinese"></span>

## 简体中文介绍

项目地址:[https://github.com/DamonHu/HDWindowLoggerSwift](https://github.com/DamonHu/HDWindowLoggerSwift)

展示效果gif图:

![](./ReadmeImage/demo.gif)

除了在屏幕上显示，可以设置是否自动滚动日志便于调试，也可以将输出的日志分享到微信、twitter等程序，以便离线查看。同时可以搜索输出内容，自己处理等

![](./ReadmeImage/2.png)

## 一、安装

你可以选择使用cocoaPod安装，也可以直接下载源文件拖入项目中

### 1.1、cocoaPod安装

```
pod 'HDWindowLoggerSwift'
```

### 1.2、文件安装

可以将工程底下，`HDWindowLoggerSwift`文件夹内的文件拖入项目即可

## 二、使用

导入头文件

```
import HDWindowLoggerSwift
```

### 2.1、然后可以根据示例随意使用以下功能

1、 显示悬浮窗

```
HDWindowLoggerSwift.show()
```

2、 获取log信息内容

```
HDWindowLoggerSwift.defaultWindowLogger.mLogDataArray
```
3、根据日志的输出类型去输出相应的日志，不同日志类型颜色不一样

```
HDWindowLoggerSwift.printLog(log: "mmmmmm" as AnyObject, logType: HDLogType.kHDLogTypeNormal)

///使用简单函数也可以同样的效果
HDNormalLog(log: "mmmmmmm" as AnyObject)
```

4、删除log

```
HDWindowLoggerSwift.cleanLog()
```

5、隐藏整个log窗口

```
HDWindowLoggerSwift.hide()
```

6、仅隐藏log输出窗口

```
HDWindowLoggerSwift.hideLogWindow()
```

7、设置log最大记录数，默认100条，0为不限制

```
HDWindowLoggerSwift.setMaxLogCount(logCount: 100)
```

为了输出方便，封装了一个三个宏定义，对应的printLog不同的类型

```
HDNormalLog(log)

HDWarnLog(log)

HDErrorLog(log)
```

### 2.1、使用示例

输出日志下面两种使用方式是等效的

```
HDWindowLoggerSwift.printLog(log: "mmmmmm" as AnyObject, logType: HDLogType.kHDLogTypeNormal)
HDWarnLog(log: "mmmmmmm" as AnyObject)
```

## 三、其他说明

1. 为了查看方便，分为普通、警告、错误三种类型，对应了三种不同的颜色，方便查看
2. 点击对应的cell可以直接将输出log复制到系统剪贴板
3. 分享调用的系统分享，可以分享到哪个软件取决于你手机上安装的有哪些软件。