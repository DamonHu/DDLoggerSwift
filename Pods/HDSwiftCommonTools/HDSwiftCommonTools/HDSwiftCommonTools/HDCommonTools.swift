//
//  HDCommonTools.swift
//  HDSwiftCommonTools
//
//  Created by Damon on 2020/7/2.
//  Copyright © 2020 Damon. All rights reserved.
//

import UIKit

open class HDCommonTools: NSObject {
    public static let shared: HDCommonTools = {
        let tShared = HDCommonTools()
        return tShared
    }()
}
