//
//  HDCommonToolsSwift.swift
//  HDCommonToolsSwift
//
//  Created by Damon on 2020/7/2.
//  Copyright © 2020 Damon. All rights reserved.
//

import UIKit

open class HDCommonToolsSwift: NSObject {
    public static let shared: HDCommonToolsSwift = {
        let tShared = HDCommonToolsSwift()
        return tShared
    }()
}
