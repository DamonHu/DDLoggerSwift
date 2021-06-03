//
//  ZXLogger+zxkit.swift
//  ZXKitLogger
//
//  Created by Damon on 2021/4/25.
//  Copyright © 2021 Damon. All rights reserved.
//

import Foundation
import ZXKitCore

//ZXKitPlugin
extension ZXKitLogger: ZXKitPluginProtocol {
    public var pluginIdentifier: String {
        return "com.zxkit.zxkitLogger"
    }
    
    public var pluginIcon: UIImage? {
        return UIImageHDBoundle(named: "logo")
    }

    public var pluginTitle: String {
        return "Logger".ZXLocaleString
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
        ZXKit.hide()
        ZXKitLogger.show()
    }
}

public extension ZXKitLogger {
    static func registZXKit() {
        ZXKit.regist(plugin: shared)
    }
}
