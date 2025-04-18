//
//  DDContentViewController.swift
//  DDLoggerSwift
//
//  Created by Damon on 2025/4/15.
//  Copyright © 2025 Damon. All rights reserved.
//

import UIKit

class DDContentViewController: UIViewController {
    private var mDisplayLogDataArray = [DDLoggerSwiftTableCellModel]()  //tableview显示的logger
    private var mCurrentSearchIndex = 0             //当前搜索到的索引
    private var lastIndexID: Int? = nil   //最后索引的id
    private var hasMore: Bool {
        get {
            return self.totalCount > self.mDisplayLogDataArray.count
        }
    }
    private var totalCount: Int = 0//数量
    
    var filterType: DDLogType? {
        didSet {
            self._resetData()
        }
    }
    
    var dataBaseName: String? {
        didSet {
            self._resetData()
        }
    }
    
    //解密栏
    var isDecryptViewHidden = true {
        willSet {
            self.mPasswordTextField.isHidden = newValue
            self.mPasswordButton.isHidden = newValue
            self.mPasswordCancelButton.isHidden = newValue
            if !newValue {
                self.mPasswordTextField.becomeFirstResponder()
            } else {
                self.mPasswordTextField.resignFirstResponder()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self._createUI()
        NotificationCenter.default.addObserver(self, selector: #selector(_dbUpdate(notice: )), name: .DDLoggerSwiftDBUpdate, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self._resetData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.isDecryptViewHidden = true
    }
    

    //MARK: UI布局
    private lazy var mContentBGView: UIView = {
        let mContentBGView = UIView()
        mContentBGView.translatesAutoresizingMaskIntoConstraints = false
        mContentBGView.backgroundColor = UIColor.dd.color(hexValue: 0x000000, alpha: 0.7)
        return mContentBGView
    }()
    
    lazy var mPullImageBGView: UIView = {
        let view = UIView()
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.dd.color(hexValue: 0x333333)
        view.dd.addLayerShadow(color: UIColor.dd.color(hexValue: 0x171619), offset: CGSize(width: 0, height: 0), radius: 5, cornerRadius: 15)
        view.layer.borderColor = UIColor.dd.color(hexValue: 0xffffff, alpha: 0.9).cgColor
        view.layer.borderWidth = 2
        let transformYAnimation = CABasicAnimation(keyPath: "transform.translation.y")
        transformYAnimation.fromValue = 0
        transformYAnimation.toValue = -10
        transformYAnimation.duration = 0.8
        transformYAnimation.isCumulative = false
        transformYAnimation.isRemovedOnCompletion = false
        transformYAnimation.autoreverses = true  //原样返回
        transformYAnimation.repeatCount = MAXFLOAT
        transformYAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        view.layer.add(transformYAnimation, forKey: "transformYAnimation")
        //添加点击
        let tap = UITapGestureRecognizer(target: self, action: #selector(_resetData))
        view.addGestureRecognizer(tap)
        return view
    }()
    
    lazy var mPullImageView: UIImageView = {
        let imageView = UIImageView(image: UIImageHDBoundle(named: "icon-pull-white"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var mTableView: UITableView = {
        let tableView = UITableView(frame: CGRect.zero, style: UITableView.Style.grouped)
        tableView.contentInset = .zero
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.contentInset = .zero
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.scrollsToTop = true
        tableView.dataSource = self
        tableView.delegate = self
        tableView.showsHorizontalScrollIndicator = false
        tableView.showsVerticalScrollIndicator = true
        tableView.keyboardDismissMode = UIScrollView.KeyboardDismissMode.onDrag
        tableView.backgroundColor = UIColor.clear
        tableView.separatorColor = UIColor.dd.color(hexValue: 0xcccccc)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.singleLine
        tableView.register(DDLoggerSwiftTableViewCell.self, forCellReuseIdentifier: "DDLoggerSwiftTableViewCell")
        //添加下拉刷新
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(_resetData), for: .valueChanged)
        tableView.refreshControl = refreshControl
        //底部距离
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: -20, right: 0)
        return tableView
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
        tTextField.leftViewMode = .always
        tTextField.leftView = UIView(frame: CGRect.init(x: 0, y: 0, width: 10, height: 0))
        return tTextField
    }()
    
    private lazy var mPasswordButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        button.backgroundColor = UIColor(red: 255.0/255.0, green: 118.0/255.0, blue: 118.0/255.0, alpha: 1.0)
        button.setTitleColor(UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0), for: UIControl.State.normal)
        button.setTitle("Decrypt".ZXLocaleString, for: UIControl.State.normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.addTarget(self, action: #selector(_decrypt), for: UIControl.Event.touchUpInside)
        return button
    }()
    
    private lazy var mPasswordCancelButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        button.backgroundColor = UIColor(red: 93.0/255.0, green: 174.0/255.0, blue: 139.0/255.0, alpha: 1.0)
        button.setTitleColor(UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0), for: UIControl.State.normal)
        button.setTitle("Cancel".ZXLocaleString, for: UIControl.State.normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.addTarget(self, action: #selector(_decryptCancel), for: UIControl.Event.touchUpInside)
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
    
    lazy var mFilterTypeView: DDLoggerSwiftFilterTypeView = {
        let view = DDLoggerSwiftFilterTypeView()
        view.delegate = self
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

}

extension DDContentViewController {
    @objc func _resetData() {
        self.mPullImageBGView.isHidden = true
        self.mCurrentSearchIndex = 0
        self.lastIndexID = nil
        self._reloadView()
    }
}

private extension DDContentViewController {
    func _createUI() {
        self.view.addSubview(self.mContentBGView)
        //列表放到最底部
        self.mContentBGView.addSubview(self.mTableView)
        //布局
        self.mContentBGView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        self.mContentBGView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        self.mContentBGView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        self.mContentBGView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true

        //搜索框
        self.mContentBGView.addSubview(self.mSearchBar)
        self.mSearchBar.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        self.mSearchBar.topAnchor.constraint(equalTo: mContentBGView.topAnchor).isActive = true
        self.mSearchBar.heightAnchor.constraint(equalToConstant: 40).isActive = true
        self.mSearchBar.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1.0/1.5).isActive = true

        self.mContentBGView.addSubview(self.mFilterButton)
        self.mFilterButton.leftAnchor.constraint(equalTo: self.mSearchBar.rightAnchor).isActive = true
        self.mFilterButton.topAnchor.constraint(equalTo: self.mSearchBar.topAnchor).isActive = true
        self.mFilterButton.bottomAnchor.constraint(equalTo: mSearchBar.bottomAnchor).isActive = true
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
        mFilterTypeView.topAnchor.constraint(equalTo: self.mFilterButton.bottomAnchor).isActive = true
        mFilterTypeView.heightAnchor.constraint(equalToConstant: 240).isActive = true

        //私密解锁
        view.addSubview(self.mPasswordTextField)
        self.mPasswordTextField.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        self.mPasswordTextField.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        self.mPasswordTextField.heightAnchor.constraint(equalToConstant: 40).isActive = true
        self.mPasswordTextField.widthAnchor.constraint(equalTo: self.mContentBGView.widthAnchor, multiplier: 1.0/1.5).isActive = true

        view.addSubview(self.mPasswordButton)
        self.mPasswordButton.leftAnchor.constraint(equalTo: self.mPasswordTextField.rightAnchor).isActive = true
        self.mPasswordButton.topAnchor.constraint(equalTo: self.mPasswordTextField.topAnchor).isActive = true
        self.mPasswordButton.widthAnchor.constraint(equalTo: self.mContentBGView.widthAnchor, multiplier: 1.0/6.0).isActive = true
        self.mPasswordButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        view.addSubview(self.mPasswordCancelButton)
        self.mPasswordCancelButton.leftAnchor.constraint(equalTo: self.mPasswordButton.rightAnchor).isActive = true
        self.mPasswordCancelButton.topAnchor.constraint(equalTo: self.mPasswordButton.topAnchor).isActive = true
        self.mPasswordCancelButton.widthAnchor.constraint(equalTo: self.mContentBGView.widthAnchor, multiplier: 1.0/6.0).isActive = true
        self.mPasswordCancelButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        //滚动日志窗
        self.mTableView.leftAnchor.constraint(equalTo: self.mContentBGView.leftAnchor).isActive = true
        self.mTableView.rightAnchor.constraint(equalTo: self.mContentBGView.rightAnchor).isActive = true
        self.mTableView.topAnchor.constraint(equalTo: self.mPasswordTextField.bottomAnchor).isActive = true
        self.mTableView.bottomAnchor.constraint(equalTo: self.mContentBGView.bottomAnchor).isActive = true
        
        //新标签
        self.mContentBGView.addSubview(mPullImageBGView)
        self.mPullImageBGView.centerXAnchor.constraint(equalTo: self.mContentBGView.centerXAnchor).isActive = true
        self.mPullImageBGView.topAnchor.constraint(equalTo: self.mTableView.topAnchor, constant: 13).isActive = true
        self.mPullImageBGView.widthAnchor.constraint(equalToConstant: 30).isActive = true
        self.mPullImageBGView.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        self.mPullImageBGView.addSubview(mPullImageView)
        self.mPullImageView.centerXAnchor.constraint(equalTo: self.mPullImageBGView.centerXAnchor).isActive = true
        self.mPullImageView.centerYAnchor.constraint(equalTo: self.mPullImageBGView.centerYAnchor).isActive = true
        self.mPullImageView.widthAnchor.constraint(equalToConstant: 16).isActive = true
        self.mPullImageView.heightAnchor.constraint(equalToConstant: 16).isActive = true
    }
    
    @objc private func _reloadView() {
        var dataArray = [DDLoggerSwiftItem]()
        self.totalCount = HDSqliteTools.shared.getItemCount(name: self.dataBaseName, keyword: self.mSearchBar.text, type: self.filterType)
        if DDLoggerSwift.maxPageSize > 0 {
            dataArray = HDSqliteTools.shared.getLogs(name: self.dataBaseName, keyword: self.mSearchBar.text, type: self.filterType, startID: self.lastIndexID, pageSize: DDLoggerSwift.maxPageSize)
            if self.lastIndexID == nil {
                self.mDisplayLogDataArray = dataArray.map({ item in
                    return DDLoggerSwiftTableCellModel(model: item)
                })
            } else {
                self.mDisplayLogDataArray.append(contentsOf: dataArray.map({ item in
                    return DDLoggerSwiftTableCellModel(model: item)
                }))
            }
            self.lastIndexID = self.mDisplayLogDataArray.last?.logItem.databaseID
        } else {
            //不分页
            dataArray = HDSqliteTools.shared.getLogs(name: self.dataBaseName, keyword: self.mSearchBar.text, type: self.filterType, startID: nil, pageSize: nil)
            self.mDisplayLogDataArray = dataArray.map({ item in
                return DDLoggerSwiftTableCellModel(model: item)
            })
        }
        if self.mDisplayLogDataArray.isEmpty {
            //第一条信息
            self.mDisplayLogDataArray.append(DDLoggerSwiftTableCellModel())
        }
        self.mNextButton.isEnabled = !self.mDisplayLogDataArray.isEmpty
        self.mSearchNumLabel.text = "\(self.mCurrentSearchIndex + 1)/\(self.mDisplayLogDataArray.count)"
        //全局刷新
        self.mTableView.reloadData()
        self.mTableView.refreshControl?.endRefreshing()
    }

    @objc private func _showFilterPop() -> Void {
        self.mFilterTypeView.isHidden = !self.mFilterTypeView.isHidden
    }

    @objc private func _next() -> Void {
        if (self.mDisplayLogDataArray.count > 0) {
            self.mCurrentSearchIndex = self.mCurrentSearchIndex + 1;
            if (self.mCurrentSearchIndex == self.mDisplayLogDataArray.count) {
                self.mCurrentSearchIndex = 0;
            }
            self.mSearchNumLabel.text = "\(self.mCurrentSearchIndex + 1)/\(self.mDisplayLogDataArray.count)"
            self.mTableView.scrollToRow(at: IndexPath(row: self.mCurrentSearchIndex, section: 0), at: UITableView.ScrollPosition.top, animated: true)
        }
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
    
    @objc private func _decryptCancel() {
        self.mPasswordTextField.resignFirstResponder()
        self.mSearchBar.resignFirstResponder()
        self.isDecryptViewHidden = true
    }
    
    @objc private func _dbUpdate(notice: Notification) {
        guard let object = notice.object as? [String: Any], let type = object["type"] as? String else { return }
        if type == "insert" && self.mPullImageBGView.isHidden {
            self.mPullImageBGView.isHidden = false
        }
        
    }
}

extension DDContentViewController: DDLoggerSwiftFilterTypeViewDelegate {
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



extension DDContentViewController: UISearchBarDelegate {
    //UISearchBarDelegate
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self._resetData()
    }
    
    public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

extension DDContentViewController: UITextFieldDelegate {
    //MAKR:UITextFieldDelegate
    public func textFieldDidEndEditing(_ textField: UITextField) {
        DDLoggerSwift.shared.isPasswordCorrect = (DDLoggerSwift.privacyLogPassword == textField.text)
    }
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.resignFirstResponder()
    }
}


extension DDContentViewController: UITableViewDataSource, UITableViewDelegate {
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
        loggerCell.updateWithLoggerItem(model: loggerItem, highlightText: self.mSearchBar.text ?? "")
        return loggerCell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = self.mDisplayLogDataArray[indexPath.row]
        if model.isCollapse {
            model.isCollapse = false
            tableView.reloadRows(at: [indexPath], with: .fade)
        } else {
            let pasteboard = UIPasteboard.general
            pasteboard.string = model.logItem.getFullContentString()
            //提醒
            let alert = UIAlertController(title: "copy success", message: "Log has been copied".ZXLocaleString, preferredStyle: .alert)
            self.present(alert, animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                alert.dismiss(animated: true)
            }
        }
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
        return self.hasMore ? 50 : 0.1
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return self.hasMore ? 50 : 0.1
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let button = UIButton()
        if self.hasMore {
            let attributed = NSMutableAttributedString(string: "🔄 " + "Load More".ZXLocaleString, attributes: [.font: UIFont.systemFont(ofSize: 15, weight: .bold), .foregroundColor: UIColor.dd.color(hexValue: 0xffffff)])
            let attributed1 = NSAttributedString(string: "\n" + "left count".ZXLocaleString + ": \(self.totalCount - self.mDisplayLogDataArray.count)", attributes: [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.dd.color(hexValue: 0xffffff, alpha: 0.6)])
            
            attributed.append(attributed1)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineHeightMultiple = 1.3
            paragraphStyle.alignment = .center
            attributed.addAttributes([.paragraphStyle: paragraphStyle], range: NSRange(location: 0, length: attributed.length))
            
            button.setAttributedTitle(attributed, for: .normal)
            button.setTitleColor(UIColor.dd.color(hexValue: 0xffffff), for: .normal)
            button.titleLabel?.numberOfLines = 0
            button.backgroundColor = UIColor.dd.color(hexValue: 0x333333)
            button.addTarget(self, action: #selector(_reloadView), for: .touchUpInside)
        }
        return button
    }
}
