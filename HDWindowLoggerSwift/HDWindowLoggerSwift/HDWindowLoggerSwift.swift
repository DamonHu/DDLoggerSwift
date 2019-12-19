//
//  HDWindowLoggerSwift.swift
//  HDWindowLoggerSwift
//
//  Created by Damon on 2019/6/24.
//  Copyright © 2019 Damon. All rights reserved.
//

import UIKit

///快速输出log
public func HDNormalLog(_ log:Any, file:String = #file, funcName:String = #function, lineNum:Int = #line) -> Void {
    HDWindowLoggerSwift.printLog(log: log, logType: HDLogType.kHDLogTypeNormal, file:file, funcName:funcName, lineNum:lineNum)
}

public func HDWarnLog(_ log:Any, file:String = #file, funcName:String = #function, lineNum:Int = #line) -> Void {
    HDWindowLoggerSwift.printLog(log: log, logType: HDLogType.kHDLogTypeWarn, file:file, funcName:funcName, lineNum:lineNum)
}

public func HDErrorLog(_ log:Any, file:String = #file, funcName:String = #function, lineNum:Int = #line) -> Void {
    HDWindowLoggerSwift.printLog(log: log, logType: HDLogType.kHDLogTypeError, file:file, funcName:funcName, lineNum:lineNum)
}

///log的级别，对应不同的颜色
public enum HDLogType : Int {
    case kHDLogTypeNormal = 0
    case kHDLogTypeWarn         //textColor #f6f49d
    case kHDLogTypeError        //textColor #ff7676
}

///log的内容
public class HDWindowLoggerItem {
    public var mLogItemType = HDLogType.kHDLogTypeNormal
    public var mLogContent: String?
    public var mCreateDate = Date()
    public func getFullContentString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss.SSS"
        let dateStr = dateFormatter.string(from: mCreateDate)
        var contentString = ""
        if let mContent = mLogContent  {
            contentString = mContent
        }
        return dateStr + "  >   " + contentString
    }
}

///log的输出
public class HDWindowLoggerSwift: UIWindow, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    public static var mCompleteLogOut = false  //是否完整输出日志文件名等调试内容
    public static var mDebugAreaLogOut = true  //是否在xcode底部的调试栏同步输出内容
    
    public static let defaultWindowLogger = HDWindowLoggerSwift(frame: CGRect.zero)
    public private(set) var mLogDataArray  = [HDWindowLoggerItem]()
    private var mFilterLogDataArray = [HDWindowLoggerItem]()
    private var mMaxLogCount = 0        //限制日志数，默认为0不限制
    
    private lazy var mBGView: UIView = {
        let mBGView = UIView()
        mBGView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.6)
        return mBGView
    }()
    private lazy var mTableView: UITableView = {
        let tableView = UITableView(frame: CGRect.zero, style: UITableView.Style.plain)
        tableView.scrollsToTop = true
        tableView.dataSource = self
        tableView.delegate = self
        tableView.showsHorizontalScrollIndicator = false
        tableView.showsVerticalScrollIndicator = true
        tableView.keyboardDismissMode = UIScrollView.KeyboardDismissMode.onDrag
        tableView.backgroundColor = UIColor.clear
        tableView.separatorColor = UIColor(red: 242.0/255.0, green: 242.0/255.0, blue: 240.0/255.0, alpha: 1.0)
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.singleLine
        return tableView
    }()
    
    private lazy var mCleanButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.backgroundColor = UIColor(red: 255.0/255.0, green: 118.0/255.0, blue: 118.0/255.0, alpha: 1.0)
        button.setTitle(NSLocalizedString("清除Log", comment: ""), for: UIControl.State.normal)
        return button
    }()
    
    private lazy var mHideButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.backgroundColor = UIColor(red: 93.0/255.0, green: 174.0/255.0, blue: 139.0/255.0, alpha: 1.0)
        button.setTitle(NSLocalizedString("隐藏", comment: ""), for: UIControl.State.normal)
        return button
    }()
    
    private lazy var mShareButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.backgroundColor = UIColor(red: 246.0/255.0, green: 244.0/255.0, blue: 157.0/255.0, alpha: 1.0)
        button.setTitleColor(UIColor(red: 255.0/255.0, green: 118.0/255.0, blue: 118.0/255.0, alpha: 1.0), for: UIControl.State.normal)
        button.setTitle(NSLocalizedString("分享", comment: ""), for: UIControl.State.normal)
        return button
    }()
    
    private lazy var mFloatWindow: UIWindow = {
        let floatWidow = UIWindow(frame: CGRect(x: UIScreen.main.bounds.size.width - 70, y: 50, width: 60, height: 60))
        floatWidow.rootViewController = UIViewController()
        floatWidow.windowLevel = UIWindow.Level.alert
        floatWidow.backgroundColor = UIColor.clear
        floatWidow.isUserInteractionEnabled = true
        
        let floatButton = UIButton(type: UIButton.ButtonType.custom)
        floatButton.backgroundColor = UIColor(red: 93.0/255.0, green: 174.0/255.0, blue: 139.0/255.0, alpha: 1.0)
        floatButton.setTitle(NSLocalizedString("H", comment: ""), for: UIControl.State.normal)
        floatButton.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        floatButton.layer.masksToBounds = true
        floatButton.layer.cornerRadius = 30.0
        floatButton.addTarget(self, action: #selector(p_show), for: UIControl.Event.touchUpInside)
        floatButton.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(p_touchMove(p:)))
        floatButton.addGestureRecognizer(pan)
        
        floatWidow.rootViewController?.view.addSubview(floatButton)
        return floatWidow
    }()
    
    private lazy var mAutoScrollSwitch: UISwitch = {
        let autoScrollSwitch = UISwitch()
        autoScrollSwitch.setOn(true, animated: false)
        return autoScrollSwitch
    }()
    
    private lazy var mSwitchLabel: UILabel = {
        let switchLabel = UILabel()
        switchLabel.text = NSLocalizedString("日志自动滚动", comment: "")
        switchLabel.textAlignment = NSTextAlignment.right
        switchLabel.font = UIFont.systemFont(ofSize: 13)
        switchLabel.textColor = UIColor.white
        return switchLabel
    }()
    
    private lazy var mSearchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = NSLocalizedString("内容过滤查找", comment: "")
        searchBar.barStyle = UIBarStyle.default
        searchBar.backgroundImage = UIImage()
        searchBar.backgroundColor = UIColor.white
        searchBar.delegate = self
        return searchBar
    }()
    
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        DispatchQueue.main.async {
            var statusBarHeight: CGFloat = 0
            if #available(iOS 13.0, *) {
                statusBarHeight = self.windowScene?.statusBarManager?.statusBarFrame.size.height ?? 0
            } else {
                statusBarHeight = UIApplication.shared.statusBarFrame.size.height
            }
            self.frame = CGRect(x: 0, y: statusBarHeight, width: UIScreen.main.bounds.size.width, height: 302)
            self.rootViewController = UIViewController()
            self.windowLevel = UIWindow.Level.alert
            self.backgroundColor = UIColor.clear
            self.isUserInteractionEnabled = true
            self.createUI()
            self.p_bindClick()
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    
    private func createUI() {
        self.rootViewController?.view.addSubview(self.mBGView)
        self.mBGView.frame = self.bounds
        //按钮
        self.mBGView.addSubview(self.mHideButton)
        self.mHideButton.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width/3.0, height: 40)
        self.mBGView.addSubview(self.mShareButton)
        self.mShareButton.frame = CGRect(x: UIScreen.main.bounds.size.width/3.0, y: 0, width: UIScreen.main.bounds.size.width/3.0, height: 40)
        self.mBGView.addSubview(self.mCleanButton)
        self.mCleanButton.frame = CGRect(x: UIScreen.main.bounds.size.width*2.0/3.0, y: 0, width: UIScreen.main.bounds.size.width/3.0, height: 40)
        
        //滚动日志窗
        self.mBGView.addSubview(self.mTableView)
        self.mTableView.frame = CGRect(x: 0, y: 40, width: UIScreen.main.bounds.size.width, height: 300-80)
        
        //开关视图
        self.mBGView.addSubview(self.mAutoScrollSwitch)
        self.mAutoScrollSwitch.frame = CGRect(x: UIScreen.main.bounds.size.width - 60, y: 40, width: 60, height: 40)
        self.mBGView.addSubview(self.mSwitchLabel)
        self.mSwitchLabel.frame = CGRect(x: UIScreen.main.bounds.size.width-155, y: 40, width: 90, height: 30)
        
        //搜索框
        self.mBGView.addSubview(self.mSearchBar)
        self.mSearchBar.frame = CGRect(x: 0, y: 300-40, width: UIScreen.main.bounds.size.width, height: 40)
    }
    
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.mFilterLogDataArray.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "loggerCellIdentifier"
        let loggerItem = self.mFilterLogDataArray[indexPath.row]
        var loggerCell = tableView.dequeueReusableCell(withIdentifier: identifier) as? HDLoggerSwiftTableViewCell
        if loggerCell == nil {
            loggerCell = HDLoggerSwiftTableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: identifier)
            loggerCell?.selectionStyle = UITableViewCell.SelectionStyle.none
        }
        if indexPath.row%2 != 0 {
            loggerCell?.backgroundColor = UIColor(red: 156.0/255.0, green: 44.0/255.0, blue: 44.0/255.0, alpha: 0.8)
        } else {
            loggerCell?.backgroundColor = UIColor.clear
        }
        if loggerCell != nil {
            loggerCell!.updateWithLoggerItem(loggerItem: loggerItem)
        }
        return loggerCell ?? UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: identifier)
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let loggerItem = self.mFilterLogDataArray[indexPath.row]
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 13)
        label.text = loggerItem.getFullContentString()
        let size = label.sizeThatFits(CGSize(width: UIScreen.main.bounds.size.width, height: CGFloat(MAXFLOAT)))
        return ceil(size.height) + 1
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let loggerItem = self.mFilterLogDataArray[indexPath.row]
        let pasteboard = UIPasteboard.general
        pasteboard.string = loggerItem.getFullContentString()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss.SSS"
        let dateStr = dateFormatter.string(from: loggerItem.mCreateDate)
        let tipString = dateStr + " " + NSLocalizedString("日志已拷贝到剪切板", comment: "")
        HDWarnLog(tipString)
    }
    
    //UISearchBarDelegate
    
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.p_reloadFilter()
    }
    
    public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    
    //私有函数
    private func p_reloadFilter() {
        self.mFilterLogDataArray.removeAll()
        let dataList = self.mLogDataArray
        for item in dataList {
            if self.mSearchBar.text != nil &&  !(self.mSearchBar.text!.isEmpty) {
                if item.getFullContentString().contains(self.mSearchBar.text!) {
                    self.mFilterLogDataArray.append(item)
                }
            } else {
                self.mFilterLogDataArray.append(item)
            }
        }
        self.mTableView.reloadData()
        if self.mFilterLogDataArray.count > 0 && self.mAutoScrollSwitch.isOn {
            let indexPath = IndexPath(row: self.mFilterLogDataArray.count - 1, section: 0)
            self.mTableView.scrollToRow(at: indexPath, at: UITableView.ScrollPosition.bottom, animated: true)
        }
    }
    
    private func p_bindClick() {
        self.mHideButton.addTarget(self, action: #selector(p_hideLogWindow), for: UIControl.Event.touchUpInside)
        self.mCleanButton.addTarget(self, action: #selector(p_cleanLog), for: UIControl.Event.touchUpInside)
        self.mShareButton.addTarget(self, action: #selector(p_share), for: UIControl.Event.touchUpInside)
    }
    
    @objc func p_touchMove(p:UIPanGestureRecognizer) {
        let panPoint = p.location(in: UIApplication.shared.keyWindow)
        if p.state == UIGestureRecognizer.State.changed {
            self.mFloatWindow.center = CGPoint(x: panPoint.x, y: panPoint.y)
        }
    }
    
    @objc private func p_show() {
        HDWindowLoggerSwift.show()
    }
    
    @objc private func p_hideLogWindow() {
        HDWindowLoggerSwift.hideLogWindow()
    }
    
    @objc private func p_cleanLog() {
        HDWindowLoggerSwift.cleanLog()
    }
    
    @objc private func p_share() {
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let documentDirectory = paths.first
        let logFilePath = "" + (documentDirectory ?? "") + "/HDWindowLogger.txt"
        let logFilePathURL = URL(fileURLWithPath: logFilePath)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss.SSS"
        var mutableArray = [String]()
        for item in self.mLogDataArray {
            let dateStr = dateFormatter.string(from: item.mCreateDate)
            mutableArray.append(dateStr)
            if let content = item.mLogContent {
                mutableArray.append(content)
            }
        }
        
        //写入文件
        let jsonData = try? JSONSerialization.data(withJSONObject: mutableArray, options: JSONSerialization.WritingOptions.prettyPrinted)
        try? jsonData?.write(to: logFilePathURL, options: Data.WritingOptions.atomic)
        
        //分享
        let activityVC = UIActivityViewController(activityItems: [logFilePathURL,jsonData as Any], applicationActivities: nil)
        if UIDevice.current.model == "iPad" {
            activityVC.modalPresentationStyle = UIModalPresentationStyle.popover
            activityVC.popoverPresentationController?.sourceView = self.mShareButton
            activityVC.popoverPresentationController?.sourceRect = self.mShareButton.frame
        }
        self.p_hideLogWindow()
        self.p_getCurrentVC().present(activityVC, animated: true, completion: nil)
    }
    
    private func p_getCurrentVC() -> UIViewController {
        var window = UIApplication.shared.keyWindow
        if window == nil || window?.windowLevel != UIWindow.Level.normal {
            let windowArray = UIApplication.shared.windows
            for tmpWin in windowArray {
                if tmpWin.windowLevel == UIWindow.Level.normal {
                    window = tmpWin
                    break;
                }
            }
        }
        var result: UIViewController
        if window!.subviews.count > 0 {
            let frontView = window?.subviews.first
            let nextResponder = frontView?.next
            if nextResponder is UIViewController {
                result = nextResponder as! UIViewController
            } else {
                result = (window?.rootViewController)!
            }
        } else {
            result = (window?.rootViewController)!
        }
        if result is UITabBarController {
            let viewController = result as! UITabBarController
            result = (viewController.selectedViewController)!
        }
        if result is UINavigationController {
            let viewController = result as! UINavigationController
            result = (viewController.visibleViewController)!
        }
        return result
    }
    
    //log的Public函数
    /// 根据日志的输出类型去输出相应的日志，不同日志类型颜色不一样
    /// - Parameter log: 日志内容
    /// - Parameter logType: 日志类型
    public class func printLog(log:Any, logType:HDLogType, file:String = #file, funcName:String = #function, lineNum:Int = #line) -> Void {
        if self.defaultWindowLogger.mLogDataArray.isEmpty {
            let loggerItem = HDWindowLoggerItem()
            loggerItem.mLogItemType = HDLogType.kHDLogTypeWarn
            loggerItem.mCreateDate = Date()
            loggerItem.mLogContent = NSLocalizedString("HDWindowLogger: 点击对应日志可快速复制", comment: "")
            self.defaultWindowLogger.mLogDataArray.append(loggerItem)
        }
        let loggerItem = HDWindowLoggerItem()
        loggerItem.mLogItemType = logType
        loggerItem.mCreateDate = Date()
        if self.mCompleteLogOut {
            let fileName = (file as NSString).lastPathComponent;
            if log is LogContent {
                loggerItem.mLogContent = "[File:\(fileName)]:[Line:\(lineNum):[Function:\(funcName)]]-Log:\n" + (log as! LogContent).logStringValue
            } else {
                loggerItem.mLogContent = "[File:\(fileName)]:[Line:\(lineNum):[Function:\(funcName)]]-Log:\n\(log)"
            }
        } else {
            if log is LogContent {
               loggerItem.mLogContent = (log as! LogContent).logStringValue
            } else {
                loggerItem.mLogContent = "\(log)"
            }
        }
        if self.mDebugAreaLogOut {
            if let content = loggerItem.mLogContent {
                print(content)
            }
        }
        self.defaultWindowLogger.mLogDataArray.append(loggerItem)
        if self.defaultWindowLogger.mMaxLogCount > 0 && self.defaultWindowLogger.mMaxLogCount > self.defaultWindowLogger.mMaxLogCount {
            self.defaultWindowLogger.mLogDataArray.removeFirst()
        }
        self.defaultWindowLogger.p_reloadFilter()
    }
    
    ///  删除log日志
    public class func cleanLog() {
        self.defaultWindowLogger.mLogDataArray.removeAll()
        self.defaultWindowLogger.mFilterLogDataArray.removeAll()
        self.defaultWindowLogger.mTableView.reloadData()
    }
    
    /// 显示log窗口
    public class func show() {
        self.defaultWindowLogger.isHidden = false
        self.defaultWindowLogger.isUserInteractionEnabled = true
        self.defaultWindowLogger.mBGView.isHidden = false
        self.defaultWindowLogger.mFloatWindow.isHidden = true
    }
    
    ///  隐藏整个log窗口
    public class func hide() {
        self.defaultWindowLogger.isHidden = true
        self.defaultWindowLogger.mBGView.isHidden = true
        self.defaultWindowLogger.mFloatWindow.isHidden = true
    }
    
    /// 只隐藏log的输出窗口，保留悬浮图标
    public class func hideLogWindow() {
        self.defaultWindowLogger.isUserInteractionEnabled = false
        self.defaultWindowLogger.mBGView.isHidden = true
        self.defaultWindowLogger.mFloatWindow.isHidden = false
    }
    
    ///  为了节省内存，可以设置记录的最大的log数，超出限制删除最老的数据，默认100条
    /// - Parameter logCount: 0为不限制
    public class func setMaxLogCount(logCount:Int) -> Void {
        self.defaultWindowLogger.mMaxLogCount = logCount
    }
    
}
