//
//  HDWindowLoggerSwift.swift
//  HDWindowLoggerSwift
//
//  Created by Damon on 2019/6/24.
//  Copyright © 2019 Damon. All rights reserved.
//

import UIKit
import SnapKit
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
public class HDWindowLoggerSwift: UIWindow, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    public static var mCompleteLogOut = true  //是否完整输出日志文件名等调试内容
    public static var mDebugAreaLogOut = true  //是否在xcode底部的调试栏同步输出内容
    public static var mPrivacyPassword = ""    //解密隐私数据的密码，默认为空不加密
    public private(set) var mLogDataArray  = [HDWindowLoggerItem]()
    public var mLogExpiryDay = 7        //本地日志文件的有效期（天），超出有效期的本地日志会被删除，0为没有有效期，默认为7天
    //FIXME: shared为老的单例方式，使用shared新的命名
    public static let defaultWindowLogger = HDWindowLoggerSwift(frame: CGRect.zero)
    public static let shared = HDWindowLoggerSwift(frame: CGRect.zero)
    //MARK: Private
    //密码解锁是否正确
    var mPasswordCorrect: Bool {
        get {
            return self.mTextPassword == HDWindowLoggerSwift.mPrivacyPassword
        }
    }
    private var mMaxLogCount = 0         //设置窗口显示的日志数，默认为0不限制
    private var mFilterIndexArray = [IndexPath]()
    private var mTextPassword = ""      //输入的密码
    private var mCurrentSearchIndex = 0 //当前搜索到的索引
    private var mFileDateNameList = [String]() //可以分享的文件列表
    private var mShareFileName = "" //选中去分享的文件名
    
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
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.singleLine
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 10;
        return tableView
    }()
    
    private lazy var mCleanButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.backgroundColor = UIColor(red: 255.0/255.0, green: 118.0/255.0, blue: 118.0/255.0, alpha: 1.0)
        button.setTitle(NSLocalizedString("清除Log", comment: ""), for: UIControl.State.normal)
        return button
    }()
    
    private lazy var mScaleButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.backgroundColor = UIColor(red: 168.0/255.0, green: 223.0/255.0, blue: 101.0/255.0, alpha: 1.0)
        button.setTitle(NSLocalizedString("伸缩", comment: ""), for: UIControl.State.normal)
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
    
    private lazy var mPasswordTextField: UITextField = {
        let tTextField = UITextField()
        tTextField.delegate = self
        let arrtibutedString = NSMutableAttributedString(string: NSLocalizedString("输入密码查看加密数据", comment: ""), attributes: [NSAttributedString.Key.foregroundColor : UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 0.7), NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14)])
        tTextField.attributedPlaceholder = arrtibutedString
        tTextField.textColor = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        tTextField.layer.masksToBounds = true
        tTextField.layer.borderColor = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0).cgColor
        tTextField.layer.borderWidth = 1.0
        return tTextField
    }()
    
    private lazy var mPasswordButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.backgroundColor = UIColor(red: 27.0/255.0, green: 108.0/255.0, blue: 168.0/255.0, alpha: 1.0)
        button.setTitleColor(UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0), for: UIControl.State.normal)
        button.setTitle(NSLocalizedString("解密", comment: ""), for: UIControl.State.normal)
        button.layer.masksToBounds = true
        button.layer.borderColor = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0).cgColor
        button.layer.borderWidth = 1.0
        return button
    }()
    
    private lazy var mAutoScrollSwitch: UISwitch = {
        let autoScrollSwitch = UISwitch()
        autoScrollSwitch.setOn(true, animated: false)
        return autoScrollSwitch
    }()
    
    private lazy var mSwitchLabel: UILabel = {
        let switchLabel = UILabel()
        switchLabel.text = NSLocalizedString("自动滚动", comment: "")
        switchLabel.textAlignment = NSTextAlignment.center
        switchLabel.font = UIFont.systemFont(ofSize: 13)
        switchLabel.textColor = UIColor.white
        return switchLabel
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
    
    private lazy var mSearchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = NSLocalizedString("内容过滤查找", comment: "")
        searchBar.barStyle = UIBarStyle.default
        searchBar.backgroundImage = UIImage()
        searchBar.backgroundColor = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        searchBar.delegate = self
        return searchBar
    }()
    
    private lazy var mPreviousButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.backgroundColor = UIColor(red: 255.0/255.0, green: 118.0/255.0, blue: 118.0/255.0, alpha: 1.0)
        button.setTitleColor(UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0), for: UIControl.State.normal)
        button.setTitleColor(UIColor(red: 102.0/255.0, green: 102.0/255.0, blue: 102.0/255.0, alpha: 1.0), for: UIControl.State.disabled)
        button.setTitle(NSLocalizedString("上一条", comment: ""), for: UIControl.State.normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.isEnabled = false
        return button
    }()
    
    private lazy var mNextButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.backgroundColor = UIColor(red: 93.0/255.0, green: 174.0/255.0, blue: 139.0/255.0, alpha: 1.0)
        button.setTitleColor(UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0), for: UIControl.State.normal)
        button.setTitleColor(UIColor(red: 102.0/255.0, green: 102.0/255.0, blue: 102.0/255.0, alpha: 1.0), for: UIControl.State.disabled)
        button.setTitle(NSLocalizedString("下一条", comment: ""), for: UIControl.State.normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.isEnabled = false
        return button
    }()
    
    private lazy var mSearchNumLabel: UILabel = {
        let tLabel = UILabel()
        tLabel.text = NSLocalizedString("0条结果", comment: "")
        tLabel.textAlignment = NSTextAlignment.center
        tLabel.font = UIFont.systemFont(ofSize: 12)
        tLabel.textColor = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        tLabel.backgroundColor = UIColor(red: 57.0/255.0, green: 74.0/255.0, blue: 81.0/255.0, alpha: 1.0)
        return tLabel
    }()
    
    private lazy var mTipLabel: UILabel = {
        let tLabel = UILabel()
        tLabel.text = "HDWindowLogger Powered by DamonHu"
        tLabel.textAlignment = NSTextAlignment.center
        tLabel.font = UIFont.systemFont(ofSize: 12)
        tLabel.textColor = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 0.8)
        tLabel.backgroundColor = UIColor.clear
        return tLabel
    }()
    
    private lazy var mPickerBGView: UIView = {
        let tView = UIView()
        tView.backgroundColor = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        tView.isHidden = true
        tView.layer.masksToBounds = true
        tView.layer.borderColor = UIColor(red: 57.0/255.0, green: 74.0/255.0, blue: 81.0/255.0, alpha: 1.0).cgColor
        tView.layer.borderWidth = 1.0
        return tView
    }()
    
    private lazy var mPickerView: UIPickerView = {
        let tPicker = UIPickerView()
        tPicker.backgroundColor = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        tPicker.isUserInteractionEnabled = true
        tPicker.dataSource = self
        tPicker.delegate = self
        return tPicker
    }()
    
    private lazy var mToolBar: UIToolbar = {
        let tToolBar = UIToolbar()
        tToolBar.barStyle = .default
        return tToolBar
    }()
    
    //MARK: Public Method
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.rootViewController = UIViewController()
        self.windowLevel = UIWindow.Level.alert
        self.backgroundColor = UIColor.clear
        self.isUserInteractionEnabled = true
        self.createUI()
        self.p_bindClick()
        self.p_checkValidity()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    //MAKR:UITextFieldDelegate
    public func textFieldDidEndEditing(_ textField: UITextField) {
        self.mTextPassword = textField.text ?? ""
        self.p_decrypt()
    }
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.resignFirstResponder()
    }
    
    //MARK:UITableViewDelegate
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.mLogDataArray.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "loggerCellIdentifier"
        let loggerItem = self.mLogDataArray[indexPath.row]
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
            loggerCell!.updateWithLoggerItem(loggerItem: loggerItem, highlightText: self.mSearchBar.text ?? "")
        }
        return loggerCell ?? UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: identifier)
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let loggerItem = self.mLogDataArray[indexPath.row]
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
    
    //MARK: UIPickerViewDelegate
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
           return 1
    }
    
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.mFileDateNameList.count
    }
    
    public func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 40
    }
    
    public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var titleView: UIView
        if let label = view, label is UILabel {
            (label as! UILabel).text = self.mFileDateNameList[row]
            titleView = label
        } else {
            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
            label.text = self.mFileDateNameList[row]
            label.textAlignment = .center
            titleView = label
        }
        return titleView
    }
    
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.mShareFileName = self.mFileDateNameList[row]
    }
    
    //log的Public函数
    /// 根据日志的输出类型去输出相应的日志，不同日志类型颜色不一样
    /// - Parameter log: 日志内容
    /// - Parameter logType: 日志类型
    public class func printLog(log:Any, logType:HDLogType, file:String = #file, funcName:String = #function, lineNum:Int = #line) -> Void {
        DispatchQueue.main.async {
            if self.shared.mLogDataArray.isEmpty {
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

                //写入文件
                self.p_writeFile(log: loggerItem.getFullContentString())
                
                self.shared.mLogDataArray.append(loggerItem)
                if self.shared.mMaxLogCount > 0 && self.shared.mMaxLogCount > self.shared.mMaxLogCount {
                    self.shared.mLogDataArray.removeFirst()
                }
                
                self.shared.p_reloadFilter()
                if self.shared.mLogDataArray.count > 0 && self.shared.mAutoScrollSwitch.isOn {
                    DispatchQueue.main.async {
                        self.shared.mTableView.scrollToRow(at: IndexPath(row: self.shared.mLogDataArray.count - 1, section: 0), at: UITableView.ScrollPosition.bottom, animated: true)
                    }
                }
            }
        }
    }
    
    ///  删除log日志
    public class func cleanLog() {
        self.shared.mLogDataArray.removeAll()
        self.shared.mFilterIndexArray.removeAll()
        self.shared.mTableView.reloadData()
    }
    
    /// 显示log窗口
    public class func show() {
        self.shared.isHidden = false
        self.shared.isUserInteractionEnabled = true
        self.shared.mBGView.isHidden = false
        self.shared.mFloatWindow.isHidden = true
    }
    
    ///  隐藏整个log窗口
    public class func hide() {
        self.shared.isHidden = true
        self.shared.mBGView.isHidden = true
        self.shared.mFloatWindow.isHidden = true
    }
    
    /// 只隐藏log的输出窗口，保留悬浮图标
    public class func hideLogWindow() {
        self.shared.isUserInteractionEnabled = false
        self.shared.mBGView.isHidden = true
        self.shared.mFloatWindow.isHidden = false
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
    
    ///  为了节省内存，可以设置记录的最大的log数，超出限制删除最老的数据，默认100条
    /// - Parameter logCount: 0为不限制
    public class func setMaxLogCount(logCount:Int) -> Void {
        self.shared.mMaxLogCount = logCount
    }
    
    //MARK: Private Method
    private func createUI() {
        self.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 350)
        
        self.rootViewController?.view.addSubview(self.mBGView)
        self.mBGView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            if #available(iOS 11.0, *) {
                make.top.equalTo(self.rootViewController!.view.safeAreaLayoutGuide.snp.top)
            } else {
                make.top.equalTo(self.rootViewController!.topLayoutGuide.snp.bottom)
            }
        }
        //按钮
        self.mBGView.addSubview(self.mScaleButton)
        self.mScaleButton.snp.makeConstraints { (make) in
            make.left.top.equalToSuperview()
            make.width.equalTo(UIScreen.main.bounds.size.width/4.0)
            make.height.equalTo(40)
        }
        self.mBGView.addSubview(self.mHideButton)
        self.mHideButton.snp.makeConstraints { (make) in
            make.top.equalTo(self.mScaleButton)
            make.left.equalTo(self.mScaleButton.snp.right)
            make.width.equalTo(self.mScaleButton)
            make.height.equalTo(self.mScaleButton)
        }
        self.mBGView.addSubview(self.mShareButton)
        self.mShareButton.snp.makeConstraints { (make) in
            make.top.equalTo(self.mScaleButton)
            make.left.equalTo(self.mHideButton.snp.right)
            make.width.equalTo(self.mScaleButton)
            make.height.equalTo(self.mScaleButton)
        }
        self.mBGView.addSubview(self.mCleanButton)
        self.mCleanButton.snp.makeConstraints { (make) in
            make.top.equalTo(self.mScaleButton)
            make.left.equalTo(self.mShareButton.snp.right)
            make.width.equalTo(self.mScaleButton)
            make.height.equalTo(self.mScaleButton)
        }
        
        //私密解锁
        self.mBGView.addSubview(self.mPasswordTextField)
        self.mPasswordTextField.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.top.equalTo(self.mScaleButton.snp.bottom)
            make.width.equalTo(UIScreen.main.bounds.size.width/3.0 + 50)
            make.height.equalTo(40)
        }
        self.mBGView.addSubview(self.mPasswordButton)
        self.mPasswordButton.snp.makeConstraints { (make) in
            make.left.equalTo(self.mPasswordTextField.snp.right)
            make.top.equalTo(self.mPasswordTextField)
            make.width.equalTo(UIScreen.main.bounds.size.width/3.0 - 50)
            make.height.equalTo(40)
        }
        //开关视图
        self.mBGView.addSubview(self.mAutoScrollSwitch)
        self.mAutoScrollSwitch.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-10)
            make.centerY.equalTo(self.mPasswordButton)
        }
        self.mBGView.addSubview(self.mSwitchLabel)
        self.mSwitchLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self.mPasswordButton.snp.right)
            make.right.equalTo(self.mAutoScrollSwitch.snp.left)
            make.centerY.equalTo(self.mAutoScrollSwitch)
        }
        
        //滚动日志窗
        self.mBGView.addSubview(self.mTableView)
        self.mTableView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(self.mPasswordTextField.snp.bottom)
            make.bottom.equalToSuperview().offset(-60)
        }
        
        //搜索框
        self.mBGView.addSubview(self.mSearchBar)
        self.mSearchBar.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.top.equalTo(self.mTableView.snp.bottom)
            make.bottom.equalToSuperview().offset(-20)
            make.width.equalTo(UIScreen.main.bounds.size.width - 180)
        }
        
        self.mBGView.addSubview(self.mPreviousButton)
        self.mPreviousButton.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(self.mSearchBar)
            make.left.equalTo(self.mSearchBar.snp.right)
            make.width.equalTo(60)
        }
        
        self.mBGView.addSubview(self.mNextButton)
        self.mNextButton.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(self.mSearchBar)
            make.left.equalTo(self.mPreviousButton.snp.right)
            make.width.equalTo(60)
        }
        
        self.mBGView.addSubview(self.mSearchNumLabel)
        self.mSearchNumLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(self.mSearchBar)
            make.left.equalTo(self.mNextButton.snp.right)
            make.width.equalTo(60)
        }
        
        self.mBGView.addSubview(self.mTipLabel)
        self.mTipLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(self.mSearchBar.snp.bottom);
            make.bottom.equalToSuperview()
        }
        
        self.mBGView.addSubview(self.mPickerBGView)
        self.mPickerBGView.snp.makeConstraints { (make) in
            make.top.equalTo(self.mBGView)
            make.left.right.bottom.equalTo(self.mBGView)
        }
        
        let tipLabel = UILabel()
        tipLabel.text = NSLocalizedString("请选择要分享的日志", comment: "");
        tipLabel.font = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.medium)
        self.mPickerBGView.addSubview(tipLabel)
        tipLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(20)
            make.height.equalTo(40)
        }
        
        self.mPickerBGView.addSubview(self.mToolBar)
        self.mToolBar.snp.makeConstraints { (make) in
            make.top.equalTo(tipLabel.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(40)
        }
        self.mToolBar.layoutIfNeeded()
        
        let closeBarItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.cancel, target: self, action: #selector(p_closePicker))
        let fixBarItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let doneBarItem = UIBarButtonItem(title: NSLocalizedString("分享", comment: ""), style: UIBarButtonItem.Style.plain, target: self, action: #selector(p_confirmPicker))
        self.mToolBar.setItems([closeBarItem, fixBarItem, doneBarItem], animated: true)
        
        self.mPickerBGView.addSubview(self.mPickerView)
        self.mPickerView.snp.makeConstraints { (make) in
            make.top.equalTo(self.mToolBar.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        
    }
    
    private func p_reloadFilter() {
        self.mFilterIndexArray.removeAll()
        self.mPreviousButton.isEnabled = false
        self.mNextButton.isEnabled = false
        self.mSearchNumLabel.text = NSLocalizedString("0条结果", comment: "");
        
        let searchText = self.mSearchBar.text ?? "";
        if !searchText.isEmpty {
            let dataList = self.mLogDataArray
            for (index, item) in dataList.enumerated() {
                if item.getFullContentString().localizedCaseInsensitiveContains(searchText) {
                    let indexPath = IndexPath(row: index, section: 0)
                    self.mFilterIndexArray.append(indexPath)
                    self.mPreviousButton.isEnabled = true
                    self.mNextButton.isEnabled = true
                    self.mCurrentSearchIndex = self.mFilterIndexArray.count - 1;
                    self.mSearchNumLabel.text = "\(self.mCurrentSearchIndex + 1)/\(self.mFilterIndexArray.count)"
                }
            }
        }
        DispatchQueue.main.async {
            self.mTableView.reloadData()
        }
    }
    
    @objc private func p_previous() -> Void {
        if (self.mFilterIndexArray.count > 0) {
            self.mCurrentSearchIndex = self.mCurrentSearchIndex - 1;
            if (self.mCurrentSearchIndex < 0) {
                self.mCurrentSearchIndex = self.mFilterIndexArray.count - 1;
            }
            self.mSearchNumLabel.text = "\(self.mCurrentSearchIndex + 1)/\(self.mFilterIndexArray.count)"
            self.mTableView .scrollToRow(at: self.mFilterIndexArray[self.mCurrentSearchIndex], at: UITableView.ScrollPosition.top, animated: true)
        }
    }
    
    private func p_bindClick() {
        self.mScaleButton.addTarget(self, action: #selector(p_scale), for: UIControl.Event.touchUpInside)
        self.mHideButton.addTarget(self, action: #selector(p_hideLogWindow), for: UIControl.Event.touchUpInside)
        self.mCleanButton.addTarget(self, action: #selector(p_cleanLog), for: UIControl.Event.touchUpInside)
        self.mShareButton.addTarget(self, action: #selector(p_share), for: UIControl.Event.touchUpInside)
        self.mPasswordButton.addTarget(self, action: #selector(p_decrypt), for: UIControl.Event.touchUpInside)
        self.mPreviousButton.addTarget(self, action: #selector(p_previous), for: UIControl.Event.touchUpInside)
        self.mNextButton.addTarget(self, action: #selector(p_next), for: UIControl.Event.touchUpInside)
    }
    
    @objc private func p_next() -> Void {
        if (self.mFilterIndexArray.count > 0) {
            self.mCurrentSearchIndex = self.mCurrentSearchIndex + 1;
            if (self.mCurrentSearchIndex == self.mFilterIndexArray.count) {
                self.mCurrentSearchIndex = 0;
            }
            self.mSearchNumLabel.text = "\(self.mCurrentSearchIndex + 1)/\(self.mFilterIndexArray.count)"
            self.mTableView .scrollToRow(at: self.mFilterIndexArray[self.mCurrentSearchIndex], at: UITableView.ScrollPosition.top, animated: true)
        }
    }
    
    @objc private func p_touchMove(p:UIPanGestureRecognizer) {
        let panPoint = p.location(in: UIApplication.shared.keyWindow)
        if p.state == UIGestureRecognizer.State.changed {
            self.mFloatWindow.center = CGPoint(x: panPoint.x, y: panPoint.y)
        }
    }
    
    @objc private func p_scale() {
        self.mScaleButton.isSelected = !self.mScaleButton.isSelected;
        if (self.mScaleButton.isSelected) {
            self.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height - 20)
        } else {
            self.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 350)
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
    
    @objc private func p_closePicker() {
        self.mPickerBGView.isHidden = true
    }
    
    @objc private func p_confirmPicker() {
        self.mPickerBGView.isHidden = true
        let logFilePathURL = HDCommonTools.shared.getFileDirectory(type: .caches).appendingPathComponent(self.mShareFileName, isDirectory: false)
        //分享
        let activityVC = UIActivityViewController(activityItems: [logFilePathURL], applicationActivities: nil)
        if UIDevice.current.model == "iPad" {
            activityVC.modalPresentationStyle = UIModalPresentationStyle.popover
            activityVC.popoverPresentationController?.sourceView = self.mShareButton
            activityVC.popoverPresentationController?.sourceRect = self.mShareButton.frame
        }
        self.p_hideLogWindow()
        HDCommonTools.shared.getCurrentVC()?.present(activityVC, animated: true, completion: nil)
    }
    
    @objc private func p_share() {
        self.mFileDateNameList = [String]()
        let cacheDirectory = HDCommonTools.shared.getFileDirectory(type: .caches)
        
        if let enumer = FileManager.default.enumerator(at: cacheDirectory, includingPropertiesForKeys: [URLResourceKey.contentModificationDateKey]) {
            while let file = enumer.nextObject() {
                if let file: URL = file as? URL {
                    if file.lastPathComponent.hasPrefix("HDWindowLogger-") {
                        self.mFileDateNameList.append(file.lastPathComponent)
                    }
                }
            }
        }
        self.mPickerBGView.isHidden = !self.mPickerBGView.isHidden
        self.mPickerView.reloadAllComponents()
        self.mShareFileName = self.mFileDateNameList.first ?? ""
    }
    
    //解密
    @objc private func p_decrypt() {
        self.mPasswordTextField.resignFirstResponder()
        self.mSearchBar.resignFirstResponder()
        if self.mPasswordTextField.text != nil {
            self.mTableView.reloadData()
        }
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
                            if fileDate.timeIntervalSince(Date()) > Double(self.mLogExpiryDay * 3600 * 24) {
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
