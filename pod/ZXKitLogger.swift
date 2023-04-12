//
//  ZXKitLogger.swift
//  ZXKitLogger
//
//  Created by Damon on 2019/6/24.
//  Copyright © 2019 Damon. All rights reserved.
//

import UIKit
import ZXKitUtil

///log的级别，对应不同的颜色
public struct ZXKitLogType : OptionSet {
    public static let debug = ZXKitLogType([])        //only show in debug output
    public static let info = ZXKitLogType(rawValue: 1)    //textColor #50d890
    public static let warn = ZXKitLogType(rawValue: 2)         //textColor #f6f49d
    public static let error = ZXKitLogType(rawValue: 4)        //textColor #ff7676
    public static let privacy = ZXKitLogType(rawValue: 8)      //textColor #42e6a4

    public let rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

extension ZXKitLogType {
    func textColor() -> UIColor {
        switch self {
        case .debug:
            return UIColor.zx.color(hexValue: 0xD1B6E1)
        case .info:
            return UIColor(red: 80.0/255.0, green: 216.0/255.0, blue: 144.0/255.0, alpha: 1.0)
        case .warn:
            return UIColor(red: 246.0/255.0, green: 244.0/255.0, blue: 157.0/255.0, alpha: 1.0)
        case .error:
            return UIColor.zx.color(hexValue: 0xFFAFAF)
        case .privacy:
            return UIColor(red: 66.0/255.0, green: 230.0/255.0, blue: 164.0/255.0, alpha: 1.0)
        default:
            return UIColor.black
        }
    }

    func typeName() -> String {
        switch self {
            case .debug:
                return "debug"
            case .info:
                return "info"
            case .warn:
                return "warn"
            case .error:
                return "error"
            case .privacy:
                return "privacy"
            default:
                return "none"
        }
    }
}

public extension NSNotification.Name {
    static let ZXKitLogDBUpdate = NSNotification.Name("ZXKitLogDBUpdate")
}

/////测试输出，不会写入到悬浮窗中
public func printDebug(_ log:Any, file:String = #file, funcName:String = #function, lineNum:Int = #line) -> Void {
    ZXKitLogger.printLog(log: log, logType: ZXKitLogType.debug, file:file, funcName:funcName, lineNum:lineNum)
}
public func printDebug(_ log:Any ..., file:String = #file, funcName:String = #function, lineNum:Int = #line) -> Void {
    ZXKitLogger.printLog(log: log, logType: ZXKitLogType.debug, file:file, funcName:funcName, lineNum:lineNum)
}
//普通输出，默认为info和printInfo一致
public func printLog(_ log:Any, file:String = #file, funcName:String = #function, lineNum:Int = #line) -> Void {
    ZXKitLogger.printLog(log: log, logType: ZXKitLogType.info, file:file, funcName:funcName, lineNum:lineNum)
}
public func printLog(_ log:Any ..., file:String = #file, funcName:String = #function, lineNum:Int = #line) -> Void {
    ZXKitLogger.printLog(log: log, logType: ZXKitLogType.info, file:file, funcName:funcName, lineNum:lineNum)
}
//普通类型的输出
public func printInfo(_ log:Any, file:String = #file, funcName:String = #function, lineNum:Int = #line) -> Void {
    ZXKitLogger.printLog(log: log, logType: ZXKitLogType.info, file:file, funcName:funcName, lineNum:lineNum)
}
public func printInfo(_ log:Any ..., file:String = #file, funcName:String = #function, lineNum:Int = #line) -> Void {
    ZXKitLogger.printLog(log: log, logType: ZXKitLogType.info, file:file, funcName:funcName, lineNum:lineNum)
}
//警告类型的输出
public func printWarn(_ log:Any, file:String = #file, funcName:String = #function, lineNum:Int = #line) -> Void {
    ZXKitLogger.printLog(log: log, logType: ZXKitLogType.warn, file:file, funcName:funcName, lineNum:lineNum)
}
public func printWarn(_ log:Any ..., file:String = #file, funcName:String = #function, lineNum:Int = #line) -> Void {
    ZXKitLogger.printLog(log: log, logType: ZXKitLogType.warn, file:file, funcName:funcName, lineNum:lineNum)
}
//错误类型的输出
public func printError(_ log:Any, file:String = #file, funcName:String = #function, lineNum:Int = #line) -> Void {
    ZXKitLogger.printLog(log: log, logType: ZXKitLogType.error, file:file, funcName:funcName, lineNum:lineNum)
}
public func printError(_ log:Any ..., file:String = #file, funcName:String = #function, lineNum:Int = #line) -> Void {
    ZXKitLogger.printLog(log: log, logType: ZXKitLogType.error, file:file, funcName:funcName, lineNum:lineNum)
}
//加密类型的输出
public func printPrivacy(_ log:Any, file:String = #file, funcName:String = #function, lineNum:Int = #line) -> Void {
    ZXKitLogger.printLog(log: log, logType: ZXKitLogType.privacy, file:file, funcName:funcName, lineNum:lineNum)
}
public func printPrivacy(_ log:Any ..., file:String = #file, funcName:String = #function, lineNum:Int = #line) -> Void {
    ZXKitLogger.printLog(log: log, logType: ZXKitLogType.privacy, file:file, funcName:funcName, lineNum:lineNum)
}

///log的输出
public class ZXKitLogger {
    public static let shared = ZXKitLogger()
    public static var isFullLogOut = true    //是否完整输出日志文件名等调试内容
    
    public static var isSyncConsole = true   //是否在xcode底部的调试栏同步输出内容
    public static var storageLevels: ZXKitLogType = [.info, .warn, .error, .privacy]    //存储到数据库的级别
    public static var logExpiryDay = 30        //本地日志文件的有效期（天），超出有效期的本地日志会被删除，0为没有有效期，默认为30天
    public static var userID = "0"             //为不同用户创建的独立的日志库
    public static var DBParentFolder = ZXKitUtil.shared.getFileDirectory(type: .documents)
    public static var uploadComplete: ((URL) ->Void)?   //点击上传日志的回调
    /*隐私数据采用AESCBC加密
     *需要设置密码privacyLogPassword
     *初始向量privacyLogIv
     *结果编码类型可以选择base64和hex编码
     **/
    public static var privacyLogPassword = "12345678901234561234567890123456"
    public static var privacyLogIv = "abcdefghijklmnop"
    public static var privacyResultEncodeType = ZXKitUtilEncodeType.hex

    /**
     如果集成实时日志功能
     */
    #if canImport(CocoaAsyncSocket)
    public static var isTCP: Bool = true //是否TCP链接，UDP在iOS14以后需要向App Store申请权限
    public static var socketPort: UInt16 = 888 //连接的端口
    public static var socketDomain: String = "local" //支持自定义
    public static var socketType: String = "_zxkitlogger"//支持自定义
    #endif

    //MARK: 内部
    static var fileSelectedComplete: ((URL, String) ->Void)?   //选择历史文件过滤回调

    //MARK: - Private变量
    private lazy var loggerWindow: ZXKitLoggerWindow? = {
        var window: ZXKitLoggerWindow?
        if #available(iOS 13.0, *) {
            for windowScene:UIWindowScene in ((UIApplication.shared.connectedScenes as? Set<UIWindowScene>)!) {
                if windowScene.activationState == .foregroundActive {
                    window = ZXKitLoggerWindow(windowScene: windowScene)
                }
            }
        }
        if window == nil {
            window = ZXKitLoggerWindow(frame: CGRect.zero)
        }
        return window
    }()
    private lazy var pickerWindow: ZXKitLoggerPickerWindow? = {
        var window: ZXKitLoggerPickerWindow?
        if #available(iOS 13.0, *) {
            for windowScene:UIWindowScene in ((UIApplication.shared.connectedScenes as? Set<UIWindowScene>)!) {
                if windowScene.activationState == .foregroundActive {
                    window = ZXKitLoggerPickerWindow(windowScene: windowScene)
                }
            }
        }
        if window == nil {
            window = ZXKitLoggerPickerWindow(frame: CGRect.zero)
        }
        return window
    }()
    private var floatWindow: ZXKitLoggerFloatWindow?
    var isPasswordCorrect: Bool = false
    private let logQueue = DispatchQueue(label:"com.ZXKitLogger.logQueue", qos:.utility, attributes:.concurrent)

    //MARK: - Public函数
    /// 根据日志的输出类型去输出相应的日志，不同日志类型颜色不一样
    /// - Parameter log: 日志内容
    /// - Parameter logType: 日志类型
    public class func printLog(log:Any, logType:ZXKitLogType, file:String = #file, funcName:String = #function, lineNum:Int = #line) -> Void {
        shared.logQueue.async(group: nil, qos: .default, flags: .barrier) {
            let loggerItem = ZXKitLoggerItem()
            loggerItem.mLogItemType = logType
            loggerItem.mCreateDate = Date()

            let fileName = (file as NSString).lastPathComponent;
            loggerItem.mLogDebugContent = "File: \(fileName) -- Line: \(lineNum) -- Function:\(fileName).\(funcName) ----"
            loggerItem.mLogContent = log

            if self.isSyncConsole {
                print(loggerItem.getFullContentString())
            }
            //刷新列表
            DispatchQueue.main.async {
                self.shared.loggerWindow?.insert(model: loggerItem)
            }
            //写入文件
            if self.storageLevels.contains(logType) {
                self.shared._writeDB(log: loggerItem)
            }
            #if canImport(CocoaAsyncSocket)
            DispatchQueue.global().async {
                if ZXKitLogger.isTCP {
                    ZXKitLoggerTCPSocketManager.shared.send(loggerItem: loggerItem)
                } else {
                    ZXKitLoggerUDPSocketManager.shared.send(loggerItem: loggerItem)
                }
            }
            #endif
        }
    }
    
    ///获取log日志数组
    public class func getAllLog(date: Date? = nil, keyword: String? = nil, type: ZXKitLogType? = nil) -> [ZXKitLoggerItem] {
        if let date = date {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: date)
            return HDSqliteTools.shared.getAllLog(name: dateString, keyword: keyword, type: type)
        } else {
            return HDSqliteTools.shared.getAllLog(name: nil, keyword: keyword, type: type)
        }
    }

    ///获取log日志的数据库
    public class func getDBFolder() -> URL {
        return HDSqliteTools.shared.getDBFolder()
    }

    ///获取log日志的数据库文件
    public class func getDBFile(date: Date) -> URL {
        let dbFolder = self.getDBFolder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        let logFilePath = dbFolder.appendingPathComponent("\(dateString).db", isDirectory: false)
        return logFilePath
    }

    public class func getItemCount(type: ZXKitLogType?) -> Int {
        return HDSqliteTools.shared.getItemCount(type: type)
    }
    
    ///  删除log日志
    public class func cleanLog() {
        DispatchQueue.main.async {
            self.shared.loggerWindow?.cleanDataArray()
        }
    }
    
    /// 显示log窗口
    public class func show(filterType: ZXKitLogType? = nil) {
        DispatchQueue.main.async {
            self.shared.floatWindow?.isHidden = true
            self.shared.loggerWindow?.isHidden = false
            self.shared.loggerWindow?.filterType = filterType
        }
    }
    
    /// 只隐藏log的输出窗口，保留悬浮图标
    public class func hide() {
        DispatchQueue.main.async {
            self.shared.loggerWindow?.isHidden = true
            self.shared.pickerWindow?.isHidden = true
            #if canImport(ZXKitCore)
            print(NSLocalizedString("The float button already exists", comment: ""))
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
            self.shared.pickerWindow?.isHidden = true
        }
    }

    /// 删除本地日志文件，如不指定则删除所有文件
    public class func deleteLogFile(date: Date? = nil) {
        if let date = date {
            try? FileManager.default.removeItem(at: self.getDBFile(date: date))
        } else {
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
    }

    ///显示分享弹窗
    public class func showShare(date: Date? = nil, isCloseWhenComplete: Bool = true) {
        self.shared.pickerWindow?.isHidden = date != nil
        self.shared.pickerWindow?.showPicker(pickType: .share, date: date, isCloseWhenComplete: isCloseWhenComplete)
    }

    ///显示上传弹窗
    public class func showUpload(date: Date? = nil, isCloseWhenComplete: Bool = true) {
        self.shared.pickerWindow?.isHidden = date != nil
        self.shared.pickerWindow?.showPicker(pickType: .upload, date: date, isCloseWhenComplete: isCloseWhenComplete)
    }

    ///选择的弹窗
    public class func showFileFilter(date: Date? = nil) {
        self.shared.pickerWindow?.isHidden = date != nil
        self.shared.pickerWindow?.showPicker(pickType: .filter, date: date, isCloseWhenComplete: false)
    }

    //MARK: init
    init() {
        if ZXKitLogger.logExpiryDay > 0 {
            self._checkValidity()
        }

        #if canImport(CocoaAsyncSocket)
        //发起服务
        ZXKitLoggerBonjour.shared.start()
        if ZXKitLogger.isTCP {
            ZXKitLoggerTCPSocketManager.shared.start()
        } else {
            ZXKitLoggerUDPSocketManager.shared.start()
        }
        #endif
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
                    if file.hasSuffix(".db") && file.count > 10 {
                        //截取日期
                        let index2 = file.startIndex
                        let index3 = file.index(index2, offsetBy: 9)
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
