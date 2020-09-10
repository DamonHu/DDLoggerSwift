//
//  HDWindowLoggerSwift.swift
//  HDWindowLoggerSwift
//
//  Created by Damon on 2019/6/24.
//  Copyright © 2019 Damon. All rights reserved.
//

import UIKit
import HDSwiftCommonTools


///log的级别，对应不同的颜色
public enum HDLogType : Int {
    case normal = 0   //textColor #50d890
    case warn         //textColor #f6f49d
    case error        //textColor #ff7676
    case privacy      //textColor #42e6a4
    case debug        //only show in debug output
}

///快速输出log
//测试输出，不会写入到悬浮窗中
public func HDDebugLog(_ log:Any, file:String = #file, funcName:String = #function, lineNum:Int = #line) -> Void {
    HDWindowLoggerSwift.printLog(log: log, logType: HDLogType.debug, file:file, funcName:funcName, lineNum:lineNum)
}
public func HDDebugLog(_ log:Any ..., file:String = #file, funcName:String = #function, lineNum:Int = #line) -> Void {
    HDWindowLoggerSwift.printLog(log: log, logType: HDLogType.debug, file:file, funcName:funcName, lineNum:lineNum)
}
//普通类型的输出
public func HDNormalLog(_ log:Any, file:String = #file, funcName:String = #function, lineNum:Int = #line) -> Void {
    HDWindowLoggerSwift.printLog(log: log, logType: HDLogType.normal, file:file, funcName:funcName, lineNum:lineNum)
}
public func HDNormalLog(_ log:Any ..., file:String = #file, funcName:String = #function, lineNum:Int = #line) -> Void {
    HDWindowLoggerSwift.printLog(log: log, logType: HDLogType.normal, file:file, funcName:funcName, lineNum:lineNum)
}
//警告类型的输出
public func HDWarnLog(_ log:Any, file:String = #file, funcName:String = #function, lineNum:Int = #line) -> Void {
    HDWindowLoggerSwift.printLog(log: log, logType: HDLogType.warn, file:file, funcName:funcName, lineNum:lineNum)
}
public func HDWarnLog(_ log:Any ..., file:String = #file, funcName:String = #function, lineNum:Int = #line) -> Void {
    HDWindowLoggerSwift.printLog(log: log, logType: HDLogType.warn, file:file, funcName:funcName, lineNum:lineNum)
}
//错误类型的输出
public func HDErrorLog(_ log:Any, file:String = #file, funcName:String = #function, lineNum:Int = #line) -> Void {
    HDWindowLoggerSwift.printLog(log: log, logType: HDLogType.error, file:file, funcName:funcName, lineNum:lineNum)
}
public func HDErrorLog(_ log:Any ..., file:String = #file, funcName:String = #function, lineNum:Int = #line) -> Void {
    HDWindowLoggerSwift.printLog(log: log, logType: HDLogType.error, file:file, funcName:funcName, lineNum:lineNum)
}
//保密类型的输出
public func HDPrivacyLog(_ log:Any, file:String = #file, funcName:String = #function, lineNum:Int = #line) -> Void {
    HDWindowLoggerSwift.printLog(log: log, logType: HDLogType.privacy, file:file, funcName:funcName, lineNum:lineNum)
}
public func HDPrivacyLog(_ log:Any ..., file:String = #file, funcName:String = #function, lineNum:Int = #line) -> Void {
    HDWindowLoggerSwift.printLog(log: log, logType: HDLogType.privacy, file:file, funcName:funcName, lineNum:lineNum)
}

///log的输出
public class HDWindowLoggerSwift {
    public static var mCompleteLogOut = true    //是否完整输出日志文件名等调试内容
    public static var mDebugAreaLogOut = true   //是否在xcode底部的调试栏同步输出内容
    public static var mPrivacyPassword = ""     //解密隐私数据的密码，默认为空不加密
    public static var mLogExpiryDay = 7        //本地日志文件的有效期（天），超出有效期的本地日志会被删除，0为没有有效期，默认为7天
    public static var mMaxShowCount = 100       //屏幕最大的显示数量，适量即可，0为不限制
    public private(set) var mLogDataArray = [HDWindowLoggerItem]()  //输出的日志信息
    public static let shared = HDWindowLoggerSwift()
    
    //MARK: Private
    private var mWindow: HDLoggerWindow?
    private let logQueue = DispatchQueue(label: "HDWindowLogger")
    var mPasswordCorrect: Bool = false
    
    //log的Public函数
    /// 根据日志的输出类型去输出相应的日志，不同日志类型颜色不一样
    /// - Parameter log: 日志内容
    /// - Parameter logType: 日志类型
    public class func printLog(log:Any, logType:HDLogType, file:String = #file, funcName:String = #function, lineNum:Int = #line) -> Void {
        self.shared.logQueue.sync {
            if self.shared.mLogDataArray.isEmpty {
                //第一条信息
                let loggerItem = HDWindowLoggerItem()
                loggerItem.mLogItemType = HDLogType.warn
                loggerItem.mCreateDate = Date()
                loggerItem.mLogContent = NSLocalizedString("HDWindowLogger: 点击对应日志可快速复制", comment: "")
                self.shared.mLogDataArray.append(loggerItem)
            }
            let loggerItem = HDWindowLoggerItem()
            loggerItem.mLogItemType = logType
            loggerItem.mCreateDate = Date()

            let fileName = (file as NSString).lastPathComponent;
            loggerItem.mLogDebugContent = "[File:\(fileName)]:[Line:\(lineNum):[Function:\(funcName)]]-Log:"
            loggerItem.mLogContent = log

            if logType == .debug {
                print(loggerItem.getFullContentString())
            } else {
                if self.mDebugAreaLogOut {
                    print(loggerItem.getFullContentString())
                }
                self.shared.mLogDataArray.append(loggerItem)
                //写入文件
                DispatchQueue.global().async {
                    self.p_writeFile(log: loggerItem.getFullContentString())
                }
                if self.mMaxShowCount != 0 && self.shared.mLogDataArray.count > self.mMaxShowCount {
                    self.shared.mLogDataArray.removeFirst()
                }
                //显示在主界面时才刷新列表
                DispatchQueue.main.async {
                    self.shared.mWindow?.updateUI(modelList: self.shared.mLogDataArray)
                }
            }
        }
    }
    
    ///  删除log日志
    public class func cleanLog() {
        self.shared.mLogDataArray.removeAll()
        DispatchQueue.main.async {
            self.shared.mWindow?.cleanLog()
        }
    }
    
    /// 显示log窗口
    public class func show() {
        DispatchQueue.main.async {
            if self.shared.mWindow == nil {
                if #available(iOS 13.0, *) {
                    for windowScene:UIWindowScene in ((UIApplication.shared.connectedScenes as? Set<UIWindowScene>)!) {
                        if windowScene.activationState == .foregroundActive {
                            self.shared.mWindow = HDLoggerWindow(windowScene: windowScene)
                        }
                    }
                }
                self.shared.mWindow = HDLoggerWindow(frame: CGRect.zero)
                //首次展示更新一次历史内容
                self.shared.mWindow?.updateUI(modelList: self.shared.mLogDataArray)
            }
            self.shared.mWindow?.show()
        }
    }
    
    /// 只隐藏log的输出窗口，保留悬浮图标
    public class func hideLogWindow() {
        DispatchQueue.main.async {
            self.shared.mWindow?.hideLogWindow()
        }
    }

    ///  隐藏整个log窗口
    public class func hide() {
        DispatchQueue.main.async {
            self.shared.mWindow?.hide()
        }
    }

    /// 删除本地日志文件
    public class func deleteLogFile() {
        let cachePath = HDCommonTools.shared.getFileDirectory(type: .caches)
        
        if let enumer = FileManager.default.enumerator(atPath: cachePath.path) {
            while let file = enumer.nextObject() {
                if let file: String = file as? String {
                    if file.hasPrefix("HDWindowLogger-") {
                        let logFilePath = cachePath.appendingPathComponent(file, isDirectory: false)
                        try? FileManager.default.removeItem(at: logFilePath)
                    }
                }
            }
        }
    }

    //MARK: init
    init() {
        self.p_checkValidity()
    }
   
    
    private class func p_writeFile(log: String) -> Void {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        //文件路径
        let logFilePathURL = HDCommonTools.shared.getFileDirectory(type: .caches).appendingPathComponent("HDWindowLogger-\(dateString).txt", isDirectory: false)

        if FileManager.default.fileExists(atPath: logFilePathURL.path) {
            if let fileHandle = try? FileHandle(forWritingTo: logFilePathURL) {
                fileHandle.seekToEndOfFile()
                if let data = log.data(using: String.Encoding.utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            } else {
                try? log.write(to: logFilePathURL, atomically: false, encoding: String.Encoding.utf8)
            }
        } else {
            do {
                try log.write(to: logFilePathURL, atomically: false, encoding: String.Encoding.utf8)
            } catch {
                print(error)
            }
        }
    }
    
    private func p_checkValidity() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let cachePath = HDCommonTools.shared.getFileDirectory(type: .caches)

        if let enumer = FileManager.default.enumerator(atPath: cachePath.path) {
            while let file = enumer.nextObject() {
                if let file: String = file as? String {
                    if file.hasPrefix("HDWindowLogger-") {
                        //截取日期
                        let index2 = file.index(file.startIndex, offsetBy: 15)
                        let index3 = file.index(file.startIndex, offsetBy: 24)
                        let dateString = file[index2...index3]
                        let fileDate = dateFormatter.date(from: String(dateString))
                        if let fileDate = fileDate {
                            if Date().timeIntervalSince(fileDate) > Double(Self.mLogExpiryDay * 3600 * 24) {
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

