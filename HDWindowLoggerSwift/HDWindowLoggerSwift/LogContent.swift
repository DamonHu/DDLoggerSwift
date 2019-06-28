//
//  LogContent.swift
//  HDWindowLoggerSwift
//
//  Created by Damon on 2019/6/28.
//  Copyright © 2019 Damon. All rights reserved.
//

import Foundation

public protocol LogContent {
    var logStringValue: String { get }
}

extension Dictionary: LogContent {
    public var logStringValue: String {
        let data = try? JSONSerialization.data(withJSONObject: self, options:JSONSerialization.WritingOptions.prettyPrinted)
        let defaultData = Data()
        return String(data: data ?? defaultData, encoding: String.Encoding.utf8) ?? ""
    }
}

extension Array: LogContent {
    public var logStringValue: String {
        let data = try? JSONSerialization.data(withJSONObject: self, options:JSONSerialization.WritingOptions.prettyPrinted)
        let defaultData = Data()
        return String(data: data ?? defaultData, encoding: String.Encoding.utf8) ?? ""
    }
}

extension String: LogContent {
    public var logStringValue: String {
        return self
    }
}
