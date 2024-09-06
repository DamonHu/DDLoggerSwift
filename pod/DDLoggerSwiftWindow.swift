//
//  DDLoggerSwiftWindow.swift
//  DDLoggerSwift
//
//  Created by Damon on 2020/9/9.
//  Copyright © 2020 Damon. All rights reserved.
//

import UIKit
import DDUtils

func UIImageHDBoundle(named: String?) -> UIImage? {
    guard let name = named else { return nil }
    guard let bundlePath = Bundle(for: DDLoggerSwift.self).path(forResource: "DDLoggerSwift", ofType: "bundle") else { return UIImage(named: name) }
    guard let bundle = Bundle(path: bundlePath) else { return UIImage(named: name) }
    return UIImage(named: name, in: bundle, compatibleWith: nil)
}

extension String{
    var ZXLocaleString: String {
        guard let bundlePath = Bundle(for: DDLoggerSwift.self).path(forResource: "DDLoggerSwift", ofType: "bundle") else { return NSLocalizedString(self, comment: "") }
        guard let bundle = Bundle(path: bundlePath) else { return NSLocalizedString(self, comment: "") }
        let msg = NSLocalizedString(self, tableName: nil, bundle: bundle, value: "", comment: "")
        return msg
    }
}

class DDLoggerSwiftWindow: UIWindow {
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
    private var mDisplayLogDataArray = [DDLoggerSwiftItem]()  //tableview显示的logger
    private var mFilterIndexArray = [IndexPath]()   //索引的排序
    private var mCurrentSearchIndex = 0             //当前搜索到的索引
    private var page: Int = 1   //第几页数据
    
    override var isHidden: Bool {
        willSet {
            super.isHidden = newValue
            if !newValue {
                self.changeWindowFrame()
                if self.mDisplayLogDataArray.isEmpty {
                    self.page = 1
                    self._reloadView()
                }
            }
        }
    }

    var filterType: DDLogType? {
        didSet {
            self.page = 1
            self._reloadView()
        }
    }

    var isFullScreen = false {
        willSet {
            if (newValue) {
                self.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height - 70)
            } else {
                self.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 420)
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
                //关闭之前的输入
                self.isDecryptViewHidden = true
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

    var dataBaseName: String? {
        didSet {
            if dataBaseName == nil {
                self.mTipLabel.text = "DDLoggerSwift"
            } else {
                self.mTipLabel.text = dataBaseName
            }
            self.page = 1
            self._reloadView()
        }
    }


    //MARK: UI布局
    private lazy var mContentBGView: UIView = {
        let mContentBGView = UIView()
        mContentBGView.translatesAutoresizingMaskIntoConstraints = false
        mContentBGView.backgroundColor = UIColor.dd.color(hexValue: 0x272d55, alpha: 0.6)
        return mContentBGView
    }()

    private lazy var mTableView: UITableView = {
        let tableView = UITableView(frame: CGRect.zero, style: UITableView.Style.grouped)
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.scrollsToTop = true
        tableView.dataSource = self
        tableView.delegate = self
        tableView.showsHorizontalScrollIndicator = false
        tableView.showsVerticalScrollIndicator = true
        tableView.keyboardDismissMode = UIScrollView.KeyboardDismissMode.onDrag
        tableView.backgroundColor = UIColor.clear
        tableView.separatorColor = UIColor.dd.color(hexValue: 0xfcfcfc)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.singleLine
        tableView.register(DDLoggerSwiftTableViewCell.self, forCellReuseIdentifier: "DDLoggerSwiftTableViewCell")
        return tableView
    }()

    lazy var mNavigationBar: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.dd.color(hexValue: 0x45526c)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var mScaleButton: UIButton = {
        let button = UIButton(type: .custom)
        button.tag = 0
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImageHDBoundle(named: "icon_scale"), for: .normal)
        button.addTarget(self, action: #selector(_bindClick(button:)), for: .touchUpInside)
        return button
    }()
    
    lazy var mDeleteButton: UIButton = {
        let button = UIButton(type: .custom)
        button.tag = 2
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImageHDBoundle(named: "icon_delete"), for: .normal)
        button.addTarget(self, action: #selector(_bindClick(button:)), for: .touchUpInside)
        return button
    }()
    
    lazy var mMenuButton: UIButton = {
        let button = UIButton(type: .custom)
        button.tag = 1
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImageHDBoundle(named: "icon_normal_back"), for: .normal)
        button.addTarget(self, action: #selector(_bindClick(button:)), for: .touchUpInside)
        return button
    }()
    
    lazy var mCloseButton: UIButton = {
        let button = UIButton(type: .custom)
        button.tag = 3
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImageHDBoundle(named: "icon_exit"), for: .normal)
        button.addTarget(self, action: #selector(_bindClick(button:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var mMenuView: DDLoggerSwiftMenuView = {
        let tMenuView = DDLoggerSwiftMenuView()
        tMenuView.translatesAutoresizingMaskIntoConstraints = false
        tMenuView.isHidden = true
        tMenuView.clickSubject = {(index) -> Void in
            self.isShowMenu = false
            switch index {
                case 0:
                    break
                case 1:
                    self._hide()
                case 2:
                    self._close()
                case 3:
                    DDLoggerSwift.showShare(isCloseWhenComplete: false)
                case 4:
                    self.isDecryptViewHidden = false
                case 5:
                    DDLoggerSwift.fileSelectedComplete = { filePath, name in
                        self.dataBaseName = name
                    }
                    DDLoggerSwift.showFileFilter()
                break
                case 6:
                    break
                case 7:
                    let folder = DDLoggerSwift.getDBFolder()
                    let size = DDUtils.shared.getFileDirectorySize(fileDirectoryPth: folder)
                    //数据库条数
                    var count = 0
                    if let enumer = FileManager.default.enumerator(at: folder, includingPropertiesForKeys: [URLResourceKey.creationDateKey]) {
                        while let file = enumer.nextObject() {
                            if let file: URL = file as? URL, file.lastPathComponent.hasSuffix(".db") {
                               count = count + 1
                            }
                        }
                    }
                    let info = """

                        📅 \("Number of Today's Logs".ZXLocaleString): \(DDLoggerSwift.getItemCount(type: nil))

                        ✅ Info count: \(DDLoggerSwift.getItemCount(type: .info))

                        ⚠️ Warn count: \(DDLoggerSwift.getItemCount(type: .warn))

                        ❌ Error count: \(DDLoggerSwift.getItemCount(type: .error))

                        ⛔️ Privacy count: \(DDLoggerSwift.getItemCount(type: .privacy))

                        📊 \("LogFile count".ZXLocaleString): \(count)

                        📈 \("LogFile total size".ZXLocaleString): \(size/1024.0)kb
                    """
                    printWarn(info)
                case 8:
                    DDLoggerSwift.showUpload(isCloseWhenComplete: false)
                default:
                    break
            }
        };
        return tMenuView
    }()
    
    private lazy var mPasswordTextField: UITextField = {
        let tTextField = UITextField()
        tTextField.translatesAutoresizingMaskIntoConstraints = false
        tTextField.backgroundColor = UIColor.dd.color(hexValue: 0x687980)
        tTextField.isHidden = true
        tTextField.isSecureTextEntry = true
        tTextField.delegate = self
        let arrtibutedString = NSMutableAttributedString(string: "Enter password to view".ZXLocaleString, attributes: [NSAttributedString.Key.foregroundColor : UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 0.7), NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14)])
        tTextField.attributedPlaceholder = arrtibutedString
        tTextField.textColor = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        tTextField.layer.masksToBounds = true
        tTextField.layer.borderColor = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0).cgColor
        tTextField.layer.borderWidth = 1.0
        return tTextField
    }()
    
    private lazy var mPasswordButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        button.backgroundColor = UIColor(red: 93.0/255.0, green: 174.0/255.0, blue: 139.0/255.0, alpha: 1.0)
        button.setTitleColor(UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0), for: UIControl.State.normal)
        button.setTitle("Decrypt".ZXLocaleString, for: UIControl.State.normal)
        button.layer.masksToBounds = true
        button.layer.borderColor = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0).cgColor
        button.layer.borderWidth = 1.0
        button.addTarget(self, action: #selector(_decrypt), for: UIControl.Event.touchUpInside)
        return button
    }()
    
    private lazy var mSearchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.placeholder = "Log filter and search".ZXLocaleString
        searchBar.barStyle = UIBarStyle.default
        searchBar.backgroundImage = UIImage()
        searchBar.backgroundColor = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        searchBar.delegate = self
        return searchBar
    }()
    
    private lazy var mFilterButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor(red: 255.0/255.0, green: 118.0/255.0, blue: 118.0/255.0, alpha: 1.0)
        button.setTitleColor(UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0), for: UIControl.State.normal)
        button.setTitleColor(UIColor(red: 102.0/255.0, green: 102.0/255.0, blue: 102.0/255.0, alpha: 1.0), for: UIControl.State.disabled)
        button.setTitle("Filter".ZXLocaleString, for: UIControl.State.normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.addTarget(self, action: #selector(_showFilterPop), for: UIControl.Event.touchUpInside)
        return button
    }()
    
    private lazy var mNextButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor(red: 93.0/255.0, green: 174.0/255.0, blue: 139.0/255.0, alpha: 1.0)
        button.setTitleColor(UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0), for: UIControl.State.normal)
        button.setTitleColor(UIColor(red: 102.0/255.0, green: 102.0/255.0, blue: 102.0/255.0, alpha: 1.0), for: UIControl.State.disabled)
        button.setTitle("Next".ZXLocaleString, for: UIControl.State.normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.isEnabled = false
        button.addTarget(self, action: #selector(_next), for: UIControl.Event.touchUpInside)
        return button
    }()
    
    private lazy var mSearchNumLabel: UILabel = {
        let tLabel = UILabel()
        tLabel.translatesAutoresizingMaskIntoConstraints = false
        tLabel.text = "0"
        tLabel.textAlignment = NSTextAlignment.center
        tLabel.font = UIFont.systemFont(ofSize: 12)
        tLabel.textColor = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        tLabel.backgroundColor = UIColor(red: 57.0/255.0, green: 74.0/255.0, blue: 81.0/255.0, alpha: 1.0)
        return tLabel
    }()
    
    private lazy var mTipLabel: UILabel = {
        let tLabel = UILabel()
        tLabel.translatesAutoresizingMaskIntoConstraints = false
        tLabel.text = "DDLoggerSwift"
        tLabel.textAlignment = NSTextAlignment.center
        tLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        tLabel.textColor = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 0.9)
        tLabel.backgroundColor = UIColor.clear
        return tLabel
    }()
    
    lazy var mFilterTypeView: DDLoggerSwiftFilterTypeView = {
        let view = DDLoggerSwiftFilterTypeView()
        view.delegate = self
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
}


//MARK: - Function
extension DDLoggerSwiftWindow {
    //
    @objc func cleanLog() {
        //删除指定数据
        HDSqliteTools.shared.deleteLog(timeStamp: Date().timeIntervalSince1970)
        self.mDisplayLogDataArray.removeAll()
        self.mFilterIndexArray.removeAll()
        self.page = 1
        self._reloadView()
    }
}

//MARK: - private Function
private extension DDLoggerSwiftWindow {
    @objc func changeWindowFrame() {
        self.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 420)
        if let view = self.rootViewController?.view {
            self.mContentBGView.topAnchor.constraint(equalTo: view.topAnchor, constant: UIApplication.shared.statusBarFrame.height).isActive = true
        }
    }

    //MARK: Private method
    private func _init() {
        self.rootViewController = UIViewController()
        self.windowLevel =  UIWindow.Level.alert
        self.isUserInteractionEnabled = true
        self.backgroundColor = UIColor.clear
        self._createUI()
        NotificationCenter.default.addObserver(self, selector: #selector(changeWindowFrame), name: UIApplication.didChangeStatusBarFrameNotification, object: nil)
    }

    @objc private func _bindClick(button: UIButton) {
        switch button.tag {
            case 0:
                self.isFullScreen = !self.isFullScreen
            case 1:
                self.isShowMenu = true
            case 2:
                self.cleanLog()
            case 3:
                DDLoggerSwift.close()
            default:
                break
        }
    }

    //过滤刷新
    private func _reloadView() {
        let dataArray = HDSqliteTools.shared.getLogs(name: self.dataBaseName, keyword: self.mSearchBar.text, type: self.filterType, pagination: (self.page, DDLoggerSwift.maxPageSize))
        if self.page == 1 {
            self.mDisplayLogDataArray = dataArray
        } else {
            self.mDisplayLogDataArray.append(contentsOf: dataArray)
        }
        if self.mDisplayLogDataArray.isEmpty {
            //第一条信息
            let loggerItem = DDLoggerSwiftItem()
            self.mDisplayLogDataArray.append(loggerItem)
        }
        self.mFilterIndexArray.removeAll()
        self.mNextButton.isEnabled = false
        self.mSearchNumLabel.text = "0"
        //高亮
        if let searchText = self.mSearchBar.text, !searchText.isEmpty {
            for (index, item) in self.mDisplayLogDataArray.enumerated() {
                if item.getFullContentString().localizedCaseInsensitiveContains(self.mSearchBar.text ?? "") {
                    let indexPath = IndexPath(row: index, section: 0)
                    self.mFilterIndexArray.append(indexPath)
                    self.mNextButton.isEnabled = true
                    self.mCurrentSearchIndex = self.mFilterIndexArray.count - 1;
                    self.mSearchNumLabel.text = "\(self.mCurrentSearchIndex + 1)/\(self.mFilterIndexArray.count)"
                }
            }
        }
        //全局刷新
        self.mTableView.reloadData()
        if self.mMenuView.isAutoScrollSwitch {
            guard self.mDisplayLogDataArray.count > 1 else { return }
            DispatchQueue.main.async {
                self.mTableView.scrollToRow(at: IndexPath(row: self.mDisplayLogDataArray.count - 1, section: 0), at: .bottom, animated: true)
            }
        }
    }

    @objc private func _showFilterPop() -> Void {
        self.mFilterTypeView.isHidden = !self.mFilterTypeView.isHidden
    }

    @objc private func _next() -> Void {
        if (self.mFilterIndexArray.count > 0) {
            self.mCurrentSearchIndex = self.mCurrentSearchIndex + 1;
            if (self.mCurrentSearchIndex == self.mFilterIndexArray.count) {
                self.mCurrentSearchIndex = 0;
            }
            self.mSearchNumLabel.text = "\(self.mCurrentSearchIndex + 1)/\(self.mFilterIndexArray.count)"
            self.mTableView.scrollToRow(at: self.mFilterIndexArray[self.mCurrentSearchIndex], at: UITableView.ScrollPosition.top, animated: true)
        }
    }

    @objc private func _show() {
        self.isHidden = false
    }
    
    @objc private func _loadMore() {
        self.page = self.page + 1
        self._reloadView()
    }

    //只隐藏log的输出窗口，保留悬浮图标
    func _hide() {
        DDLoggerSwift.hide()
        self.isDecryptViewHidden = true
    }
    
    func _close() {
        DDLoggerSwift.close()
        self.isDecryptViewHidden = true
    }

    //解密
    @objc private func _decrypt() {
        self.mPasswordTextField.resignFirstResponder()
        self.mSearchBar.resignFirstResponder()
        self.isDecryptViewHidden = true
        if DDLoggerSwift.shared.isPasswordCorrect {
            self.mTableView.reloadData()
        } else {
            printError("Password Error".ZXLocaleString)
        }
    }

    private func _createUI() {
        guard let view = self.rootViewController?.view else { return }

        view.addSubview(self.mContentBGView)
        self.mContentBGView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        self.mContentBGView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        self.mContentBGView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        self.mContentBGView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true

        //菜单view
        view.addSubview(self.mMenuView)
        self.mMenuView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        self.mMenuView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        self.mMenuView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40).isActive = true
        self.mMenuView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        self.changeWindowFrame()
        
        //顶部按钮
        self.mContentBGView.addSubview(self.mNavigationBar)
        self.mNavigationBar.topAnchor.constraint(equalTo: self.mContentBGView.topAnchor).isActive = true
        self.mNavigationBar.leftAnchor.constraint(equalTo: self.mContentBGView.leftAnchor).isActive = true
        self.mNavigationBar.rightAnchor.constraint(equalTo: self.mContentBGView.rightAnchor).isActive = true
        self.mNavigationBar.heightAnchor.constraint(equalToConstant: 40 + UIApplication.shared.statusBarFrame.height).isActive = true
        //放大
        self.mNavigationBar.addSubview(self.mScaleButton)
        mScaleButton.bottomAnchor.constraint(equalTo: self.mNavigationBar.bottomAnchor, constant: -10).isActive = true
        mScaleButton.leftAnchor.constraint(equalTo: self.mNavigationBar.leftAnchor, constant: 20).isActive = true
        mScaleButton.widthAnchor.constraint(equalToConstant: 20).isActive = true
        mScaleButton.heightAnchor.constraint(equalToConstant: 20).isActive = true
        //清除
        self.mNavigationBar.addSubview(self.mDeleteButton)
        mDeleteButton.centerYAnchor.constraint(equalTo: self.mScaleButton.centerYAnchor).isActive = true
        mDeleteButton.leftAnchor.constraint(equalTo: self.mScaleButton.rightAnchor, constant: 25).isActive = true
        mDeleteButton.widthAnchor.constraint(equalToConstant: 25).isActive = true
        mDeleteButton.heightAnchor.constraint(equalToConstant: 25).isActive = true
        //关闭
        self.mNavigationBar.addSubview(self.mCloseButton)
        mCloseButton.centerYAnchor.constraint(equalTo: self.mScaleButton.centerYAnchor).isActive = true
        mCloseButton.rightAnchor.constraint(equalTo: self.mNavigationBar.rightAnchor, constant: -20).isActive = true
        mCloseButton.widthAnchor.constraint(equalToConstant: 23).isActive = true
        mCloseButton.heightAnchor.constraint(equalToConstant: 23).isActive = true
        //菜单
        self.mNavigationBar.addSubview(self.mMenuButton)
        mMenuButton.centerYAnchor.constraint(equalTo: self.mScaleButton.centerYAnchor).isActive = true
        mMenuButton.rightAnchor.constraint(equalTo: self.mCloseButton.leftAnchor, constant: -25).isActive = true
        mMenuButton.widthAnchor.constraint(equalToConstant: 23).isActive = true
        mMenuButton.heightAnchor.constraint(equalToConstant: 23).isActive = true
        //标题
        self.mNavigationBar.addSubview(self.mTipLabel)
        self.mTipLabel.centerXAnchor.constraint(equalTo: self.mNavigationBar.centerXAnchor).isActive = true
        self.mTipLabel.centerYAnchor.constraint(equalTo: self.mScaleButton.centerYAnchor).isActive = true
        //滚动日志窗
        self.mContentBGView.addSubview(self.mTableView)
        self.mTableView.leftAnchor.constraint(equalTo: self.mContentBGView.leftAnchor).isActive = true
        self.mTableView.rightAnchor.constraint(equalTo: self.mContentBGView.rightAnchor).isActive = true
        self.mTableView.topAnchor.constraint(equalTo: self.mNavigationBar.bottomAnchor).isActive = true
        self.mTableView.bottomAnchor.constraint(equalTo: self.mContentBGView.bottomAnchor, constant: -40).isActive = true
        //搜索框
        self.mContentBGView.addSubview(self.mSearchBar)
        self.mSearchBar.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        self.mSearchBar.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        self.mSearchBar.heightAnchor.constraint(equalToConstant: 40).isActive = true
        self.mSearchBar.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1.0/1.5).isActive = true

        self.mContentBGView.addSubview(self.mFilterButton)
        self.mFilterButton.leftAnchor.constraint(equalTo: self.mSearchBar.rightAnchor).isActive = true
        self.mFilterButton.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        self.mFilterButton.topAnchor.constraint(equalTo: self.mSearchBar.topAnchor).isActive = true
        self.mFilterButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1.0/9.0).isActive = true

        self.mContentBGView.addSubview(self.mNextButton)
        self.mNextButton.topAnchor.constraint(equalTo: self.mSearchBar.topAnchor).isActive = true
        self.mNextButton.bottomAnchor.constraint(equalTo: self.mSearchBar.bottomAnchor).isActive = true
        self.mNextButton.leftAnchor.constraint(equalTo: self.mFilterButton.rightAnchor).isActive = true
        self.mNextButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1.0/9.0).isActive = true

        self.mContentBGView.addSubview(self.mSearchNumLabel)
        self.mSearchNumLabel.topAnchor.constraint(equalTo: self.mSearchBar.topAnchor).isActive = true
        self.mSearchNumLabel.bottomAnchor.constraint(equalTo: self.mSearchBar.bottomAnchor).isActive = true
        self.mSearchNumLabel.leftAnchor.constraint(equalTo: self.mNextButton.rightAnchor).isActive = true
        self.mSearchNumLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1.0/9.0).isActive = true
        //过滤框
        self.mContentBGView.addSubview(mFilterTypeView)
        mFilterTypeView.leftAnchor.constraint(equalTo: self.mFilterButton.leftAnchor).isActive = true
        mFilterTypeView.widthAnchor.constraint(equalToConstant: 90).isActive = true
        mFilterTypeView.bottomAnchor.constraint(equalTo: self.mFilterButton.topAnchor).isActive = true
        mFilterTypeView.heightAnchor.constraint(equalToConstant: 240).isActive = true

        //私密解锁
        view.addSubview(self.mPasswordTextField)
        self.mPasswordTextField.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        self.mPasswordTextField.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        self.mPasswordTextField.heightAnchor.constraint(equalToConstant: 40).isActive = true
        self.mPasswordTextField.widthAnchor.constraint(equalTo: self.mContentBGView.widthAnchor, multiplier: 1.0/1.5).isActive = true

        view.addSubview(self.mPasswordButton)
        self.mPasswordButton.leftAnchor.constraint(equalTo: self.mPasswordTextField.rightAnchor).isActive = true
        self.mPasswordButton.topAnchor.constraint(equalTo: self.mPasswordTextField.topAnchor).isActive = true
        self.mPasswordButton.widthAnchor.constraint(equalTo: self.mContentBGView.widthAnchor, multiplier: 1.0/3.0).isActive = true
        self.mPasswordButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
    }
}

//MARK: Delegate
extension DDLoggerSwiftWindow: DDLoggerSwiftFilterTypeViewDelegate {
    func filterSelected(filterType: DDLogType?) {
        self.mFilterTypeView.isHidden = true
        self.filterType = filterType
        if let filterType = filterType {
            self.mFilterButton.setTitle(filterType.typeName(), for: .normal)
        } else {
            self.mFilterButton.setTitle("Filter", for: .normal)
        }
    }
}


extension DDLoggerSwiftWindow: UITableViewDataSource, UITableViewDelegate {
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {

        
    }
    //MARK:UITableViewDelegate
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.mDisplayLogDataArray.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let loggerItem = self.mDisplayLogDataArray[indexPath.row]
        
        let loggerCell = tableView.dequeueReusableCell(withIdentifier: "DDLoggerSwiftTableViewCell") as! DDLoggerSwiftTableViewCell
        loggerCell.backgroundColor = UIColor.clear
        loggerCell.selectionStyle = .none
        loggerCell.updateWithLoggerItem(loggerItem: loggerItem, highlightText: self.mSearchBar.text ?? "")
        return loggerCell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let loggerItem = self.mDisplayLogDataArray[indexPath.row]
        let pasteboard = UIPasteboard.general
        pasteboard.string = loggerItem.getFullContentString()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss.SSS"
        let dateStr = dateFormatter.string(from: loggerItem.mCreateDate)
        let tipString = dateStr + " " + "Log has been copied".ZXLocaleString
        printWarn(tipString)
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 0.1
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.1
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        return 0.1
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 44
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
//        let view = UIView()
        let button = UIButton()
        button.setTitle("Load More 🔄", for: .normal)
        button.setTitleColor(UIColor.dd.color(hexValue: 0xffffff), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        button.backgroundColor = UIColor.dd.color(hexValue: 0x333333)
        button.addTarget(self, action: #selector(_loadMore), for: .touchUpInside)
        return button
    }
}

extension DDLoggerSwiftWindow: UISearchBarDelegate {
    //UISearchBarDelegate
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.page = 1
        self._reloadView()
    }
    
    public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

extension DDLoggerSwiftWindow: UITextFieldDelegate {
    //MAKR:UITextFieldDelegate
    public func textFieldDidEndEditing(_ textField: UITextField) {
        DDLoggerSwift.shared.isPasswordCorrect = (DDLoggerSwift.privacyLogPassword == textField.text)
    }
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.resignFirstResponder()
    }
}
