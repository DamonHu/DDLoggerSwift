//
//  HDNameSpace.swift
//  HDCommonToolsSwift
//
//  Created by Damon on 2020/7/3.
//  Copyright © 2020 Damon. All rights reserved.
//

import Foundation

public struct HDNameSpace <T> {
    let object: T       //存储的实例对象
    
    internal init(object: T) {
        self.object = object
    }
}

//实现命名空间需遵守的协议
public protocol HDNameSpaceWrappable {
    associatedtype WrapperType
    var hd: WrapperType { get }
    static var hd: WrapperType.Type { get }
}


//协议默认的实现方式
public extension HDNameSpaceWrappable {
    var hd: HDNameSpace<Self> {
        return HDNameSpace(object: self)
    }

    static var hd: HDNameSpace<Self>.Type {
        return HDNameSpace.self
    }
}
