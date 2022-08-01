# FPS

![](https://img.shields.io/badge/CocoaPods-supported-brightgreen) ![](https://img.shields.io/badge/Swift-5.0-brightgreen) ![](https://img.shields.io/badge/License-MIT-brightgreen) ![](https://img.shields.io/badge/version-iOS11.0-brightgreen)

[English](./README_en.md)

如果您需要的是快速集成多个调试功能，例如日志查看、网速测试、文件查看等功能，请使用 [DamonHu/ZXKitSwift](https://github.com/DamonHu/ZXKitSwift)。

**该插件已经默认集成在[ZXKitSwift](https://github.com/DamonHu/ZXKitSwift)中，如果您已经集成了`ZXKitSwift`，无需重复集成该插件**

FPS是图像领域中的定义，是指画面每秒传输帧数，通俗来讲就是指动画或视频的画面数。FPS是测量用于保存、显示动态视频的信息数量。每秒钟帧数越多，所显示的动作就会越流畅。通常，要避免动作不流畅的最低是30。

该工具用来iOS平台测试帧率

# 集成

1、可以使用cocoapods集成

```
pod 'ZXKitFPS'
```

2、使用文件

如果您不想使用cocoapods集成，可以将根目录下的`pod`文件夹中的内容拖到项目即可

## 使用

```
//创建对象
let fps = ZXKitFPS()

//开始测试
fps.start { (fps) in
  print(fps)
}

//结束测试
fps.stop()
```

## License

该项目基于MIT协议，您可以自由修改使用