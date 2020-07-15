//
//  UIImage+hd.swift
//  HDSwiftCommonTools
//
//  Created by Damon on 2020/7/11.
//  Copyright © 2020 Damon. All rights reserved.
//

import UIKit

extension UIImage: HDNameSpaceWrappable {

}

public extension HDNameSpace where T : UIImage {
    ///通过颜色获取纯色图片
    static func getImage(by color: UIColor) -> UIImage {
        return HDCommonTools.shared.getImage(by: color)
    }
    
    ///线性渐变
    static func getLinearGradientImage(colors: [UIColor], directionType: HDGradientDirection, size: CGSize = CGSize(width: 100, height: 100)) -> UIImage {
        return HDCommonTools.shared.getLinearGradientImage(colors: colors, directionType: directionType, size: size)
    }
    
    ///角度渐变
    static func getRadialGradientImage(colors: [UIColor], raduis: CGFloat, size: CGSize = CGSize(width: 100, height: 100)) -> UIImage {
        return HDCommonTools.shared.getRadialGradientImage(colors: colors, raduis: raduis, size: size)
    }
}
