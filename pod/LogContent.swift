//
//  LogContent.swift
//  ZXKitLogger
//
//  Created by Damon on 2019/6/28.
//  Copyright © 2019 Damon. All rights reserved.
//

import Foundation
import ZXKitUtil

//输出内容需要遵循的协议
public protocol LogContent {
    var logStringValue: String { get }
}

///默认的几个输出类型
extension Dictionary: LogContent {
    public var logStringValue: String {
        if JSONSerialization.isValidJSONObject(self) {
            let data = try? JSONSerialization.data(withJSONObject: self, options:JSONSerialization.WritingOptions.prettyPrinted)
            if let data = data {
                let string = String(data: data, encoding: String.Encoding.utf8) ?? "\(self)"
                return string.zx.unicodeDecode()
            } else {
                let string = "\(self)"
                return string.zx.unicodeDecode()
            }
        } else {
            let string = "\(self)"
            return string.zx.unicodeDecode()
        }
    }
}

extension Array: LogContent {
    public var logStringValue: String {
        if JSONSerialization.isValidJSONObject(self) {
            let data = try? JSONSerialization.data(withJSONObject: self, options:JSONSerialization.WritingOptions.prettyPrinted)
            if let data = data {
                let string = String(data: data, encoding: String.Encoding.utf8) ?? "\(self)"
                return string.zx.unicodeDecode()
            } else {
                let string = "\(self)"
                return string.zx.unicodeDecode()
            }
        } else {
            let string = "\(self)"
            return string.zx.unicodeDecode()
        }
    }
}

extension String: LogContent {
    public var logStringValue: String {
        return self.zx.unicodeDecode()
    }
}
