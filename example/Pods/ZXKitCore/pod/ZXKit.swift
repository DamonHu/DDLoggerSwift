//
//  ZXKit.swift
//  ZXKit
//
//  Created by Damon on 2021/4/23.
//

import UIKit

public class ZXKit: NSObject {
    static var window: ZXKitWindow?
    static var floatWindow: ZXKitFloatWindow?
    static var pluginList = [[ZXKitPluginProtocol](), [ZXKitPluginProtocol](), [ZXKitPluginProtocol]()]

    public static func regist(plugin: ZXKitPluginProtocol) {
        switch plugin.pluginType {
            case .ui:
                self.pluginList[0].append(plugin)
            case .data:
                self.pluginList[1].append(plugin)
            case .other:
                self.pluginList[2].append(plugin)
        }

        if let window = self.window, !window.isHidden {
            DispatchQueue.main.async {
                window.reloadData()
            }
        }
    }

    public static func show() {
        self.floatWindow?.isHidden = true
        DispatchQueue.main.async {
            if let window = self.window {
                window.isHidden = false
            } else {
                if #available(iOS 13.0, *) {
                    for windowScene:UIWindowScene in ((UIApplication.shared.connectedScenes as? Set<UIWindowScene>)!) {
                        if windowScene.activationState == .foregroundActive {
                            self.window = ZXKitWindow(windowScene: windowScene)
                            self.window?.frame = UIScreen.main.bounds
                        }
                    }
                }
                if self.window == nil {
                    self.window = ZXKitWindow(frame: UIScreen.main.bounds)
                }
                self.window?.isHidden = false
            }
        }
    }

    public static func hide() {
        DispatchQueue.main.async {
            self.window?.isHidden = true
            //float window
            if let window = self.floatWindow {
                window.isHidden = false
            } else {
                if #available(iOS 13.0, *) {
                    for windowScene:UIWindowScene in ((UIApplication.shared.connectedScenes as? Set<UIWindowScene>)!) {
                        if windowScene.activationState == .foregroundActive {
                            self.floatWindow = ZXKitFloatWindow(windowScene: windowScene)
                            self.floatWindow?.frame = CGRect(x: UIScreen.main.bounds.size.width - 80, y: 100, width: 60, height: 60)
                        }
                    }
                }
                if self.floatWindow == nil {
                    self.floatWindow = ZXKitFloatWindow(frame: CGRect(x: UIScreen.main.bounds.size.width - 80, y: 100, width: 60, height: 60))
                }
                self.floatWindow?.isHidden = false
            }
        }
    }

    public static func close() {
        DispatchQueue.main.async {
            self.window?.isHidden = true
            self.floatWindow?.isHidden = true
        }
    }
}
