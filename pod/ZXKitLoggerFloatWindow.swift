//
//  ZXKitLoggerFloatWindow.swift
//  ZXKitLogger
//
//  Created by Damon on 2021/4/28.
//  Copyright © 2021 Damon. All rights reserved.
//

import UIKit
import ZXKitUtil

class ZXKitLoggerFloatWindow: UIWindow {

    @available(iOS 13.0, *)
    override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)
        self._initVC()
        self._createUI()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self._initVC()
        self._createUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var mButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor.zx.color(hexValue: 0x5dae8b)
        button.setTitle("Z".ZXLocaleString, for: UIControl.State.normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 23, weight: .bold)
        button.layer.borderColor = UIColor.zx.color(hexValue: 0xffffff).cgColor
        button.zx.addLayerShadow(color: UIColor.zx.color(hexValue: 0x333333), offset: CGSize(width: 2, height: 2), radius: 4, cornerRadius: 30)
        button.layer.borderWidth = 4.0
        button.addTarget(self, action: #selector(_show), for: UIControl.Event.touchUpInside)
        button.frame = CGRect(x: 0, y: 0, width: 60, height: 60)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(_touchMove(p:)))
        button.addGestureRecognizer(pan)
        return button
    }()

}

private extension ZXKitLoggerFloatWindow {

    func _initVC() {
        self.rootViewController = UIViewController()
        self.windowLevel =  UIWindow.Level.alert
        self.isUserInteractionEnabled = true
    }

    @objc func _show() {
        ZXKitLogger.show()
    }

    func _createUI() {
        guard let rootViewController = self.rootViewController else {
            return
        }
        rootViewController.view.addSubview(mButton)
        mButton.leftAnchor.constraint(equalTo: rootViewController.view.leftAnchor).isActive = true
        mButton.rightAnchor.constraint(equalTo: rootViewController.view.rightAnchor).isActive = true
        mButton.topAnchor.constraint(equalTo: rootViewController.view.topAnchor).isActive = true
        mButton.bottomAnchor.constraint(equalTo: rootViewController.view.bottomAnchor).isActive = true
    }

    @objc private func _touchMove(p:UIPanGestureRecognizer) {
        guard let window = ZXKitUtil.shared.getCurrentNormalWindow() else { return }
        let panPoint = p.location(in: window)
        //跟随手指拖拽
        if p.state == .changed {
            self.center = CGPoint(x: panPoint.x, y: panPoint.y)
            p.setTranslation(CGPoint.zero, in: self)
        }
        //弹回边界
        if p.state == .ended || p.state == .cancelled {
            var x: CGFloat = 50
            if panPoint.x > (window.bounds.size.width) / 2.0 {
                x = window.bounds.size.width - 50
            }
            let y = min(max(130, panPoint.y), window.bounds.size.height - 140)
            p.setTranslation(CGPoint.zero, in: self)
            UIView.animate(withDuration: 0.35) {
                self.center = CGPoint(x: x, y: y)
            }
        }
    }
}
