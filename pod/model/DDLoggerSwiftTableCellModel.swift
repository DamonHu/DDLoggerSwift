//
//  DDLoggerSwiftTableCellModel.swift
//  DDLoggerSwift
//
//  Created by Damon on 2025/2/21.
//  Copyright © 2025 Damon. All rights reserved.
//

import UIKit

class DDLoggerSwiftTableCellModel: NSObject {
    var logItem = DDLoggerSwiftItem()
    var isCollapse = false
    
    convenience init(model: DDLoggerSwiftItem) {
        self.init()
        self.logItem = model
        self.isCollapse = model.getFullContentString().count > DDLoggerSwift.cellDisplayCount
    }
}
