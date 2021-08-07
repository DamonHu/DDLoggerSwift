//
//  ZXKitLoggerPickerWindow.swift
//  ZXKitLogger
//
//  Created by Damon on 2021/8/6.
//  Copyright © 2021 Damon. All rights reserved.
//

import UIKit
import ZXKitUtil

class ZXKitLoggerPickerWindow: UIWindow {
    @available(iOS 13.0, *)
    override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)
        self._initVC()
        self._createUI()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        self._initVC()
        self._createUI()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var mFileDateNameList = [String]()      //可以分享的文件列表
    private var mShareFileName = ""                 //选中去分享的文件名
    private var isCloseWhenComplete = false           //分享或者上传完毕之后是否关闭整个log
    private var pickerType: PickerType = .share {
        willSet {
            if newValue == .share {
                mPickerTipLabel.text = "Please select the log to share".ZXLocaleString
            } else if newValue == .upload {
                mPickerTipLabel.text = "Please select the log to upload".ZXLocaleString
            }
        }
    }
    
    //MARK: UI
    private lazy var mContentBGView: UIView = {
        let mContentBGView = UIView()
        mContentBGView.backgroundColor = UIColor.zx.color(hexValue: 0x000000, alpha: 0.6)
        return mContentBGView
    }()
    
    private lazy var mPickerBGView: UIView = {
        let tView = UIView()
        tView.backgroundColor = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        tView.layer.masksToBounds = true
        tView.layer.borderColor = UIColor(red: 57.0/255.0, green: 74.0/255.0, blue: 81.0/255.0, alpha: 1.0).cgColor
        tView.layer.borderWidth = 1.0
        return tView
    }()

    private lazy var mPickerTipLabel: UILabel = {
        let tipLabel = UILabel()
        tipLabel.text = "Please select the log to share".ZXLocaleString
        tipLabel.font = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.medium)
        return tipLabel
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

extension ZXKitLoggerPickerWindow {
    func showPicker(pickType: PickerType, isCloseWhenComplete: Bool) {
        self.pickerType = pickType
        self.isCloseWhenComplete = isCloseWhenComplete
        self.mFileDateNameList = [String]()
        let path = HDSqliteTools.shared.getDBFolder()
        //数据库目录
        if let enumer = FileManager.default.enumerator(at: path, includingPropertiesForKeys: [URLResourceKey.nameKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
            while let file = enumer.nextObject() {
                if let file: URL = file as? URL, file.lastPathComponent.hasSuffix(".db") {
                    self.mFileDateNameList.append(file.lastPathComponent)
                }
            }
        }

        //倒序，最后的放前面
        self.mFileDateNameList = self.mFileDateNameList.sorted().reversed()
        self.mPickerView.reloadAllComponents()
        self.mShareFileName = self.mFileDateNameList.first ?? ""
    }
}

private extension ZXKitLoggerPickerWindow {
    func _initVC() {
        self.rootViewController = UIViewController()
        self.windowLevel =  UIWindow.Level.alert
        self.isUserInteractionEnabled = true
    }
    
    private func _createUI() {
        self.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 350)
        self.rootViewController?.view.addSubview(self.mContentBGView)
        self.mContentBGView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalToSuperview().offset(UIApplication.shared.statusBarFrame.height)
        }
        self.mContentBGView.addSubview(self.mPickerBGView)
        self.mPickerBGView.snp.makeConstraints { (make) in
            make.top.equalTo(self.mContentBGView)
            make.left.right.bottom.equalTo(self.mContentBGView)
        }

        self.mPickerBGView.addSubview(mPickerTipLabel)
        mPickerTipLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(20)
            make.height.equalTo(40)
        }

        self.mPickerBGView.addSubview(self.mToolBar)
        self.mToolBar.snp.makeConstraints { (make) in
            make.top.equalTo(mPickerTipLabel.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(40)
        }
        self.mToolBar.layoutIfNeeded()

        let closeBarItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.cancel, target: self, action: #selector(_closePicker))
        let fixBarItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let doneBarItem = UIBarButtonItem(title: "Done".ZXLocaleString, style:.plain, target: self, action: #selector(_confirmPicker))
        self.mToolBar.setItems([closeBarItem, fixBarItem, doneBarItem], animated: true)

        self.mPickerBGView.addSubview(self.mPickerView)
        self.mPickerView.snp.makeConstraints { (make) in
            make.top.equalTo(self.mToolBar.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
    }
    
    @objc private func _closePicker() {
        self.isHidden = true
    }
    
    @objc private func _confirmPicker() {
        if self.pickerType == .share {
            let dataList = HDSqliteTools.shared.getAllLog(name: self.mShareFileName).reversed()
            //写入到text文件好解析
            //文件路径
            let logFilePathURL = ZXKitUtil.shared.getFileDirectory(type: .caches).appendingPathComponent("ZXKitLogger.log", isDirectory: false)
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
                let view: UIView = ZXKitUtil.shared.getCurrentVC()?.view ?? self.rootViewController!.view
                activityVC.popoverPresentationController?.sourceView = view
                activityVC.popoverPresentationController?.sourceRect = CGRect(x: 0, y: UIScreenHeight - 200, width: UIScreenWidth, height: 200)
            }
            if isCloseWhenComplete {
                ZXKitLogger.close()
            } else {
                ZXKitLogger.hide()
            }
            ZXKitUtil.shared.getCurrentVC()?.present(activityVC, animated: true, completion: nil)
        } else if let complete = ZXKitLogger.uploadComplete {
            let path = HDSqliteTools.shared.getDBFolder().appendingPathComponent(self.mShareFileName)
            complete(path)
            if isCloseWhenComplete {
                ZXKitLogger.close()
            } else {
                ZXKitLogger.hide()
            }
        }
    }
}

extension ZXKitLoggerPickerWindow: UIPickerViewDelegate, UIPickerViewDataSource {
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
