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
        //优先使用主项目翻译
        let mainValue = NSLocalizedString(self, comment: "")
        if mainValue != self {
            return mainValue
        }
        //使用自己的bundle
        if let bundlePath = Bundle(for: DDLoggerSwift.self).path(forResource: "DDLoggerSwift", ofType: "bundle"), let bundle = Bundle(path: bundlePath) {
            return NSLocalizedString(self, tableName: nil, bundle: bundle, value: self, comment: "")
        }
        return self
    }
}

class DDLoggerSwiftWindow: UIWindow {
    var currentVC = DDContentViewController()
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
    
    
    override var isHidden: Bool {
        willSet {
            super.isHidden = newValue
//            if !newValue {
//                self.changeWindowFrame()
//                if self.mDisplayLogDataArray.isEmpty {
//                    self.currentVC._resetData()
//                }
//            }
        }
    }

    var filterType: DDLogType? {
        didSet {
            self.currentVC.filterType = filterType
        }
    }

    var isFullScreen = false {
        willSet {
            if (newValue) {
                self.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height - 40)
            } else {
                self.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 600)
            }
        }
    }

    var dataBaseName: String? {
        didSet {
            self.currentVC.dataBaseName = dataBaseName
        }
    }
}


//MARK: - Function
extension DDLoggerSwiftWindow {
    //
    @objc func cleanLog() {
        //删除指定数据
        HDSqliteTools.shared.deleteLog(timeStamp: Date().timeIntervalSince1970)
        self.currentVC._resetData()
    }
}

//MARK: - private Function
private extension DDLoggerSwiftWindow {
    @objc func changeWindowFrame() {
        self.isFullScreen = false
    }

    //MARK: Private method
    private func _init() {
        let rootVC = self.currentVC
        let navigationVC = UINavigationController(rootViewController: rootVC)
        self.rootViewController = navigationVC
        self.windowLevel =  UIWindow.Level.alert
        self.isUserInteractionEnabled = true
        self.backgroundColor = UIColor.clear
        //导航栏
        //set title
        let view = UIView()
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.attributedText = NSAttributedString(string: "DDLoggerSwift", attributes: [NSAttributedString.Key.font:UIFont.systemFont(ofSize: 18, weight: .medium), NSAttributedString.Key.foregroundColor:UIColor.black])
        view.addSubview(label)
        label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        self.currentVC.navigationItem.titleView = view
        //navigationBar leftview
        let button = UIButton(frame: .init(x: 0, y: 0, width: 25, height: 25))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImageHDBoundle(named: "log_icon_close"), for: .normal)
        button.addTarget(self, action: #selector(_clickClose), for: .touchUpInside)
        NSLayoutConstraint(item: button, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 25).isActive = true
        NSLayoutConstraint(item: button, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 25).isActive = true
        let leftbarItem = UIBarButtonItem(customView: button)
        
        let button1 = UIButton(frame: .init(x: 0, y: 0, width: 25, height: 25))
        button1.translatesAutoresizingMaskIntoConstraints = false
        button1.setImage(UIImageHDBoundle(named: "log_icon_subtract"), for: .normal)
        button1.addTarget(self, action: #selector(_clickHidden), for: .touchUpInside)
        NSLayoutConstraint(item: button1, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 25).isActive = true
        NSLayoutConstraint(item: button1, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 25).isActive = true
        let leftbarItem1 = UIBarButtonItem(customView: button1)
        
        let button2 = UIButton(frame: .init(x: 0, y: 0, width: 25, height: 25))
        button2.translatesAutoresizingMaskIntoConstraints = false
        button2.setImage(UIImageHDBoundle(named: "log_icon_scale"), for: .normal)
        button2.addTarget(self, action: #selector(_clickScale), for: .touchUpInside)
        NSLayoutConstraint(item: button2, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 25).isActive = true
        NSLayoutConstraint(item: button2, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 25).isActive = true
        let leftbarItem2 = UIBarButtonItem(customView: button2)
        
        rootVC.navigationItem.leftBarButtonItems = [leftbarItem, leftbarItem1, leftbarItem2]
        //right view
        let button5 = UIButton(frame: .init(x: 0, y: 0, width: 25, height: 25))
        button5.translatesAutoresizingMaskIntoConstraints = false
        button5.setImage(UIImageHDBoundle(named: "icon_normal_back"), for: .normal)
        button5.addTarget(self, action: #selector(_clickMenu), for: .touchUpInside)
        NSLayoutConstraint(item: button5, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 25).isActive = true
        NSLayoutConstraint(item: button5, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 25).isActive = true
        let leftbarItem5 = UIBarButtonItem(customView: button5)
        rootVC.navigationItem.rightBarButtonItems = [leftbarItem5]
        //
        self.changeWindowFrame()
        NotificationCenter.default.addObserver(self, selector: #selector(changeWindowFrame), name: UIApplication.didChangeStatusBarFrameNotification, object: nil)
    }
    
    @objc private func _clickScale() {
        self.isFullScreen = !self.isFullScreen
    }
    
    @objc private func _clickClose() {
        DDLoggerSwift.close()
    }
    
    @objc private func _clickHidden() {
        DDLoggerSwift.hide()
    }
    
    @objc private func _clickMenu() {
        let vc = DDMenuViewController()
        vc.contentVC = self.currentVC
        self.currentVC.navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func _show() {
        self.isHidden = false
    }

    //只隐藏log的输出窗口，保留悬浮图标
    func _hide() {
        DDLoggerSwift.hide()
    }
    
    func _close() {
        DDLoggerSwift.close()
    }
}
