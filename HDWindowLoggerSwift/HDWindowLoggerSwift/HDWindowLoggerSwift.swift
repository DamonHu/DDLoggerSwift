//
//  HDWindowLoggerSwift.swift
//  HDWindowLoggerSwift
//
//  Created by Damon on 2019/6/24.
//  Copyright © 2019 Damon. All rights reserved.
//

import UIKit
import CommonCrypto
import SnapKit

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
    public var mCreateDate = Date()                      //log日期
    
    private var mCurrentHighlightString = ""            //当前需要高亮的字符串
    private var mCacheHasHighlightString = false        //上次查询是否包含高亮的字符串
    var mCacheHighlightCompleteString = NSMutableAttributedString()   //上次包含高亮支付的富文本
    
    
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
    
    //根据需要高亮内容查询组装高亮内容
    public func getHighlightAttributedString(highlightString: String, complete:(Bool, NSAttributedString)->Void) -> Void {
        if highlightString.isEmpty {
            //空的直接返回
            let contentString = self.getFullContentString()
            let newString = NSMutableAttributedString(string: contentString, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 13)])
            self.mCacheHighlightCompleteString = newString
            self.mCacheHasHighlightString = false
            complete(self.mCacheHasHighlightString, newString)
        } else if highlightString == self.mCurrentHighlightString{
            //和上次高亮相同，直接用之前的回调
            complete(self.mCacheHasHighlightString, self.mCacheHighlightCompleteString)
        } else {
            self.mCurrentHighlightString = highlightString
            let contentString = self.getFullContentString()
            let newString = NSMutableAttributedString(string: contentString, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 13)])
            let regx = try? NSRegularExpression(pattern: highlightString, options: NSRegularExpression.Options.caseInsensitive)
            if let searchRegx = regx {
                self.mCacheHasHighlightString = false;
                searchRegx.enumerateMatches(in: contentString, options: NSRegularExpression.MatchingOptions.reportCompletion, range: NSRange(location: 0, length: contentString.count)) { (result: NSTextCheckingResult?, flag, stop) in
                    newString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor(red: 255.0/255.0, green: 0.0, blue: 0.0, alpha: 1.0), range: result?.range ?? NSRange(location: 0, length: 0))
                    if result != nil {
                        self.mCacheHasHighlightString = true
                    }
                    self.mCacheHighlightCompleteString = newString
                    complete(self.mCacheHasHighlightString, newString)
                }
            } else {
                self.mCacheHighlightCompleteString = newString
                self.mCacheHasHighlightString = false
                complete(self.mCacheHasHighlightString, newString)
            }
        }
    }
}

///log的输出
public class HDWindowLoggerSwift: UIWindow, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UITextFieldDelegate {
    public static var mCompleteLogOut = true  //是否完整输出日志文件名等调试内容
    public static var mDebugAreaLogOut = true  //是否在xcode底部的调试栏同步输出内容
    public static var mPrivacyPassword = ""    //解密隐私数据的密码，默认为空不加密
    public private(set) var mLogDataArray  = [HDWindowLoggerItem]()
    
    static let defaultWindowLogger = HDWindowLoggerSwift(frame: CGRect.zero)
    
//    public static var defaultWindowLogger: HDWindowLoggerSwift {
//        struct DefaultWindow {
//            static let kWindowLogger: HDWindowLoggerSwift = { () -> HDWindowLoggerSwift in
//                return HDWindowLoggerSwift(frame: CGRect.zero)
//            }()
//        }
//        return DefaultWindow.kWindowLogger
//    }
    
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
        tLabel.text = "HDWindowLogger v2.0"
        tLabel.textAlignment = NSTextAlignment.center
        tLabel.font = UIFont.systemFont(ofSize: 12)
        tLabel.textColor = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        tLabel.backgroundColor = UIColor.clear
        return tLabel
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.rootViewController = UIViewController()
        self.windowLevel = UIWindow.Level.alert
        self.backgroundColor = UIColor.clear
        self.isUserInteractionEnabled = true
        self.createUI()
        self.p_bindClick()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
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
        self.mBGView.frame = self.bounds
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
    
    
    
    //MARK:私有函数
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
    
    @objc func p_previous() -> Void {
        if (self.mFilterIndexArray.count > 0) {
            self.mCurrentSearchIndex = self.mCurrentSearchIndex - 1;
            if (self.mCurrentSearchIndex < 0) {
                self.mCurrentSearchIndex = self.mFilterIndexArray.count - 1;
            }
            self.mSearchNumLabel.text = "\(self.mCurrentSearchIndex + 1)/\(self.mFilterIndexArray.count)"
            self.mTableView .scrollToRow(at: self.mFilterIndexArray[self.mCurrentSearchIndex], at: UITableView.ScrollPosition.top, animated: true)
        }
    }
    
    @objc func p_next() -> Void {
        if (self.mFilterIndexArray.count > 0) {
            self.mCurrentSearchIndex = self.mCurrentSearchIndex + 1;
            if (self.mCurrentSearchIndex == self.mFilterIndexArray.count) {
                self.mCurrentSearchIndex = 0;
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
    
    @objc func p_touchMove(p:UIPanGestureRecognizer) {
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
           
            self.defaultWindowLogger.p_reloadFilter()
            if self.defaultWindowLogger.mLogDataArray.count > 0 && self.defaultWindowLogger.mAutoScrollSwitch.isOn {
                DispatchQueue.main.async {
                    self.defaultWindowLogger.mTableView.scrollToRow(at: IndexPath(row: self.defaultWindowLogger.mLogDataArray.count - 1, section: 0), at: UITableView.ScrollPosition.bottom, animated: true)
                }
            }
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
