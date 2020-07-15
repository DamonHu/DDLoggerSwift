//
//  UIColor+hd.swift
//  HDSwiftCommonTools
//
//  Created by Damon on 2020/7/9.
//  Copyright © 2020 Damon. All rights reserved.
//

import UIKit

extension UIColor: HDNameSpaceWrappable {

}

public extension HDNameSpace where T : UIColor {
    ///16进制颜色转为UIColor 0xffffff
    static func color(with hexValue: Int, darkHexValue: Int = 0x333333, alpha: Float = 1.0, darkAlpha: Float = 1.0) -> UIColor {
        return UIColor(with: hexValue, darkHexValue: darkHexValue, alpha: alpha, darkAlpha: darkAlpha)
    }
    
    ///16进制字符串转为UIColor #ffffff
    static func color(with hexString: String, darkHexString: String = "#333333", alpha: CGFloat = 1.0, darkAlpha: CGFloat = 1.0) -> UIColor {
        return UIColor(with: hexString, darkHexString: darkHexString, alpha: alpha, darkAlpha: darkAlpha)
    }
}
