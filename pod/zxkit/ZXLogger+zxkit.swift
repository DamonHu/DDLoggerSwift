//
//  ZXLogger+zxkit.swift
//  ZXKitLogger
//
//  Created by Damon on 2021/4/25.
//  Copyright © 2021 Damon. All rights reserved.
//

import Foundation

#if canImport(ZXKitCore)
import ZXKitCore

func UIImageHDBoundle(named: String?) -> UIImage? {
    guard let name = named else { return nil }
    guard let bundlePath = Bundle(for: ZXKitLogger.self).path(forResource: "ZXKitLogger", ofType: "bundle") else { return nil }
    let bundle = Bundle(path: bundlePath)
    return UIImage(named: name, in: bundle, compatibleWith: nil)
}

//ZXKitPlugin
extension ZXKitLogger: ZXKitPluginProtocol {
    public var pluginIcon: UIImage? {
        return UIImageHDBoundle(named: "log")
    }

    public var pluginTitle: String {
        return NSLocalizedString("ZXKitLogger", comment: "")
    }

    public var pluginType: ZXKitPluginType {
        return .data
    }

    public func start() {
        ZXKitLogger.show()
    }
}
#endif
