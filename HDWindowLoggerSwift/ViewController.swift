//
//  ViewController.swift
//  HDWindowLoggerSwift
//
//  Created by Damon on 2019/6/24.
//  Copyright © 2019 Damon. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    lazy var clickButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.backgroundColor = UIColor.red
        button.frame = CGRect(x: 0, y: UIScreen.main.bounds.size.height - 130, width: 200, height: 100)
        button.setTitle("点击添加日志", for: UIControl.State.normal)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.clickButton)
        self.clickButton.addTarget(self, action: #selector(onClickButton), for: UIControl.Event.touchUpInside)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        HDWindowLoggerSwift.show()
        HDNormalLog(log: "收到就好丰盛的金凤凰就水电费交mmm换机时间开始的回复是砍价的回复四大皆空回复速度快解放后搜的飞机开会接口是点击开发还是手机打开混分巨兽地方收到就好丰盛的金凤凰就水电费交换机时间开始的回复是砍价的回复四大皆空回复速度快解放后搜的飞机开会接口是点击开发还是手机打开混分巨兽地方收到就好丰盛的金凤凰就水电费交换机时间开始的回复是砍价的回复四大皆空回复速度快解放后搜的飞机开会接口是点击开发还是手机打开混分巨兽地方" as AnyObject)
    }

    @objc func onClickButton() {
        HDNormalLog(log: "点击了按钮111" as AnyObject)
        HDWindowLoggerSwift.printLog(log: "点击了按钮警告类型" as AnyObject, logType: HDLogType.kHDLogTypeError)
        let dicObj = ["hhhhhhh":"撒旦法是打发斯蒂芬是打发斯蒂芬","77777":"数据库的复健科花见花开会尽快圣诞节开发和金黄色的费四大皆空回复就开始和豆腐是砍价的回复斯柯达金凤凰"]
        HDNormalLog(log: dicObj as AnyObject)
        let arrayObj = ["1111111","22222222","sdjkhfsjkdfjkhsdhjfk","3333sjdhgfhjg"]
        HDNormalLog(log: arrayObj as AnyObject)
    }
}

