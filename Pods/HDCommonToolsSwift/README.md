![](./HDCommonToolsSwift.png)

# HDCommonToolsSwift

[HDCommonToolsSwift](https://github.com/DamonHu/HDCommonToolsSwift)的Swift版本，简单高效的集成常用功能，将常用的功能集合进来。目前还在完善中，也可以直接使用HDCommonToolsSwift的OC版本

## 一、导入项目

### 通过cocoapods导入

```
pod 'HDCommonToolsSwift'
```

由于苹果对`idfa`的访问权限要求更严，只要导入了`AppTrackingTransparency`这个库就会询问跟踪的目的，不论你是否主动调用过，所以从`2.1.0`开始，`idfa`单独拿出来，如果需要`idfa`的功能，可以选择导入

```
pod 'HDCommonToolsSwift/idfa'
```

### 通过文件导入

下载项目，将项目文件下的HDCommonToolsSwift文件夹里面的内容导入项目即可

## 二、API列表

已有的数据类型操作可以通过`.hd`的语法，其他操作可以通过`HDCommonToolsSwift.shared`单例来使用。

* 单例和`.hd`使用没区别，单例会更统一简单，`.hd`语法的好处就是不需要在使用的地方导入

```
import HDCommonToolsSwift
```

### UI相关

|名称|功能说明|示例|
|----|----|----|
|func getCurrentNormalWindow()|获取当前的NormalWindow|HDCommonToolsSwift.shared.getCurrentNormalWindow()|
|func getCurrentVC()|获取当前的ViewController|HDCommonToolsSwift.shared.getCurrentVC()|
|func getImage(color: UIColor)|通过颜色生成一张纯色背景图|HDCommonToolsSwift.shared.getImage(color: UIColor.red) <br/>或者<br/> UIImage.hd.getImage(color: UIColor.red)|
|func getLinearGradientImage(colors: [UIColor], directionType: HDGradientDirection, size: CGSize = CGSize(width: 100, height: 100))|生成线性渐变的图片|HDCommonToolsSwift.shared.getLinearGradientImage(colors:  [UIColor.red, UIColor.black, UIColor.blue] <br/>或者<br/> UIImage.hd.getLinearGradientImage(colors: [UIColor.red, UIColor.black, UIColor.blue], directionType: .leftToRight)|
|func getRadialGradientImage(colors: [UIColor], raduis: CGFloat, size: CGSize = CGSize(width: 100, height: 100))|生成角度渐变的图片|HDCommonToolsSwift.shared.getRadialGradientImage(colors: [UIColor.red, UIColor.black, UIColor.blue], raduis: 45) <br/>或者<br/> UIImage.hd.getRadialGradientImage(colors: [UIColor.red, UIColor.black, UIColor.blue], raduis: 45)|
|func getColor(hexString: String, alpha: CGFloat = 1.0)|通过十六进制字符串获取颜色|UIColor(hexString: "#FFFFFF") <br/>或者<br/>  UIColor.hd.color(hexString: "#FFFFFF")|
|func UIColor(hexValue: Int, darkHexValue: Int = 0x333333, alpha: Float = 1.0, darkAlpha: Float = 1.0)|通过十六进制获取颜色|UIColor(hexValue: 0xffffff) <br/>或者<br/> UIColor.hd.color(hexValue: 0xffffff)|
|UIScreenWidth|屏幕宽度||
|UIScreenHeight|屏幕高度||
|HD_StatusBar_Height|状态栏高度||
|func HD_Default_NavigationBar_Height(vc: UIViewController? = nil)|导航栏高度|HD_Default_NavigationBar_Height()|
|func func HD_Default_Tabbar_Height(vc: UIViewController? = nil)|tabbar高度|HD_Default_Tabbar_Height()|
|func addLayerShadow(color: UIColor, offset: CGSize, radius: CGFloat, cornerRadius: CGFloat? = nil)|为view添加阴影|view.hd.addLayerShadow(color: UIColor.black, offset: CGSize(width: 2, height: 0), radius: 10)|
|func setFrame(x: CGFloat? = nil, y: CGFloat? = nil, width: CGFloat? = nil, height: CGFloat? = nil)|view单独设置Frame的某个值|view.hd.setFrame(x: 10)|

### 系统和软件信息

|名称|功能说明|示例|
|----|----|----|
|func getAppVersionString()|获取软件版本|HDCommonToolsSwift.shared.getAppVersionString()|
|func getAppBuildVersionString()|获取软件构建版本|HDCommonToolsSwift.shared.getAppBuildVersionString()|
|func getIOSVersionString()|获取系统的iOS版本|HDCommonToolsSwift.shared.getIOSVersionString()|
|func getIOSLanguageStr()|获取系统语言|HDCommonToolsSwift.shared.getIOSLanguageStr()|
|func getBundleIdentifier()|获取软件Bundle Identifier|HDCommonToolsSwift.shared.getBundleIdentifier()|
|func getSystemHardware()|获取本机机型标识|HDCommonToolsSwift.shared.getSystemHardware()|
|func getSystemUpTime()|获取本机上次重启时间|HDCommonToolsSwift.shared.getSystemUpTime()|
|func getIDFAString(idfvIfFailed: Bool = true)|模拟软件唯一标示|HDCommonToolsSwift.shared.getIDFAString()|
|func getMacAddress()|获取手机WIFI的MAC地址，需要开启Access WiFi information|HDCommonToolsSwift.shared.getMacAddress()|
|func openSystemSetting()|打开系统设置|HDCommonToolsSwift.shared.openSystemSetting()|
|func openAppStorePage(openType: HDOpenAppStoreType, appleID: String)|打开软件对应的App Store页面|HDCommonToolsSwift.shared.openAppStorePage(openType: .app, appleID: "1123211")|
|func openAppStoreReviewPage(openType: HDOpenAppStoreType, appleID: String = "")|打开软件对应的评分页面|HDCommonToolsSwift.shared.openAppStoreReviewPage(openType: .app)|

### 软件权限

|名称|功能说明|示例|
|----|----|----|
|func requestPermission(type: HDPermissionType, complete: @escaping ((HDPermissionStatus) -> Void))|请求权限|HDCommonToolsSwift.shared.requestPermission(type: .notification) { (status) in print("权限设置回调", status) }|
|func checkPermission(type: HDPermissionType, complete: @escaping ((HDPermissionStatus) -> Void))|检测软件权限|HDCommonToolsSwift.shared.checkPermission(type: .notification) { (status) in print("当前权限状态", status) }|
|func requestIDFAPermission(complete: @escaping ((HDPermissionStatus) -> Void)) -> Void|检测软件IDFA权限|HDCommonToolsSwift.shared.requestIDFAPermission { (status) in print("当前idfa权限状态", status) }|
|func checkIDFAPermission(type: HDPermissionType, complete: @escaping ((HDPermissionStatus) -> Void)) -> Void|检测软件idfa权限|HDCommonToolsSwift.shared.checkIDFAPermission { (status) in print("当前权限状态", status) }|

### 多媒体操作

|名称|功能说明|示例|
|----|----|----|
|func getVideoDuration(videoURL: URL) -> Double|获取指定video的时长， 单位秒| HDCommonToolsSwift.shared.getVideoDuration(videoURL: URL(fileURLWithPath: path))|
|func getVideoSize(videoURL: URL)|获取指定视频的分辨率，支持本地或者网络地址|HDCommonToolsSwift.shared.getVideoSize(videoURL: URL(fileURLWithPath: path))|
|func playMusic(url: URL?, repeated: Bool = false, audioSessionCategory: AVAudioSession.Category = AVAudioSession.Category.playback)|播放音乐|HDCommonToolsSwift.shared.playMusic(url: url, repeated: false)|
|func stopMusic()|关闭音乐播放|HDCommonToolsSwift.shared.stopMusic()|
|func playEffect(url: URL?, vibrate: Bool = false)|播放音效，静音模式不会播放音效|HDCommonToolsSwift.shared.playEffect(url: url, vibrate: true)|
|func startVibrate(repeated: Bool = false)|开始震动|HDCommonToolsSwift.shared.startVibrate()|
|func stopVibrate()|结束震动|HDCommonToolsSwift.shared.stopVibrate()|

### 文件操作

|名称|功能说明|示例|
|----|----|----|
|func getFileDirectory(type: HDFileDirectoryType)|获取文件夹路径|HDCommonToolsSwift.shared.getFileDirectory(type: .documents)|
|func createFileDirectory(in type: HDFileDirectoryType, directoryName: String)|在指定文件夹中创建文件夹|HDCommonToolsSwift.shared.createFileDirectory(in: .documents, directoryName: "filePath")|
|func getFileSize(filePath: URL)|获取指定文件的大小|HDCommonToolsSwift.shared.getFileSize(filePath: url)|
|func getFileDirectorySize(fileDirectoryPth: URL)|获取指定文件夹的大小|HDCommonToolsSwift.shared.getFileDirectorySize(fileDirectoryPth: url)|

### 其他

|名称|功能说明|示例|
|----|----|----|
|func compare(anotherDate: Date, ignoreTime: Bool = false)|比较日期，设置是否忽略时间|Date().hd.compare(anotherDate: date)|
|func subString(rang: NSRange)|截取字符串|string.hd.subString(rang: NSRange(location: 2, length: 5))|
|func unicodeDecode()|unicode转中文|"\\u54c8\\u54c8\\u54c8".hd.unicodeDecode()|
|func unicodeEncode()|字符串转unicode|"哈哈是电话费".hd.unicodeEncode()|
|func base64Decode(lowercase: Bool = true)|base64解码|"5ZOI5ZOI5piv55S16K+d6LS5".hd.base64Decode()|
|func aes256Decrypt(password: String, ivString: String = "abcdefghijklmnop")|aes256解密|string.hd.aes256Decrypt(password: "password")|
|func aes256Encrypt(password: String, ivString: String = "abcdefghijklmnop")|aes256加密|string.hd.aes256Encrypt(password: "password")|
|func encryptString(encryType: HDEncryType, lowercase: Bool = true)|字符串加密|string.hd.encryptString(encryType: HDEncryType.md5) <br/> 支持md5/sha1/sha224/sha256/sha384/sha512/base64加密|

## 三、其他

欢迎交流，互相学习

项目gitHub地址：[https://github.com/DamonHu/HDCommonToolsSwift](https://github.com/DamonHu/HDCommonToolsSwift)