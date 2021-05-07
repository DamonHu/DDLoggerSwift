//
//  ZXLogger+zxkit.swift
//  ZXKitLogger
//
//  Created by Damon on 2021/4/25.
//  Copyright © 2021 Damon. All rights reserved.
//

import Foundation
import ZXKitCore

func UIImageHDBoundle(named: String?) -> UIImage? {
    guard let name = named else { return nil }
    guard let bundlePath = Bundle(for: ZXKitLogger.self).path(forResource: "ZXKitLogger", ofType: "bundle") else { return nil }
    let bundle = Bundle(path: bundlePath)
    return UIImage(named: name, in: bundle, compatibleWith: nil)
}

//ZXKitPlugin
extension ZXKitLogger: ZXKitPluginProtocol {
    public var pluginIdentifier: String {
        return "com.zxkit.zxkitLogger"
    }
    
    public var pluginIcon: UIImage? {
        return UIImageHDBoundle(named: "logo")
    }

    public var pluginTitle: String {
        return NSLocalizedString("Logger", comment: "")
    }

    public var pluginType: ZXKitPluginType {
        return .data
    }

    public func start() {
        ZXKit.hide()
        ZXKitLogger.show()
    }

    public var isRunning: Bool {
        return true
    }

    public func stop() {
        ZXWarnLog(NSLocalizedString("System basic plug-in cannot be stopped", comment: ""))
        ZXKit.hide()
        ZXKitLogger.show()
    }
}

public extension ZXKitLogger {
    static func registZXKit() {
        ZXKit.regist(plugin: shared)
    }
}
