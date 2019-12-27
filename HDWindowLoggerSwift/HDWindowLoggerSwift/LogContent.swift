//
//  LogContent.swift
//  HDWindowLoggerSwift
//
//  Created by Damon on 2019/6/28.
//  Copyright © 2019 Damon. All rights reserved.
//

import Foundation

//输出内容需要遵循的协议
public protocol LogContent {
    var logStringValue: String { get }
}

///默认的几个输出类型
extension Dictionary: LogContent {
    public var logStringValue: String {
        let data = try? JSONSerialization.data(withJSONObject: self, options:JSONSerialization.WritingOptions.prettyPrinted)
        let defaultData = Data()
        return String(data: data ?? defaultData, encoding: String.Encoding.utf8) ?? "\(self)"
    }
}

extension Array: LogContent {
    public var logStringValue: String {
        let data = try? JSONSerialization.data(withJSONObject: self, options:JSONSerialization.WritingOptions.prettyPrinted)
        let defaultData = Data()
        return String(data: data ?? defaultData, encoding: String.Encoding.utf8) ?? "\(self)"
    }
}

extension String: LogContent {
    public var logStringValue: String {
        return self
    }
}

extension URL: LogContent {
    public var logStringValue: String {
        return self.absoluteString
    }
}
