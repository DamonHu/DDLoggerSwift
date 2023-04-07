# ZXKitLogger

![](https://img.shields.io/badge/CocoaPods-supported-brightgreen) ![](https://img.shields.io/badge/Swift-5.0-brightgreen) ![](https://img.shields.io/badge/License-MIT-brightgreen) ![](https://img.shields.io/badge/version-iOS11.0-brightgreen)

[English](./README_en.md)

> 如果您需要的是快速集成多个调试功能，例如日志查看、网速测试、文件查看等功能，可使用 [DamonHu/ZXKitSwift](https://github.com/DamonHu/ZXKitSwift)。


iOS端将输出日志log悬浮显示在屏幕上，可以生成日志文件分享，便于在真机没有连接xcode的情况下调试信息。可以分享、筛选log等操作。

该项目使用`sqlite`高效存储，后台运行期间只记录数据，不会影响界面性能，前台运行效率高，基本和Xcode同步输出日志，可以查看和xCode日志输出的对比gif图

|预览gif图|Xcode对比gif图|
|----|----|
|![](./readmeResources/preview.gif)|![](./readmeResources/debug.gif)|


|预览图|分享 & FPS|
|----|----|
|![](./readmeResources/mobile_preview.png)<br/>XCode预览图<br/>![](./readmeResources/xcode_preview.png)|![](./readmeResources/share_preview.png)|

![](./readmeResources/preview.png)

## 一、安装

你可以选择使用cocoaPod安装，也可以直接下载源文件拖入项目中

### 1.1、cocoaPod安装

```
pod 'ZXKitLogger'
```

### 1.2、文件安装

可以将工程底下，`pod`文件夹内的文件拖入项目即可

## 二、使用

简单三步即可调用

### 1、导入头文件

```
import ZXKitLogger
```

### 2、显示悬浮窗

```
ZXKitLogger.show()
```

### 3、打印日志内容

四种输出方式字体颜色显示不同，对应的printLog不同的类型

```
printDebug(log)	//调试输出，默认不会写入数据库

printLog(log)	//日志为绿色

printWarn(log)	//日志为黄色

printError(log)	//日志为红色

printPrivacy(log)	//加密数据的输出，具体加密方式在下面的加密中说明

```

输出格式

```
2021-08-11 10:07:28.378 ---- ⚠️⚠️ ---- File: ViewController.swift -- Line: 82 -- Function:ViewController.swift.onClickButton() ----
警告提示

2021-08-11 10:07:28.380 ---- ❌❌ ---- File: ViewController.swift -- Line: 84 -- Function:ViewController.swift.onClickButton() ----
错误出现

2021-08-11 10:07:28.381 ---- ⛔️⛔️ ---- File: ViewController.swift -- Line: 86 -- Function:ViewController.swift.onClickButton() ----
AAuKjIm5hC2jiPqz7OKHAngWspeACyWZufDguqdOcugituhWV8jnbr/6SHYoK0/9

2021-08-11 10:07:28.383 ---- ✅✅ ---- File: ViewController.swift -- Line: 89 -- Function:ViewController.swift.onClickButton() ----
{
  "77777" : "数据库的复健科花见花开会尽快圣诞节开发和金黄色的费四大皆空回复就开始和豆腐是砍价的回复斯柯达金凤凰",
  "hhhhhhh" : "撒旦法是打发斯蒂芬是打发斯蒂芬"
}

2021-08-11 10:07:28.388 ---- 💜💜 ---- File: ViewController.swift -- Line: 76 -- Function:ViewController.swift.onClickButton() ----
测试输出，默认不会写入数据库
```

## 三、更多设置

通过其他设置可以实现获取更多功能

### 1、设置是否输出全部信息

```
ZXKitLogger.isFullLogOut = true
```

如果设置为`true`，那么输出的格式是下面这样的，包含了输出文件、调用的行数、和调用的函数

```
13:36:08.474 ---- ⚠️⚠️ ---- File: ViewController.swift -- Line: 82 -- Function:ViewController.swift.onClickButton() ----
警告提示

13:36:08.476 ---- ❌❌ ---- File: ViewController.swift -- Line: 84 -- Function:ViewController.swift.onClickButton() ----
错误出现

13:36:08.487 ---- ⛔️⛔️ ---- File: ViewController.swift -- Line: 86 -- Function:ViewController.swift.onClickButton() ----
AAuKjIm5hC2jiPqz7OKHAngWspeACyWZufDguqdOcugituhWV8jnbr/6SHYoK0/9

13:36:08.489 ---- ✅✅ ---- File: ViewController.swift -- Line: 89 -- Function:ViewController.swift.onClickButton() ----
{
  "hhhhhhh" : "撒旦法是打发斯蒂芬是打发斯蒂芬",
  "77777" : "数据库的复健科花见花开会尽快圣诞节开发和金黄色的费四大皆空回复就开始和豆腐是砍价的回复斯柯达金凤凰"
}

2021-08-11 10:07:28.388 ---- 💜💜 ---- File: ViewController.swift -- Line: 76 -- Function:ViewController.swift.onClickButton() ----
测试输出，默认不会写入数据库
```

设置为`false`的输出样式

```
2021-08-11 10:10:33.309 ---- ⚠️⚠️ ---- 
警告提示

2021-08-11 10:10:33.310 ---- ❌❌ ---- 
错误出现

2021-08-11 10:10:33.312 ---- ⛔️⛔️ ---- 
AAuKjIm5hC2jiPqz7OKHAngWspeACyWZufDguqdOcugituhWV8jnbr/6SHYoK0/9

2021-08-11 10:10:33.318 ---- ✅✅ ---- 
{
  "hhhhhhh" : "撒旦法是打发斯蒂芬是打发斯蒂芬",
  "77777" : "数据库的复健科花见花开会尽快圣诞节开发和金黄色的费四大皆空回复就开始和豆腐是砍价的回复斯柯达金凤凰"
}

2021-08-11 10:10:33.323 ---- 💜💜 ---- 
测试输出，默认不会写入数据库
```

### 2、是否在xcode底部的调试栏同步输出内容

```
ZXKitLogger.isSyncConsole = true
```

### 3、针对不同用户设置独立日志文件夹

```
ZXKitLogger.userID = "1001"
```

### 4、清空log

```
ZXKitLogger.cleanLog()
```

### 5、关闭整个log窗口

```
ZXKitLogger.close()
```

### 6、仅隐藏log输出窗口

```
ZXKitLogger.hide()
```

### 7、设置显示log最大记录数，0为不限制, 默认为100

```
ZXKitLogger.maxDisplayCount = 100
```

### 8、 删除本地日志文件

```
ZXKitLogger.deleteLogFile()
```

### 9、 本地日志文件的有效期（天），超出有效期的本地日志会被删除，0为没有有效期，默认为30天

```
ZXKitLogger.logExpiryDay = 30
```

### 10、存储日志的级别

包含在内的日志级别会被存储到数据库，默认debug级别不存储

```

ZXKitLogger.storageLevels = [.info, .warn, .error, .privacy]

```

### 11、获取数据库存储的日志信息数组，也可以指定日期

```
//获取今日的日志
ZXKitLogger.getAllLog()
//指定日期
ZXKitLogger.getAllLog(date: Date(timeIntervalSinceNow: 1000))
```


如果你想获取所有日志文件，可以获取日志存储的文件夹，返回的是一个URL结果，然后自己进行遍历去处理

```
ZXKitLogger.getDBFolder()
```

例如

```
let dbFolder = ZXKitLogger.getDBFolder()
        
if let enumer = FileManager.default.enumerator(atPath: dbFolder.path) {
    while let file = enumer.nextObject() {
         if let file: String = file as? String {
            if file.hasSuffix(".db") {
            	//获取到具体的log文件日志
                let logFilePath = dbFolder.appendingPathComponent(file, isDirectory: false)
             }
         }
    }
}
```

### 12、直接显示日志分享window

如果你不想让用户看到日志输出的window，而仅仅是让分享日志，则可以调用

```
ZXKitLogger.showShare()
```

### 13、显示日志上传选择window和按钮

如果你想让用户上传db文件，除了可以自己遍历，我们也提供了快捷方案，和分享一样，调用

```
ZXKitLogger.showUpload()
```

即可出现上传的选项，用户选择之后确定的回调在`uploadComplete`，你实现该回调即可，例如

```
ZXKitLogger.uploadComplete = { file in
     print(file)
     //处理上传
}
```

### LogContent协议

如果你想自定义输出的内容，可以集成并该类型的LogContent协议，例如设置打印`URL`类型只输出它的`path`，可以直接设置返回的`logStringValue`即可。

```
extension URL: LogContent {
    public var logStringValue: String {
        return self.path
    }
}
```


## 四、 敏感信息输出加密和解密

如果存在敏感信息，不希望用户或者手机调试时看到，简单两步就可以设置加密

```
//1、设置加密密码，32个字符数字。默认为12345678901234561234567890123456
ZXKitLogger.privacyLogPassword = "12345678901234561234567890123456"

//2、输出加密内容
printPrivacy("这个是加密数据的测试数据222")
```

### 4.2、显示窗内容解密

设置之后，在显示窗中的显示为`该内容已加密，请解密后查看`，输入设置的加密密码然后点击解密之后即可显示正常的加密内容。

### 4.1、 分享文件解密

* 如果已经在显示窗解密了数据，此时分享的文件内容不会加密，会显示所有内容。
* 如果在显示窗中未解密，此时分享出的文件内容为AES加密内容，可以搜索`AES在线解密的网站`去解密内容，设置参照下图：

![](./readmeResources/decrypt.png)

* 模式: CBC
* 填充: Pkcs7
* 数据块: 128位
* 偏移量: abcdefghijklmnop
* 编码: Base64
* 字符集: UTF8
* 密码: 你自己在sdk中设置的密码

然后点击解密即可。

这里推荐几个在线的网站，你也可以自己百度

* [https://oktools.net/aes](https://oktools.net/aes)
* [http://tools.bugscaner.com/cryptoaes/](http://tools.bugscaner.com/cryptoaes/)
* [http://tool.chacuo.net/cryptaes](http://tool.chacuo.net/cryptaes)


## 五、日志查看客户端

该库使用SQLite存储日志信息，如果使用通用的SQLite查看工具，只是一条一条的表格，并且有的还收费。所以可以使用[ZXKitLogger_Mac](https://github.com/DamonHu/ZXKitLogger_Mac)的客户端配合查看`ZXKitLogger`导出的SQLite文件。

![](./readmeResources/Jietu20220731-212644.png)

## 六、局域网实时日志

`3.0.0` 版本之后，可配合上面的日志查看工具，可实现局域网实时日志查看，简单配置接口使用

1、增加局域网功能

```
pod 'ZXKitLogger/socket'
```

2、在项目`info.plist`增加局域网描述，和`Bonjour`的服务字段。

```
<key>NSBonjourServices</key>
	<array>
		<string>_zxkitlogger._tcp</string>
	</array>
<key>NSLocalNetworkUsageDescription</key>
<string>查找本地网络以便使用Bonjour功能</string>
```

**注意：`NSBonjourServices`的type值和`ZXKitLogger.socketType`保持一致，ZXKitLogger代码中的`socketType`可以自定义，修改之后info.plist也做对应的修改即可**

无需其他配置，即可在通过[ZXKitLogger_Mac](https://github.com/DamonHu/ZXKitLogger_Mac)查看同一局域网下的设备日志

## 七、其他说明tips

1. 为了查看方便，分为普通、警告、错误三种类型，对应了三种不同的颜色，方便查看
2. 点击对应的cell可以直接将输出log复制到系统剪贴板
3. 分享调用的系统分享，可以分享到哪个软件取决于你手机上安装的有哪些软件。
4.   分享出去的log文件可在任意文本编辑器查看，在`VSCode`查看会有代码高亮效果

## License

该项目基于MIT协议，您可以自由修改使用