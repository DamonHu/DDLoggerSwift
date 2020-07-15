//
//  HDCommonTools+system.swift
//  HDSwiftCommonTools
//
//  Created by Damon on 2020/7/3.
//  Copyright © 2020 Damon. All rights reserved.
//

import Foundation
import UIKit
import AdSupport
import SystemConfiguration.CaptiveNetwork
import StoreKit

public enum HDOpenAppStoreType {
    case app        //应用内打开，ios10.3以下无反应
    case appStore   //跳转到App Store
    case auto       //ios10.3以上应用内打开，以下跳转到App Store打开
}

public extension HDCommonTools {
    ///获取软件版本
    func getAppVersionString() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        return version ?? ""
    }
    
    ///获取软件构建版本
    func getAppBuildVersionString() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        return version ?? ""
    }
    
    ///获取系统的iOS版本
    func getIOSVersionString() -> String {
        return UIDevice.current.systemVersion
    }
    
    ///获取系统语言
    func getIOSLanguageStr() -> String {
        let language = Bundle.main.preferredLocalizations.first
        return language ?? ""
    }
    
    ///获取软件Bundle Identifier
    func getBundleIdentifier() -> String {
        return Bundle.main.bundleIdentifier ?? ""
    }
    
    ///获取本机机型标识
    func getSystemHardware() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
    
    ///获取本机上次重启时间
    func getSystemUpTime() -> TimeInterval {
        let timeInterval = ProcessInfo.processInfo.systemUptime
        return Date().timeIntervalSince1970 - timeInterval
    }
    
    /// 模拟软件唯一标示
    /// - Parameter idfvIfFailed: 如果用户禁止获取本机idfa，是否去尝试使用idfv
    /// - Returns: 唯一标识
    func getIDFAString(idfvIfFailed: Bool = true) -> String {
        if ASIdentifierManager.shared().isAdvertisingTrackingEnabled {
            return ASIdentifierManager.shared().advertisingIdentifier.uuidString
        } else {
            return UIDevice.current.identifierForVendor?.uuidString ?? ""
        }
    }
    
    ///获取手机WIFI的MAC地址，需要开启Access WiFi information
    func getMacAddress() -> (ssid: String?, mac: String?) {
        let interfaces:NSArray = CNCopySupportedInterfaces()!
        var ssid: String?
        var mac: String?
        for sub in interfaces {
            if let dict = CFBridgingRetain(CNCopyCurrentNetworkInfo(sub as! CFString)) {
                ssid = dict["SSID"] as? String
                mac = dict["BSSID"] as? String
                break
            }
        }
        return (ssid: ssid, mac: mac)
    }
    
    ///打开系统设置
    func openSystemSetting() -> Void {
        let url = URL(string: UIApplication.openSettingsURLString)!
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    ///打开软件对应的App Store页面
    func openAppStorePage(openType: HDOpenAppStoreType, appleID: String) -> Void {
        switch openType {
        case .app:
            let storeProductVC = SKStoreProductViewController()
            storeProductVC.delegate = self
            storeProductVC.loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier : appleID]) { (success, error) in
                if success {
                    self.getCurrentVC()?.present(storeProductVC, animated: true, completion: nil)
                }
            }
        case .appStore:
            let url = URL(string: "https://itunes.apple.com/app/id\(appleID)")!
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        case .auto:
            let storeProductVC = SKStoreProductViewController()
            storeProductVC.delegate = self
            storeProductVC.loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier : appleID]) { (success, error) in
                if success {
                    self.getCurrentVC()?.present(storeProductVC, animated: true, completion: nil)
                } else {
                    let url = URL(string: "https://itunes.apple.com/app/id\(appleID)")!
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
        }
    }
    
    ///打开软件对应的评分页面
    func openAppStoreReviewPage(openType: HDOpenAppStoreType, appleID: String = "") -> Void {
        switch openType {
        case .app:
            if #available(iOS 10.3, *) {
                SKStoreReviewController.requestReview()
            } else {
                
            };
        case .appStore:
            let url = URL(string: "itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=\(appleID)")!
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        case .auto:
            if #available(iOS 10.3, *) {
                SKStoreReviewController.requestReview()
            } else {
                let url = URL(string: "itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=\(appleID)")!
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
}

extension HDCommonTools : SKStoreProductViewControllerDelegate {
    public func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
}
