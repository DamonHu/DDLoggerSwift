//
//  ZXKitLogger.swift
//  ZXKitLogger
//
//  Created by Damon on 2019/6/24.
//  Copyright © 2019 Damon. All rights reserved.
//

import UIKit
import ZXKitUtil
import CommonCrypto
import ZXKitFPS

///log的级别，对应不同的颜色
public enum ZXKitLogType : Int {
    case normal = 0   //textColor #50d890
    case warn         //textColor #f6f49d
    case error        //textColor #ff7676
    case privacy      //textColor #42e6a4
    case debug        //only show in debug output
}

///快速输出log
//测试输出，不会写入到悬浮窗中
public func ZXDebugLog(_ log:Any, file:String = #file, funcName:String = #function, lineNum:Int = #line) -> Void {
    ZXKitLogger.printLog(log: log, logType: ZXKitLogType.debug, file:file, funcName:funcName, lineNum:lineNum)
}
public func ZXDebugLog(_ log:Any ..., file:String = #file, funcName:String = #function, lineNum:Int = #line) -> Void {
    ZXKitLogger.printLog(log: log, logType: ZXKitLogType.debug, file:file, funcName:funcName, lineNum:lineNum)
}
//普通类型的输出
public func ZXNormalLog(_ log:Any, file:String = #file, funcName:String = #function, lineNum:Int = #line) -> Void {
    ZXKitLogger.printLog(log: log, logType: ZXKitLogType.normal, file:file, funcName:funcName, lineNum:lineNum)
}
public func ZXNormalLog(_ log:Any ..., file:String = #file, funcName:String = #function, lineNum:Int = #line) -> Void {
    ZXKitLogger.printLog(log: log, logType: ZXKitLogType.normal, file:file, funcName:funcName, lineNum:lineNum)
}
//警告类型的输出
public func ZXWarnLog(_ log:Any, file:String = #file, funcName:String = #function, lineNum:Int = #line) -> Void {
    ZXKitLogger.printLog(log: log, logType: ZXKitLogType.warn, file:file, funcName:funcName, lineNum:lineNum)
}
public func ZXWarnLog(_ log:Any ..., file:String = #file, funcName:String = #function, lineNum:Int = #line) -> Void {
    ZXKitLogger.printLog(log: log, logType: ZXKitLogType.warn, file:file, funcName:funcName, lineNum:lineNum)
}
//错误类型的输出
public func ZXErrorLog(_ log:Any, file:String = #file, funcName:String = #function, lineNum:Int = #line) -> Void {
    ZXKitLogger.printLog(log: log, logType: ZXKitLogType.error, file:file, funcName:funcName, lineNum:lineNum)
}
public func ZXErrorLog(_ log:Any ..., file:String = #file, funcName:String = #function, lineNum:Int = #line) -> Void {
    ZXKitLogger.printLog(log: log, logType: ZXKitLogType.error, file:file, funcName:funcName, lineNum:lineNum)
}
//保密类型的输出
public func ZXPrivacyLog(_ log:Any, file:String = #file, funcName:String = #function, lineNum:Int = #line) -> Void {
    ZXKitLogger.printLog(log: log, logType: ZXKitLogType.privacy, file:file, funcName:funcName, lineNum:lineNum)
}
public func ZXPrivacyLog(_ log:Any ..., file:String = #file, funcName:String = #function, lineNum:Int = #line) -> Void {
    ZXKitLogger.printLog(log: log, logType: ZXKitLogType.privacy, file:file, funcName:funcName, lineNum:lineNum)
}

///log的输出
public class ZXKitLogger {
    public static var isFullLogOut = true    //是否完整输出日志文件名等调试内容
    public static var isSyncConsole = true   //是否在xcode底部的调试栏同步输出内容
    public static var privacyLogPassword = "" {
        willSet {
            assert(newValue.count == kCCKeySizeAES256, NSLocalizedString("The password requires 32 characters", comment: ""))
        }
    }     //解密隐私数据的密码，默认为空不加密
    public static var logExpiryDay = 7        //本地日志文件的有效期（天），超出有效期的本地日志会被删除，0为没有有效期，默认为7天
    public static var maxDisplayCount = 100       //屏幕最大的显示数量，适量即可，0为不限制
    public static var userID = "0"             //为不同用户创建的独立的日志库
    public static var isShowFPS = true {
        willSet {
            if newValue {
                shared.mFPSTools.start { (fps) in
                    DispatchQueue.main.async {
                        shared.floatWindow?.mButton.setTitle("\(fps)FPS", for: UIControl.State.normal)
                        shared.floatWindow?.mButton.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .bold)
                        if fps >= 55 {
                            shared.floatWindow?.mButton.backgroundColor = UIColor.zx.color(hexValue: 0x5dae8b)
                        } else if (fps >= 50 && fps < 55) {
                            shared.floatWindow?.mButton.backgroundColor = UIColor.zx.color(hexValue: 0xf0a500)
                        } else {
                            shared.floatWindow?.mButton.backgroundColor = UIColor.zx.color(hexValue: 0xaa2b1d)
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    shared.mFPSTools.stop()
                    shared.floatWindow?.mButton.titleLabel?.font = UIFont.systemFont(ofSize: 23, weight: .bold)
                    shared.floatWindow?.mButton.backgroundColor = UIColor.zx.color(hexValue: 0x5dae8b)
                    shared.floatWindow?.mButton.setTitle(NSLocalizedString("H", comment: ""), for: UIControl.State.normal)
                }
            }
        }
    }            //是否显示屏幕FPS状态
    //MARK: Private
    private let mFPSTools = ZXKitFPS()
    private var loggerWindow: ZXKitLoggerWindow?
    private var floatWindow: ZXKitLoggerFloatWindow?
    var isPasswordCorrect: Bool = false
    static let shared = ZXKitLogger()

    private let logQueue = DispatchQueue(label:"com.HDWindowLogger.logQueue", qos:.utility, attributes:.concurrent)
    //log的Public函数
    /// 根据日志的输出类型去输出相应的日志，不同日志类型颜色不一样
    /// - Parameter log: 日志内容
    /// - Parameter logType: 日志类型
    public class func printLog(log:Any, logType:ZXKitLogType, file:String = #file, funcName:String = #function, lineNum:Int = #line) -> Void {
        shared.logQueue.async(group: nil, qos: .default, flags: .barrier) {
            let loggerItem = ZXKitLoggerItem()
            loggerItem.mLogItemType = logType
            loggerItem.mCreateDate = Date()

            let fileName = (file as NSString).lastPathComponent;
            loggerItem.mLogDebugContent = "[File:\(fileName)]:[Line:\(lineNum):[Function:\(funcName)]]-Log:"
            loggerItem.mLogContent = log

            if logType == .debug {
                print(loggerItem.getFullContentString())
            } else {
                if self.isSyncConsole {
                    print(loggerItem.getFullContentString())
                }
                //写入文件
                self.shared._writeDB(log: loggerItem)
                //刷新列表
                DispatchQueue.main.async {
                    self.shared.loggerWindow?.insert(model: loggerItem)
                }
            }
        }
    }
    
    ///获取log日志数组
    public class func getAllLog(date: Date? = nil) -> [String] {
        if let date = date {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: date)
            return HDSqliteTools.shared.getAllLog(name: dateString)
        } else {
            return HDSqliteTools.shared.getAllLog()
        }
    }

    ///获取log日志的数据库
    public class func getDBFolder() -> URL {
        return HDSqliteTools.shared.getDBFolder()
    }
    
    ///  删除log日志
    public class func cleanLog() {
        DispatchQueue.main.async {
            self.shared.loggerWindow?.cleanDataArray()
        }
    }
    
    /// 显示log窗口
    public class func show() {
        DispatchQueue.main.async {
            self.shared.floatWindow?.isHidden = true
            if self.shared.loggerWindow == nil {
                if #available(iOS 13.0, *) {
                    for windowScene:UIWindowScene in ((UIApplication.shared.connectedScenes as? Set<UIWindowScene>)!) {
                        if windowScene.activationState == .foregroundActive {
                            self.shared.loggerWindow = ZXKitLoggerWindow(windowScene: windowScene)
                        }
                    }
                }
                if self.shared.loggerWindow == nil {
                    self.shared.loggerWindow = ZXKitLoggerWindow(frame: CGRect.zero)
                }
            }
            self.shared.loggerWindow?.isHidden = false
            self.isShowFPS = true
        }
    }
    
    /// 只隐藏log的输出窗口，保留悬浮图标
    public class func hide() {
        DispatchQueue.main.async {
            self.shared.loggerWindow?.isHidden = true
            #if canImport(ZXKitCore)
            ZXWarnLog(NSLocalizedString("The float button already exists", comment: ""))
            #else
            //float window
            if let window = self.shared.floatWindow {
                window.isHidden = false
            } else {
                if #available(iOS 13.0, *) {
                    for windowScene:UIWindowScene in ((UIApplication.shared.connectedScenes as? Set<UIWindowScene>)!) {
                        if windowScene.activationState == .foregroundActive {
                            self.shared.floatWindow = ZXKitLoggerFloatWindow(windowScene: windowScene)
                            self.shared.floatWindow?.frame = CGRect(x: UIScreen.main.bounds.size.width - 80, y: 100, width: 60, height: 60)
                        }
                    }
                }
                if self.shared.floatWindow == nil {
                    self.shared.floatWindow = ZXKitLoggerFloatWindow(frame: CGRect(x: UIScreen.main.bounds.size.width - 80, y: 100, width: 60, height: 60))
                }
                self.shared.floatWindow?.isHidden = false
            }
            #endif
        }
    }

    ///  隐藏整个log窗口
    public class func close() {
        DispatchQueue.main.async {
            self.shared.loggerWindow?.isHidden = true
            self.shared.floatWindow?.isHidden = true
        }
    }

    /// 删除本地日志文件
    public class func deleteLogFile() {
        let dbFolder = self.getDBFolder()
        
        if let enumer = FileManager.default.enumerator(atPath: dbFolder.path) {
            while let file = enumer.nextObject() {
                if let file: String = file as? String {
                    if file.hasSuffix(".db") {
                        let logFilePath = dbFolder.appendingPathComponent(file, isDirectory: false)
                        try? FileManager.default.removeItem(at: logFilePath)
                    }
                }
            }
        }
    }

    //MARK: init
    init() {
        if ZXKitLogger.logExpiryDay > 0 {
            self._checkValidity()
        }
    }
}

private extension ZXKitLogger {
    func _writeDB(log: ZXKitLoggerItem) -> Void {
        HDSqliteTools.shared.insertLog(log: log)
    }
    
    func _checkValidity() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let cachePath = HDSqliteTools.shared.getDBFolder()

        if let enumer = FileManager.default.enumerator(atPath: cachePath.path) {
            while let file = enumer.nextObject() {
                if let file: String = file as? String {
                    if file.hasSuffix(".db") {
                        //截取日期
                        let index2 = file.startIndex
                        let index3 = file.index(file.startIndex, offsetBy: 9)
                        let dateString = file[index2...index3]
                        let fileDate = dateFormatter.date(from: String(dateString))
                        if let fileDate = fileDate {
                            if Date().timeIntervalSince(fileDate) > Double(Self.logExpiryDay * 3600 * 24) {
                                let logFilePath = cachePath.appendingPathComponent(file, isDirectory: false)
                                try? FileManager.default.removeItem(at: logFilePath)
                            }
                        }
                    }
                }
            }
        }
    }
}
