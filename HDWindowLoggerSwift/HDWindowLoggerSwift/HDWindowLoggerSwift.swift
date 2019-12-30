//
//  HDWindowLoggerSwift.swift
//  HDWindowLoggerSwift
//
//  Created by Damon on 2019/6/24.
//  Copyright © 2019 Damon. All rights reserved.
//

import UIKit
import CommonCrypto

///快速输出log
//普通类型的输出
public func HDNormalLog(_ log:Any, file:String = #file, funcName:String = #function, lineNum:Int = #line) -> Void {
    HDWindowLoggerSwift.printLog(log: log, logType: HDLogType.kHDLogTypeNormal, file:file, funcName:funcName, lineNum:lineNum)
}
//警告类型的输出
public func HDWarnLog(_ log:Any, file:String = #file, funcName:String = #function, lineNum:Int = #line) -> Void {
    HDWindowLoggerSwift.printLog(log: log, logType: HDLogType.kHDLogTypeWarn, file:file, funcName:funcName, lineNum:lineNum)
}
//错误类型的输出
public func HDErrorLog(_ log:Any, file:String = #file, funcName:String = #function, lineNum:Int = #line) -> Void {
    HDWindowLoggerSwift.printLog(log: log, logType: HDLogType.kHDLogTypeError, file:file, funcName:funcName, lineNum:lineNum)
}
//保密类型的输出
public func HDPrivacyLog(_ log:Any, file:String = #file, funcName:String = #function, lineNum:Int = #line) -> Void {
    HDWindowLoggerSwift.printLog(log: log, logType: HDLogType.kHDLogTypePrivacy, file:file, funcName:funcName, lineNum:lineNum)
}

///log的级别，对应不同的颜色
public enum HDLogType : Int {
    case kHDLogTypeNormal = 0   //textColor #50d890
    case kHDLogTypeWarn         //textColor #f6f49d
    case kHDLogTypeError        //textColor #ff7676
    case kHDLogTypePrivacy      //textColor #42e6a4
}

///log的内容
public class HDWindowLoggerItem {
    public var mLogItemType = HDLogType.kHDLogTypeNormal    //log类型
    public var mLogDebugContent: String = ""                //log在文件中的调试内容
    public var mLogContent: Any?                         //log的内容
    
    public var mCreateDate = Date()
    public func getFullContentString() -> String {
        //日期
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss.SSS"
        let dateStr = dateFormatter.string(from: mCreateDate)
        //内容
        var contentString = ""
        if self.mLogItemType == .kHDLogTypePrivacy {
            if let mContent = mLogContent  {
                if mContent is LogContent {
                    contentString = (mContent as! LogContent).logStringValue
                } else if JSONSerialization.isValidJSONObject(mContent) {
                    let data = try? JSONSerialization.data(withJSONObject: mContent, options:JSONSerialization.WritingOptions.prettyPrinted)
                    contentString =  String(data: data ?? Data(), encoding: String.Encoding.utf8) ?? "\(mContent)"
                } else {
                    contentString = "\(mContent)"
                }
                if !HDWindowLoggerSwift.defaultWindowLogger.mPasswordCorrect {
                    contentString = NSLocalizedString("该内容已加密，请解密后查看", comment: "")
                }
                if !HDWindowLoggerSwift.mPrivacyPassword.isEmpty && HDWindowLoggerSwift.mPrivacyPassword.count != kCCKeySizeAES256 {
                    contentString = NSLocalizedString("密码设置长度错误，需要32个字符", comment: "")
                }
            }
        } else {
            if let mContent = mLogContent  {
                if mContent is LogContent {
                    contentString = (mContent as! LogContent).logStringValue
                }  else if JSONSerialization.isValidJSONObject(mContent) {
                    let data = try? JSONSerialization.data(withJSONObject: mContent, options:JSONSerialization.WritingOptions.prettyPrinted)
                    contentString =  String(data: data ?? Data(), encoding: String.Encoding.utf8) ?? "\(mContent)"
                } else {
                    contentString = "\(mContent)"
                }
            }
        }
        if HDWindowLoggerSwift.mCompleteLogOut {
            return dateStr + "  >   " +  mLogDebugContent + "\n" + contentString
        } else {
            return dateStr + "  >   " + contentString
        }
        
    }
}

///log的输出
public class HDWindowLoggerSwift: UIWindow, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UITextFieldDelegate {
    public static var mCompleteLogOut = true  //是否完整输出日志文件名等调试内容
    public static var mDebugAreaLogOut = true  //是否在xcode底部的调试栏同步输出内容
    public static var mPrivacyPassword = ""    //解密隐私数据的密码，默认为空不加密
    public static let defaultWindowLogger = HDWindowLoggerSwift(frame: CGRect.zero)
    public private(set) var mLogDataArray  = [HDWindowLoggerItem]()
    
    //密码解锁是否正确
    fileprivate var mPasswordCorrect: Bool {
        get {
            return self.mTextPassword == HDWindowLoggerSwift.mPrivacyPassword
        }
    }
    
    private var mFilterIndexArray = [IndexPath]()
    private var mMaxLogCount = 0        //限制日志数，默认为0不限制
    private var mTextPassword = ""      //输入的密码
    private var mCurrentSearchIndex = 0 //当前搜索到的索引
    
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
    
    lazy var mPasswordTextField: UITextField = {
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
        button.backgroundColor = UIColor(red: 66.0/255.0, green: 230.0/255.0, blue: 164.0/255.0, alpha: 1.0)
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
        switchLabel.textAlignment = NSTextAlignment.left
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
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        DispatchQueue.main.async {
            var statusBarHeight: CGFloat = 0
            if #available(iOS 13.0, *) {
                statusBarHeight = self.windowScene?.statusBarManager?.statusBarFrame.size.height ?? 0
            } else {
                statusBarHeight = UIApplication.shared.statusBarFrame.size.height
            }
            self.frame = CGRect(x: 0, y: statusBarHeight, width: UIScreen.main.bounds.size.width, height: 342)
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
        //私密解锁
        self.mBGView.addSubview(self.mPasswordTextField)
        self.mPasswordTextField.frame = CGRect(x: 0, y: 40, width: UIScreen.main.bounds.size.width/3.0 + 50, height: 40)
        self.mBGView.addSubview(self.mPasswordButton)
        self.mPasswordButton.frame = CGRect(x: UIScreen.main.bounds.size.width/3.0 + 50, y: 40, width: UIScreen.main.bounds.size.width/3.0 - 50, height: 40)
        //开关视图
        self.mBGView.addSubview(self.mSwitchLabel)
        self.mSwitchLabel.frame = CGRect(x: UIScreen.main.bounds.size.width*2.0/3.0 + 6, y: 40, width: 90, height: 40)
        self.mBGView.addSubview(self.mAutoScrollSwitch)
        self.mAutoScrollSwitch.frame = CGRect(x: UIScreen.main.bounds.size.width - 60, y: 45, width: 60, height: 40)
        //滚动日志窗
        self.mBGView.addSubview(self.mTableView)
        self.mTableView.frame = CGRect(x: 0, y: 80, width: UIScreen.main.bounds.size.width, height: 220)
        
        //搜索框
        self.mBGView.addSubview(self.mSearchBar)
        self.mSearchBar.frame = CGRect(x: 0, y: 300, width: UIScreen.main.bounds.size.width - 180, height: 40)
        
        self.mBGView.addSubview(self.mPreviousButton)
        self.mPreviousButton.frame = CGRect(x: UIScreen.main.bounds.size.width - 180, y: 300, width: 60, height: 40)
        
        self.mBGView.addSubview(self.mNextButton)
        self.mNextButton.frame = CGRect(x: UIScreen.main.bounds.size.width - 120, y: 300, width: 60, height: 40)
        
        self.mBGView.addSubview(self.mSearchNumLabel)
        self.mSearchNumLabel.frame = CGRect(x: UIScreen.main.bounds.size.width - 60, y: 300, width: 60, height: 40)
    }
    
    //MAKR:UITextFieldDelegate
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        self.mTextPassword = textField.text ?? ""
        self.p_decrypt()
        return true
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
            loggerCell!.updateWithLoggerItem(loggerItem: loggerItem, searchText: self.mSearchBar.text ?? "")
        }
        return loggerCell ?? UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: identifier)
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let loggerItem = self.mLogDataArray[indexPath.row]
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 13)
        label.text = loggerItem.getFullContentString()
        let size = label.sizeThatFits(CGSize(width: UIScreen.main.bounds.size.width, height: CGFloat(MAXFLOAT)))
        return ceil(size.height) + 1
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
    
    
    
    //MARK:私有函数
    private func p_reloadFilter() {
        if self.mFilterIndexArray.count > 0 {
            UIView.performWithoutAnimation {
                self.mTableView.reloadRows(at: self.mFilterIndexArray, with: UITableView.RowAnimation.none)
            }
        }
        
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
                    UIView.performWithoutAnimation {
                        self.mTableView.reloadRows(at: self.mFilterIndexArray, with: UITableView.RowAnimation.none)
                    }
                    self.mPreviousButton.isEnabled = true
                    self.mNextButton.isEnabled = true
                    self.mCurrentSearchIndex = self.mFilterIndexArray.count - 1;
                    self.mSearchNumLabel.text = "\(self.mCurrentSearchIndex + 1)/\(self.mFilterIndexArray.count)"
                }
            }
        }
    }
    
    @objc func p_previous() -> Void {
        if (self.mFilterIndexArray.count > 0) {
            self.mCurrentSearchIndex = self.mCurrentSearchIndex - 1;
            if (self.mCurrentSearchIndex < 0) {
                self.mCurrentSearchIndex = self.mFilterIndexArray.count - 1;
            }
            self.mSearchNumLabel.text = "\(self.mCurrentSearchIndex + 1)/\(self.mFilterIndexArray.count)"
            self.mTableView .scrollToRow(at: IndexPath(row: self.mCurrentSearchIndex, section: 0), at: UITableView.ScrollPosition.top, animated: true)
        }
    }
    
    @objc func p_next() -> Void {
        if (self.mFilterIndexArray.count > 0) {
            self.mCurrentSearchIndex = self.mCurrentSearchIndex + 1;
            if (self.mCurrentSearchIndex == self.mFilterIndexArray.count) {
                self.mCurrentSearchIndex = 0;
            }
            self.mSearchNumLabel.text = "\(self.mCurrentSearchIndex + 1)/\(self.mFilterIndexArray.count)"
            self.mTableView .scrollToRow(at: IndexPath(row: self.mCurrentSearchIndex, section: 0), at: UITableView.ScrollPosition.top, animated: true)
        }
    }
    
    private func p_bindClick() {
        self.mHideButton.addTarget(self, action: #selector(p_hideLogWindow), for: UIControl.Event.touchUpInside)
        self.mCleanButton.addTarget(self, action: #selector(p_cleanLog), for: UIControl.Event.touchUpInside)
        self.mShareButton.addTarget(self, action: #selector(p_share), for: UIControl.Event.touchUpInside)
        self.mPasswordButton.addTarget(self, action: #selector(p_decrypt), for: UIControl.Event.touchUpInside)
        self.mPreviousButton.addTarget(self, action: #selector(p_previous), for: UIControl.Event.touchUpInside)
        self.mNextButton.addTarget(self, action: #selector(p_next), for: UIControl.Event.touchUpInside)
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
        
        //保存的内容
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss.SSS"
        
        var mutableArray = [Any]()
        for item in self.mLogDataArray {
            let dateStr = dateFormatter.string(from: item.mCreateDate) +  "  >   " +  item.mLogDebugContent
            mutableArray.append(dateStr)
            mutableArray.append(item.mLogContent ?? "")
        }
        //end
        
        //写入文件
        let jsonData = try? JSONSerialization.data(withJSONObject: mutableArray, options: JSONSerialization.WritingOptions.prettyPrinted)
        
        if HDWindowLoggerSwift.defaultWindowLogger.mPasswordCorrect {
            try? jsonData?.write(to: logFilePathURL, options: Data.WritingOptions.atomic)
        } else {
            let data = HDWindowLoggerTools().p_crypt(data: jsonData ?? Data(), password: HDWindowLoggerSwift.mPrivacyPassword, option: CCOperation(kCCEncrypt))
            let string = data.base64EncodedString()
            try? string.write(to: logFilePathURL, atomically: true, encoding: String.Encoding.utf8)
        }
        
        
        
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
    
    //解密
    @objc private func p_decrypt() {
        self.mPasswordTextField.resignFirstResponder()
        self.mSearchBar.resignFirstResponder()
        if self.mPasswordTextField.text != nil {
            self.mTableView.reloadData()
        }
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
        DispatchQueue.main.async {
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
            
            let fileName = (file as NSString).lastPathComponent;
            loggerItem.mLogDebugContent = "[File:\(fileName)]:[Line:\(lineNum):[Function:\(funcName)]]-Log:"
            loggerItem.mLogContent = log
            
            if self.mDebugAreaLogOut {
                print(loggerItem.getFullContentString())
            }
            self.defaultWindowLogger.mLogDataArray.append(loggerItem)
            if self.defaultWindowLogger.mMaxLogCount > 0 && self.defaultWindowLogger.mMaxLogCount > self.defaultWindowLogger.mMaxLogCount {
                self.defaultWindowLogger.mLogDataArray.removeFirst()
            }
            self.defaultWindowLogger.mTableView.reloadData()
            if self.defaultWindowLogger.mLogDataArray.count > 0 && self.defaultWindowLogger.mAutoScrollSwitch.isOn {
                DispatchQueue.main.async {
                    self.defaultWindowLogger.mTableView.scrollToRow(at: IndexPath(row: self.defaultWindowLogger.mLogDataArray.count - 1, section: 0), at: UITableView.ScrollPosition.bottom, animated: true)
                }
            }
            self.defaultWindowLogger.p_reloadFilter()
        }
    }
    
    ///  删除log日志
    public class func cleanLog() {
        self.defaultWindowLogger.mLogDataArray.removeAll()
        self.defaultWindowLogger.mFilterIndexArray.removeAll()
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

fileprivate class HDWindowLoggerTools: NSObject {
    let ivString = "abcdefghijklmnop";
    
    //AES256加密
    func AES256Encrypt(text: String, password: String) -> String {
        guard let data = text.data(using:String.Encoding.utf8) else { return "" }
        let encryptData = self.p_crypt(data: data, password: password, option: CCOperation(kCCEncrypt))
        return encryptData.base64EncodedString()
    }
    
    //AES256解密
    func AES256Decrypt(text: String, password: String) -> String {
        guard let data = Data(base64Encoded: text) else { return "" }
        let encryptData = self.p_crypt(data: data, password: password, option: CCOperation(kCCDecrypt))
        return String(data: encryptData, encoding: String.Encoding.utf8) ?? ""
    }
    
    func p_crypt(data: Data, password: String, option: CCOperation) -> Data {
        guard let iv = ivString.data(using:String.Encoding.utf8) else { return Data() }
        guard let key = password.data(using:String.Encoding.utf8) else { return Data() }
        
        let cryptLength = data.count + kCCBlockSizeAES128
        var cryptData   = Data(count: cryptLength)

        let keyLength = kCCKeySizeAES256
        let options   = CCOptions(kCCOptionPKCS7Padding)

        var bytesLength = Int(0)

        let status = cryptData.withUnsafeMutableBytes { cryptBytes in
            data.withUnsafeBytes { dataBytes in
                iv.withUnsafeBytes { ivBytes in
                    key.withUnsafeBytes { keyBytes in
                    CCCrypt(option, CCAlgorithm(kCCAlgorithmAES), options, keyBytes.baseAddress, keyLength, ivBytes.baseAddress, dataBytes.baseAddress, data.count, cryptBytes.baseAddress, cryptLength, &bytesLength)
                    }
                }
            }
        }

        guard UInt32(status) == UInt32(kCCSuccess) else {
            debugPrint("Error: Failed to crypt data. Status \(status)")
            return Data()
        }

        cryptData.removeSubrange(bytesLength..<cryptData.count)
        return cryptData
    }
}
