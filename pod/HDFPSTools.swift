//
//  HDFPSTools.swift
//  ZXKitLogger
//
//  Created by Damon on 2021/3/10.
//  Copyright © 2021 Damon. All rights reserved.
//

import UIKit

class HDFPSTools {
    var complete: ((Int) -> Void)?
    var showFPS = true {
        willSet {
            if newValue {
                self.displayLink = CADisplayLink(target: self, selector: #selector(tick(link:)))
                self.displayLink?.add(to: RunLoop.main, forMode: .common)
            } else {
                self.displayLink?.invalidate()
            }
        }
    }            //是否显示屏幕FPS状态
    
    private var displayLink: CADisplayLink?     //fps显示
    private var lastTime: TimeInterval = 0
    private var count = 0

    init(complete: ((Int) -> Void)? = nil) {
        self.complete = complete
    }
}

extension HDFPSTools {
    @objc func tick(link: CADisplayLink) {
        guard lastTime != 0 else {
            lastTime = link.timestamp
            return
        }
        count = count + 1
        let delta = link.timestamp - lastTime
        guard delta >= 1 else { return }
        lastTime = link.timestamp
        let fps = round(Double(count) / delta)
        count = 0
        if let complete = complete {
            complete(Int(fps))
        }
    }
}
