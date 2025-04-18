//
//  DDLoggerSwiftPickerWindow.swift
//  DDLoggerSwift
//
//  Created by Damon on 2021/8/6.
//  Copyright © 2021 Damon. All rights reserved.
//

import UIKit
import DDUtils

enum PickerType {
    case filter
    case share
    case upload
}

class DDLoggerSwiftPickerWindow: UIWindow {
    @available(iOS 13.0, *)
    override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)
        self.windowScene = windowScene
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
            switch newValue {
                case .share:
                    self.mConfirmButton.setTitle("Share".ZXLocaleString, for: .normal)
                case .upload:
                    self.mConfirmButton.setTitle("Upload".ZXLocaleString, for: .normal)
                case .filter:
                    self.mConfirmButton.setTitle("Confirm".ZXLocaleString, for: .normal)
            }
        }
    }
    
    //MARK: UI
    private lazy var mContentBGView: UIView = {
        let mContentBGView = UIView()
        mContentBGView.translatesAutoresizingMaskIntoConstraints = false
        mContentBGView.backgroundColor = UIColor.dd.color(hexValue: 0x333333)
        return mContentBGView
    }()
    
    private lazy var mPickerView: UIPickerView = {
        let tPicker = UIPickerView()
        tPicker.translatesAutoresizingMaskIntoConstraints = false
        tPicker.backgroundColor = UIColor.clear
        tPicker.isUserInteractionEnabled = true
        tPicker.dataSource = self
        tPicker.delegate = self
        return tPicker
    }()
    
    private lazy var mConfirmButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitleColor(UIColor.dd.color(hexValue: 0xffffff), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12)
        button.backgroundColor = UIColor(red: 255.0/255.0, green: 118.0/255.0, blue: 118.0/255.0, alpha: 1.0)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(_confirmPicker), for: .touchUpInside)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 6
        
        let scaleAnimation = CABasicAnimation(keyPath: "transform")
        scaleAnimation.fromValue = NSValue(caTransform3D: CATransform3DMakeScale(0.9, 0.9, 1))
        scaleAnimation.toValue = NSValue(caTransform3D: CATransform3DMakeScale(1.1, 1.1, 1))
        scaleAnimation.duration = 0.5
        scaleAnimation.isCumulative = false
        scaleAnimation.isRemovedOnCompletion = false
        scaleAnimation.autoreverses = true  //原样返回
        scaleAnimation.repeatCount = MAXFLOAT
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        button.layer.add(scaleAnimation, forKey: "scale")
        
        return button
    }()
}

extension DDLoggerSwiftPickerWindow {
    func showPicker(pickType: PickerType, date: Date?, isCloseWhenComplete: Bool) {
        self.pickerType = pickType
        self.isCloseWhenComplete = isCloseWhenComplete
        if let date = date {
            //指定日期
            self.mShareFileName = DDLoggerSwift.dateFormatter.string(from: date) + ".db"
            self._confirmPicker()
        } else {
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
}

private extension DDLoggerSwiftPickerWindow {
    func _initVC() {
        self.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
        let rootVC = UIViewController()
        let navigationVC = UINavigationController(rootViewController: rootVC)
        navigationVC.navigationBar.barTintColor = UIColor.white
        navigationVC.navigationBar.isTranslucent = false
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.white
            navigationVC.navigationBar.standardAppearance = appearance
            navigationVC.navigationBar.scrollEdgeAppearance = appearance
        }
        self.rootViewController = navigationVC
        self.windowLevel =  UIWindow.Level.alert
        self.isUserInteractionEnabled = true
        self.backgroundColor = UIColor.clear
        //标题
        let view = UIView()
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.attributedText = NSAttributedString(string: "Select Log File".ZXLocaleString, attributes: [NSAttributedString.Key.font:UIFont.systemFont(ofSize: 18, weight: .medium), NSAttributedString.Key.foregroundColor:UIColor.black])
        view.addSubview(label)
        label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        rootVC.navigationItem.titleView = view
        
        //
        let button = UIButton(frame: .init(x: 0, y: 0, width: 25, height: 25))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImageHDBoundle(named: "log_icon_close"), for: .normal)
        button.addTarget(self, action: #selector(_closePicker), for: .touchUpInside)
        NSLayoutConstraint(item: button, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 25).isActive = true
        NSLayoutConstraint(item: button, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 25).isActive = true
        let leftbarItem = UIBarButtonItem(customView: button)
        rootVC.navigationItem.leftBarButtonItems = [leftbarItem]
        
        //
        let rightButton = self.mConfirmButton
        NSLayoutConstraint(item: rightButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 25).isActive = true
        NSLayoutConstraint(item: rightButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 65).isActive = true
        let rightBarItem = UIBarButtonItem(customView: rightButton)
        rootVC.navigationItem.rightBarButtonItem = rightBarItem
    }
    
    private func _createUI() {
        guard let rootVC = self.rootViewController as? UINavigationController, let view = rootVC.topViewController?.view else { return }
        
        view.addSubview(self.mContentBGView)
        self.mContentBGView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        self.mContentBGView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        self.mContentBGView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        self.mContentBGView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true

        self.mContentBGView.addSubview(self.mPickerView)
        self.mPickerView.topAnchor.constraint(equalTo: self.mContentBGView.topAnchor).isActive = true
        self.mPickerView.leftAnchor.constraint(equalTo: self.mContentBGView.leftAnchor).isActive = true
        self.mPickerView.rightAnchor.constraint(equalTo: self.mContentBGView.rightAnchor).isActive = true
        self.mPickerView.bottomAnchor.constraint(equalTo: self.mContentBGView.bottomAnchor).isActive = true
    }
    
    @objc private func _closePicker() {
        self.isHidden = true
    }
    
    @objc private func _confirmPicker() {
        if self.pickerType == .share {
            let dataList = HDSqliteTools.shared.getLogs(name: self.mShareFileName, keyword: nil).map { item in
                return item.getFullContentString()
            }
            //写入到text文件好解析
            //文件路径
            let fileName = self.mShareFileName.components(separatedBy: ".").first ?? self.mShareFileName
            let logFilePathURL = DDUtils.shared.getFileDirectory(type: .tmp).appendingPathComponent("DDLoggerSwift-\(fileName).log", isDirectory: false)
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
                let view: UIView = DDUtils.shared.getCurrentVC()?.view ?? self.rootViewController!.view
                activityVC.popoverPresentationController?.sourceView = view
                activityVC.popoverPresentationController?.sourceRect = CGRect(x: 0, y: UIScreenHeight - 200, width: UIScreenWidth, height: 200)
            }
            if isCloseWhenComplete {
                DDLoggerSwift.close()
            } else {
                DDLoggerSwift.hide()
            }
            DDUtils.shared.getCurrentVC()?.present(activityVC, animated: true, completion: nil)
        } else if self.pickerType == .upload, let complete = DDLoggerSwift.uploadComplete {
            let path = HDSqliteTools.shared.getDBFolder().appendingPathComponent(self.mShareFileName)
            complete(path)
            if isCloseWhenComplete {
                DDLoggerSwift.close()
            } else {
                DDLoggerSwift.hide()
            }
        } else if self.pickerType == .filter, let complete = DDLoggerSwift.fileSelectedComplete {
            let path = HDSqliteTools.shared.getDBFolder().appendingPathComponent(self.mShareFileName)
            complete(path, self.mShareFileName)
            self.isHidden = true
        }
    }
}

extension DDLoggerSwiftPickerWindow: UIPickerViewDelegate, UIPickerViewDataSource {
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
            label.textColor = UIColor.dd.color(hexValue: 0xffffff)
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
