//
//  ZXKitLoggerWindow.swift
//  ZXKitLogger
//
//  Created by Damon on 2020/9/9.
//  Copyright © 2020 Damon. All rights reserved.
//

import UIKit
import SnapKit
import ZXKitUtil

func UIImageHDBoundle(named: String?) -> UIImage? {
    guard let name = named else { return nil }
    guard let bundlePath = Bundle(for: ZXKitLogger.self).path(forResource: "ZXKitLogger", ofType: "bundle") else { return nil }
    let bundle = Bundle(path: bundlePath)
    return UIImage(named: name, in: bundle, compatibleWith: nil)
}

class ZXKitLoggerWindow: UIWindow {
    private var mLogDataArray = [ZXKitLoggerItem]()  //输出的日志信息
    private var mFilterIndexArray = [IndexPath]()   //索引的排序
    private var mCurrentSearchIndex = 0             //当前搜索到的索引
    private var mFileDateNameList = [String]()      //可以分享的文件列表
    private var mShareFileName = ""                 //选中去分享的文件名

    override var isHidden: Bool {
        willSet {
            super.isHidden = newValue
            if !newValue {
                self.changeWindowFrame()
                if self.mLogDataArray.isEmpty {
                    //第一条信息
                    let loggerItem = ZXKitLoggerItem()
                    loggerItem.mLogItemType = ZXKitLogType.warn
                    loggerItem.mCreateDate = Date()
                    loggerItem.mLogContent = NSLocalizedString("ZXKitLogger: Click Log To Copy", comment: "")
                    self.mLogDataArray.append(loggerItem)
                }
                self._reloadFilter()
            }
        }
    }

    var isFullScreen = false {
        willSet {
            if (newValue) {
                self.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height - 70)
            } else {
                self.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 350)
            }
        }
    }


    //解密栏
    var isDecryptViewHidden = true {
        willSet {
            self.mPasswordTextField.isHidden = newValue
            self.mPasswordButton.isHidden = newValue
            if !newValue {
                self.mPasswordTextField.becomeFirstResponder()
            } else {
                self.mPasswordTextField.resignFirstResponder()
            }
        }
    }

    //滚动设置
    var isScrollViewHidden = true {
        willSet {
            self.mAutoScrollSwitch.isHidden = newValue
            self.mSwitchLabel.isHidden = newValue
        }
    }

    //搜索栏
    var isSearchViewHidden = true {
        willSet {
            self.mSearchBar.isHidden = newValue
            self.mPreviousButton.isHidden = newValue
            self.mNextButton.isHidden = newValue
            self.mSearchNumLabel.isHidden = newValue
            self.mSearchBar.text = nil
            if !newValue {
                self.mSearchBar.becomeFirstResponder()
            } else {
                self.mSearchBar.resignFirstResponder()
            }
        }
    }

    var isShowMenu = false {
        willSet {
            if newValue {
                UIView.transition(with: self.mContentBGView, duration: 0.8, options: UIView.AnimationOptions.transitionFlipFromLeft, animations: {
                    self.mContentBGView.alpha = 0
                }) { (finish) in
                    self.mContentBGView.isHidden = true
                    self.mMenuView.isHidden = false
                    self.mContentBGView.alpha = 1
                }

            } else {
                UIView.transition(with: self.mMenuView, duration: 0.8, options: UIView.AnimationOptions.transitionFlipFromRight, animations: {
                    self.mMenuView.alpha = 0
                }) { (finish) in
                    self.mContentBGView.isHidden = false
                    self.mMenuView.isHidden = true
                    self.mMenuView.alpha = 1
                }
            }
        }
    }


    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    @available(iOS 13.0, *)
    override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)
        self._init()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self._init()
    }

    func insert(model: ZXKitLoggerItem) {
        if ZXKitLogger.maxDisplayCount != 0 && self.mLogDataArray.count > ZXKitLogger.maxDisplayCount {
            self.mLogDataArray.removeFirst()
        }
        self.mLogDataArray.append(model)
        if !self.isHidden {
            self._reloadFilter(model: model)
        }
    }

    //
    func cleanDataArray() {
        self.mLogDataArray.removeAll()
        self.mFilterIndexArray.removeAll()
        self._reloadFilter()
    }


    
    //MARK: UI布局
    private lazy var mContentBGView: UIView = {
        let mContentBGView = UIView()
        mContentBGView.backgroundColor = UIColor.zx.color(hexValue: 0x000000, alpha: 0.6)
        return mContentBGView
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
        tableView.separatorColor = UIColor.zx.color(hexValue: 0xfcfcfc)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.singleLine
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 10
        tableView.register(ZXKitLoggerTableViewCell.self, forCellReuseIdentifier: "ZXKitLoggerTableViewCell")
        return tableView
    }()

    private lazy var mNormalStackView: UIStackView = {
        let titleList = [NSLocalizedString("Scale", comment: ""), NSLocalizedString("Hide", comment: ""), NSLocalizedString("Clean Log", comment: ""), NSLocalizedString("More", comment: "")]
        let colorList = [UIColor.zx.color(hexValue: 0x91c788), UIColor.zx.color(hexValue: 0xFF7676), UIColor.zx.color(hexValue: 0x5DAE8B), UIColor.zx.color(hexValue: 0x45526c)]
        var stackSubViews = [UIButton]()
        for i in 0..<titleList.count {
            let button = UIButton(type: .custom)
            button.addTarget(self, action: #selector(_bindClick(button:)), for: .touchUpInside)
            button.backgroundColor = colorList[i]
            button.setTitleColor(UIColor.zx.color(hexValue: 0xffffff), for: .normal)
            button.setTitle(titleList[i], for: .normal)
            button.tag = i
            stackSubViews.append(button)
        }
        let tStackView = UIStackView(arrangedSubviews: stackSubViews)
        tStackView.alignment = .fill
        tStackView.distribution = .fillEqually
        return tStackView
    }()

    private lazy var mMenuView: ZXKitLoggerMenuView = {
        let tMenuView = ZXKitLoggerMenuView()
        tMenuView.isHidden = true
        tMenuView.clickSubject = {(index) -> Void in
            self.isShowMenu = false
            self.isDecryptViewHidden = true
            self.isScrollViewHidden = true
            self.isSearchViewHidden = true
            switch index {
                case 0:
                    break
                case 1:
                    self.isDecryptViewHidden = false
                case 2:
                    self.isSearchViewHidden = false
                case 3:
                    self._share()
                case 4:
                    self.isScrollViewHidden = false
                case 5:
                    let folder = ZXKitLogger.getDBFolder()
                    let size = ZXKitUtil.shared.getFileDirectorySize(fileDirectoryPth: folder)
                    //数据库条数
                    var count = 0
                    if let enumer = FileManager.default.enumerator(at: folder, includingPropertiesForKeys: [URLResourceKey.creationDateKey]) {
                        while let file = enumer.nextObject() {
                            if let file: URL = file as? URL, file.lastPathComponent.hasSuffix(".db") {
                               count = count + 1
                            }
                        }
                    }
                    let info = "\n" + NSLocalizedString("current log count", comment: "") + ": \(self.mLogDataArray.count)" +  "\n" + NSLocalizedString("LogFile count", comment: "") + ": \(count)" + "\n" + NSLocalizedString("LogFile total size", comment: "") + ": \(size/1024.0)kb"
                    ZXWarnLog(info)
                default:
                    break
            }
        };
        return tMenuView
    }()
    
    private lazy var mPasswordTextField: UITextField = {
        let tTextField = UITextField()
        tTextField.backgroundColor = UIColor.zx.color(hexValue: 0x687980)
        tTextField.isHidden = true
        tTextField.isSecureTextEntry = true
        tTextField.delegate = self
        let arrtibutedString = NSMutableAttributedString(string: NSLocalizedString("Enter password to view", comment: ""), attributes: [NSAttributedString.Key.foregroundColor : UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 0.7), NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14)])
        tTextField.attributedPlaceholder = arrtibutedString
        tTextField.textColor = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        tTextField.layer.masksToBounds = true
        tTextField.layer.borderColor = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0).cgColor
        tTextField.layer.borderWidth = 1.0
        return tTextField
    }()
    
    private lazy var mPasswordButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.isHidden = true
        button.backgroundColor = UIColor(red: 93.0/255.0, green: 174.0/255.0, blue: 139.0/255.0, alpha: 1.0)
        button.setTitleColor(UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0), for: UIControl.State.normal)
        button.setTitle(NSLocalizedString("Decrypt", comment: ""), for: UIControl.State.normal)
        button.layer.masksToBounds = true
        button.layer.borderColor = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0).cgColor
        button.layer.borderWidth = 1.0
        button.addTarget(self, action: #selector(_decrypt), for: UIControl.Event.touchUpInside)
        return button
    }()
    
    private lazy var mAutoScrollSwitch: UISwitch = {
        let autoScrollSwitch = UISwitch()
        autoScrollSwitch.isHidden = true
        autoScrollSwitch.setOn(true, animated: false)
        return autoScrollSwitch
    }()
    
    private lazy var mSwitchLabel: UILabel = {
        let switchLabel = UILabel()
        switchLabel.isHidden = true
        switchLabel.text = NSLocalizedString("Auto scroll", comment: "")
        switchLabel.textAlignment = NSTextAlignment.center
        switchLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        switchLabel.textColor = UIColor.white
        return switchLabel
    }()
    
    private lazy var mSearchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.isHidden = true
        searchBar.placeholder = NSLocalizedString("Log filter and search", comment: "")
        searchBar.barStyle = UIBarStyle.default
        searchBar.backgroundImage = UIImage()
        searchBar.backgroundColor = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        searchBar.delegate = self
        return searchBar
    }()
    
    private lazy var mPreviousButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.isHidden = true
        button.backgroundColor = UIColor(red: 255.0/255.0, green: 118.0/255.0, blue: 118.0/255.0, alpha: 1.0)
        button.setTitleColor(UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0), for: UIControl.State.normal)
        button.setTitleColor(UIColor(red: 102.0/255.0, green: 102.0/255.0, blue: 102.0/255.0, alpha: 1.0), for: UIControl.State.disabled)
        button.setTitle(NSLocalizedString("Previous", comment: ""), for: UIControl.State.normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.isEnabled = false
        button.addTarget(self, action: #selector(_previous), for: UIControl.Event.touchUpInside)
        return button
    }()
    
    private lazy var mNextButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.isHidden = true
        button.backgroundColor = UIColor(red: 93.0/255.0, green: 174.0/255.0, blue: 139.0/255.0, alpha: 1.0)
        button.setTitleColor(UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0), for: UIControl.State.normal)
        button.setTitleColor(UIColor(red: 102.0/255.0, green: 102.0/255.0, blue: 102.0/255.0, alpha: 1.0), for: UIControl.State.disabled)
        button.setTitle(NSLocalizedString("Next", comment: ""), for: UIControl.State.normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.isEnabled = false
        button.addTarget(self, action: #selector(_next), for: UIControl.Event.touchUpInside)
        return button
    }()
    
    private lazy var mSearchNumLabel: UILabel = {
        let tLabel = UILabel()
        tLabel.isHidden = true
        tLabel.text = "0"
        tLabel.textAlignment = NSTextAlignment.center
        tLabel.font = UIFont.systemFont(ofSize: 12)
        tLabel.textColor = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        tLabel.backgroundColor = UIColor(red: 57.0/255.0, green: 74.0/255.0, blue: 81.0/255.0, alpha: 1.0)
        return tLabel
    }()
    
    private lazy var mTipLabel: UILabel = {
        let tLabel = UILabel()
        tLabel.text = "ZXKitLogger Powered by DamonHu"
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
}

private extension ZXKitLoggerWindow {
    @objc func changeWindowFrame() {
        self.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 350)
        self.mContentBGView.snp.updateConstraints { (make) in
            make.top.equalToSuperview().offset(UIApplication.shared.statusBarFrame.height)
        }
    }

    @objc func cleanLog() {
        ZXKitLogger.cleanLog()
    }

    //MARK: Private method
    private func _init() {
        self.rootViewController = UIViewController()
        self.windowLevel =  UIWindow.Level.alert
        self.isUserInteractionEnabled = true
        self.backgroundColor = UIColor.clear
        self._createUI()

        NotificationCenter.default.addObserver(self, selector: #selector(changeWindowFrame), name: NSNotification.Name(UIApplication.didChangeStatusBarFrameNotification.rawValue), object: nil)
    }

    @objc private func _bindClick(button: UIButton) {
        switch button.tag {
            case 0:
                self.isFullScreen = !self.isFullScreen
            case 1:
                self._hide()
            case 2:
                self.cleanLog()
            case 3:
                self.isShowMenu = true
            default:
                break
        }
    }

    //过滤刷新
    private func _reloadFilter(model: ZXKitLoggerItem? = nil) {
        self.mFilterIndexArray.removeAll()
        self.mPreviousButton.isEnabled = false
        self.mNextButton.isEnabled = false
        self.mSearchNumLabel.text = "0"

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
        self.mTableView.reloadData()
        if self.mAutoScrollSwitch.isOn {
            guard self.mLogDataArray.count > 1 else { return }
            DispatchQueue.main.async {
                self.mTableView.scrollToRow(at: IndexPath(row: self.mLogDataArray.count - 1, section: 0), at: .bottom, animated: true)
            }
        }
    }

    @objc private func _previous() -> Void {
        if (self.mFilterIndexArray.count > 0) {
            self.mCurrentSearchIndex = self.mCurrentSearchIndex - 1;
            if (self.mCurrentSearchIndex < 0) {
                self.mCurrentSearchIndex = self.mFilterIndexArray.count - 1;
            }
            self.mSearchNumLabel.text = "\(self.mCurrentSearchIndex + 1)/\(self.mFilterIndexArray.count)"
            self.mTableView .scrollToRow(at: self.mFilterIndexArray[self.mCurrentSearchIndex], at: UITableView.ScrollPosition.top, animated: true)
        }
    }

    @objc private func _next() -> Void {
        if (self.mFilterIndexArray.count > 0) {
            self.mCurrentSearchIndex = self.mCurrentSearchIndex + 1;
            if (self.mCurrentSearchIndex == self.mFilterIndexArray.count) {
                self.mCurrentSearchIndex = 0;
            }
            self.mSearchNumLabel.text = "\(self.mCurrentSearchIndex + 1)/\(self.mFilterIndexArray.count)"
            self.mTableView .scrollToRow(at: self.mFilterIndexArray[self.mCurrentSearchIndex], at: UITableView.ScrollPosition.top, animated: true)
        }
    }

    @objc private func _closePicker() {
        self.mPickerBGView.isHidden = true
    }

    @objc private func _show() {
        self.isHidden = false
    }

    //只隐藏log的输出窗口，保留悬浮图标
    func _hide() {
        ZXKitLogger.hide()
        self.isDecryptViewHidden = true
        self.isScrollViewHidden = true
        self.isSearchViewHidden = true
    }

    @objc private func _confirmPicker() {
        self.mPickerBGView.isHidden = true
        let dataList = HDSqliteTools.shared.getAllLog(name: self.mShareFileName).reversed()
        //写入到text文件好解析
        //文件路径
        let logFilePathURL = ZXKitUtil.shared.getFileDirectory(type: .caches).appendingPathComponent("HDWindowLogger.log", isDirectory: false)
        if FileManager.default.fileExists(atPath: logFilePathURL.path) {
            try? FileManager.default.removeItem(at: logFilePathURL)
        }
        do {
            try dataList.joined(separator: "\n").write(to: logFilePathURL, atomically: false, encoding: String.Encoding.utf8)
        } catch {
            print(error)
        }

        //分享
        let activityVC = UIActivityViewController(activityItems: [logFilePathURL], applicationActivities: nil)
        if UIDevice.current.model == "iPad" {
            activityVC.modalPresentationStyle = UIModalPresentationStyle.popover
            activityVC.popoverPresentationController?.sourceView = self.mMenuView.subviews.first
            activityVC.popoverPresentationController?.sourceRect = self.mMenuView.subviews.first?.frame ?? .zero
        }
        self._hide()
        ZXKitUtil.shared.getCurrentVC()?.present(activityVC, animated: true, completion: nil)
    }

    private func _share() {
        self.mFileDateNameList = [String]()
        let path = HDSqliteTools.shared.getDBFolder()
        //数据库目录
        if let enumer = FileManager.default.enumerator(at: path, includingPropertiesForKeys: [URLResourceKey.creationDateKey]) {
            while let file = enumer.nextObject() {
                if let file: URL = file as? URL, file.lastPathComponent.hasSuffix(".db") {
                    self.mFileDateNameList.append(file.lastPathComponent)
                }
            }
        }

        //倒序，最后的放前面
        self.mFileDateNameList = self.mFileDateNameList.reversed()
        self.mPickerBGView.isHidden = !self.mPickerBGView.isHidden
        self.mPickerView.reloadAllComponents()
        self.mShareFileName = self.mFileDateNameList.first ?? ""
    }

    //解密
    @objc private func _decrypt() {
        self.mPasswordTextField.resignFirstResponder()
        self.mSearchBar.resignFirstResponder()
        if self.mPasswordTextField.text != nil {
            self.mTableView.reloadData()
        }
    }

    private func _createUI() {
        self.rootViewController?.view.addSubview(self.mContentBGView)
        self.mContentBGView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalToSuperview().offset(UIApplication.shared.statusBarFrame.height)
        }
        //菜单view
        self.rootViewController?.view.addSubview(self.mMenuView)
        self.mMenuView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalToSuperview().offset(UIApplication.shared.statusBarFrame.height)
        }
        self.changeWindowFrame()
        //顶部按钮
        self.mContentBGView.addSubview(self.mNormalStackView)
        self.mNormalStackView.snp.makeConstraints {
            $0.top.left.right.equalToSuperview()
            $0.height.equalTo(40)
        }
        //滚动日志窗
        self.mContentBGView.addSubview(self.mTableView)
        self.mTableView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(self.mNormalStackView.snp.bottom)
            make.bottom.equalToSuperview().offset(-20)
        }
        //私密解锁
        self.mContentBGView.addSubview(self.mPasswordTextField)
        self.mPasswordTextField.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.top.equalTo(self.mNormalStackView.snp.bottom)
            make.width.equalToSuperview().dividedBy(1.5)
            make.height.equalTo(40)
        }
        self.mContentBGView.addSubview(self.mPasswordButton)
        self.mPasswordButton.snp.makeConstraints { (make) in
            make.left.equalTo(self.mPasswordTextField.snp.right)
            make.top.equalTo(self.mPasswordTextField)
            make.width.equalToSuperview().dividedBy(3)
            make.height.equalTo(40)
        }
        //开关视图
        self.mContentBGView.addSubview(self.mAutoScrollSwitch)
        self.mAutoScrollSwitch.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-20)
            make.centerY.equalTo(self.mPasswordButton)
        }
        self.mContentBGView.addSubview(self.mSwitchLabel)
        self.mSwitchLabel.snp.makeConstraints { (make) in
            make.right.equalTo(self.mAutoScrollSwitch.snp.left).offset(-10)
            make.centerY.equalTo(self.mAutoScrollSwitch)
        }

        //搜索框
        self.mContentBGView.addSubview(self.mSearchBar)
        self.mSearchBar.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.bottom.equalToSuperview().offset(-20)
            make.height.equalTo(40)
            make.width.equalToSuperview().dividedBy(1.5)
        }

        self.mContentBGView.addSubview(self.mPreviousButton)
        self.mPreviousButton.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(self.mSearchBar)
            make.left.equalTo(self.mSearchBar.snp.right)
            make.width.equalToSuperview().dividedBy(9)
        }

        self.mContentBGView.addSubview(self.mNextButton)
        self.mNextButton.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(self.mSearchBar)
            make.left.equalTo(self.mPreviousButton.snp.right)
            make.width.equalToSuperview().dividedBy(9)
        }

        self.mContentBGView.addSubview(self.mSearchNumLabel)
        self.mSearchNumLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(self.mSearchBar)
            make.left.equalTo(self.mNextButton.snp.right)
            make.width.equalToSuperview().dividedBy(9)
        }

        self.mContentBGView.addSubview(self.mTipLabel)
        self.mTipLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(self.mSearchBar.snp.bottom);
            make.bottom.equalToSuperview()
        }

        self.mContentBGView.addSubview(self.mPickerBGView)
        self.mPickerBGView.snp.makeConstraints { (make) in
            make.top.equalTo(self.mContentBGView)
            make.left.right.bottom.equalTo(self.mContentBGView)
        }

        let tipLabel = UILabel()
        tipLabel.text = NSLocalizedString("Please select the log to share", comment: "");
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

        let closeBarItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.cancel, target: self, action: #selector(_closePicker))
        let fixBarItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let doneBarItem = UIBarButtonItem(title: NSLocalizedString("Share", comment: ""), style:.plain, target: self, action: #selector(_confirmPicker))
        self.mToolBar.setItems([closeBarItem, fixBarItem, doneBarItem], animated: true)

        self.mPickerBGView.addSubview(self.mPickerView)
        self.mPickerView.snp.makeConstraints { (make) in
            make.top.equalTo(self.mToolBar.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
    }
}

//MARK: Delegate
extension ZXKitLoggerWindow: UITableViewDataSource, UITableViewDelegate {
    //MARK:UITableViewDelegate
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.mLogDataArray.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let loggerItem = self.mLogDataArray[indexPath.row]
        
        let loggerCell: ZXKitLoggerTableViewCell = tableView.dequeueReusableCell(withIdentifier: "ZXKitLoggerTableViewCell") as! ZXKitLoggerTableViewCell
        if indexPath.row%2 != 0 {
            loggerCell.backgroundColor = UIColor(red: 156.0/255.0, green: 44.0/255.0, blue: 44.0/255.0, alpha: 0.8)
        } else {
            loggerCell.backgroundColor = UIColor.clear
        }
        loggerCell.updateWithLoggerItem(loggerItem: loggerItem, highlightText: self.mSearchBar.text ?? "")
        return loggerCell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let loggerItem = self.mLogDataArray[indexPath.row]
        let pasteboard = UIPasteboard.general
        pasteboard.string = loggerItem.getFullContentString()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss.SSS"
        let dateStr = dateFormatter.string(from: loggerItem.mCreateDate)
        let tipString = dateStr + " " + NSLocalizedString("Log has been copied", comment: "")
        ZXWarnLog(tipString)
    }
}

extension ZXKitLoggerWindow: UISearchBarDelegate {
    //UISearchBarDelegate
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self._reloadFilter()
    }
    
    public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

extension ZXKitLoggerWindow: UITextFieldDelegate {
    //MAKR:UITextFieldDelegate
    public func textFieldDidEndEditing(_ textField: UITextField) {
        ZXKitLogger.shared.isPasswordCorrect = (ZXKitLogger.privacyLogPassword == textField.text)
        self._decrypt()
    }
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.resignFirstResponder()
    }
}

extension ZXKitLoggerWindow: UIPickerViewDelegate, UIPickerViewDataSource {
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
        if !self.mFileDateNameList.isEmpty {
            self.mShareFileName = self.mFileDateNameList[row]
        }

    }
}
