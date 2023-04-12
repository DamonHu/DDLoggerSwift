//
//  ViewController.swift
//  ZXKitLogger
//
//  Created by Damon on 2019/6/24.
//  Copyright © 2019 Damon. All rights reserved.
//

import UIKit
#if canImport(ZXKitCore)
import ZXKitCore
#endif

class ViewController: UIViewController {

    lazy var clickButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.backgroundColor = UIColor.red
        button.frame = CGRect(x: 0, y: UIScreen.main.bounds.size.height - 230, width: 100, height: 60)
        button.setTitle("添加日志", for: UIControl.State.normal)
        return button
    }()
    
    lazy var showButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.backgroundColor = UIColor.red
        button.frame = CGRect(x: 120, y: UIScreen.main.bounds.size.height - 130, width: 100, height: 60)
        button.setTitle("显示弹层", for: UIControl.State.normal)
        return button
    }()
    
    lazy var deleteButton: UIButton = {
           let button = UIButton(type: UIButton.ButtonType.custom)
           button.backgroundColor = UIColor.red
           button.frame = CGRect(x: 240, y: UIScreen.main.bounds.size.height - 130, width: 150, height: 60)
           button.setTitle("删除本地日志文件", for: UIControl.State.normal)
           return button
    }()
    
    lazy var filterButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.backgroundColor = UIColor.red
        button.frame = CGRect(x: 0, y: UIScreen.main.bounds.size.height - 130, width: 100, height: 60)
        button.setTitle("过滤错误", for: UIControl.State.normal)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.view.addSubview(self.clickButton)
        self.view.addSubview(self.showButton)
        self.view.addSubview(self.deleteButton)
        self.view.addSubview(filterButton)
        
        self.showButton.addTarget(self, action: #selector(showButtonClick), for: UIControl.Event.touchUpInside)
        self.clickButton.addTarget(self, action: #selector(onClickButton), for: UIControl.Event.touchUpInside)
        self.deleteButton.addTarget(self, action: #selector(onClickdeleteButton), for: UIControl.Event.touchUpInside)
        self.filterButton.addTarget(self, action: #selector(filterButtonClick), for: UIControl.Event.touchUpInside)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //输出加密内容
        ZXKitLogger.privacyLogPassword = "12345678901234561234567890123456" //设置加密内容密码
        ZXKitLogger.uploadComplete = { filePath in
            print(filePath)
        }
    }
    
    @objc func showButtonClick(){
        ZXKitLogger.show()
    }

    @objc func filterButtonClick(){
        ZXKitLogger.show(filterType: .error)
    }
    
    
    @objc func onClickButton() {
//        ZXKit.show()
        printDebug("debug")
        printLog("ssss")
        printInfo("点击了按钮111")
        printError("错误出现")
        printInfo("调试数据文件地址", ZXKitLogger.getDBFolder().path)
        printWarn("警告提示")
        printPrivacy("这个是加密数据的测试数据222")
//
//        for _ in 0..<10 {
//            printLog("测试输出，默认不会写入数据库")
//            printLog("测试输出，默认不会写入数据库","222222","3333333")
//            //普通输出
//            printInfo("点击了按钮111")
//            printInfo("输出多个",22)
//            //输出警告内容
//            printWarn("警告提示")
//            //输出错误内容
//            printError("错误出现")
//
//            printPrivacy("这个是加密数据的测试数据222")
//            //输出字典
//            let dicObj = ["hhhhhhh":"撒旦法是打发斯蒂芬是打发斯蒂芬","77777":"数据库的复健科花见花开会尽快圣诞节开发和金黄色的费四大皆空回复就开始和豆腐是砍价的回复斯柯达金凤凰"]
//            printInfo(dicObj)
//            //输出数组
//            let arrayObj = ["1111111","22222222","sdjkhfsjkdfjkhsdhjfk","3333sjdhgfhjg"]
//            printInfo(arrayObj)
//        }

        print(ZXKitLogger.getItemCount(type: .info))
    }
    
    @objc func onClickdeleteButton() {
        ZXKitLogger.deleteLogFile()
    }
}

