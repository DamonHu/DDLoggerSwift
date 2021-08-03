//
//  AppDelegate.swift
//  ZXKitLogger
//
//  Created by Damon on 2019/6/24.
//  Copyright © 2019 Damon. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let vc = ViewController()
        self.window?.rootViewController = vc
        self.window?.makeKeyAndVisible()

        //如果需要支持zxkit，需要先注册
        #if canImport(ZXKitCore)
        ZXKitLogger.registZXKit()
        #endif
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

