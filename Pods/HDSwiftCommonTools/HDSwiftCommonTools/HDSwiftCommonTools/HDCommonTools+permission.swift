//
//  HDCommonTools+permission.swift
//  HDSwiftCommonTools
//
//  Created by Damon on 2020/7/3.
//  Copyright © 2020 Damon. All rights reserved.
//

import Foundation
import AVFoundation
import Photos
import UserNotifications

public enum HDPermissionType {
    case audio          //麦克风权限
    case video          //相机权限
    case photoLibrary   //相册权限
    case GPS            //定位权限
    case notification   //通知权限
}

public enum HDPermissionStatus {
    case authorized     //用户允许
    case restricted     //被限制修改不了状态,比如家长控制选项等
    case denied         //用户拒绝
    case notDetermined  //用户尚未选择
}

public extension HDCommonTools {
    ///请求权限
    func requestPermission(type: HDPermissionType, complete: @escaping ((HDPermissionStatus) -> Void)) -> Void {
        switch type {
        case .audio:
            AVCaptureDevice.requestAccess(for: .audio) { (granted) in
                if granted {
                    complete(.authorized)
                } else {
                    complete(.denied)
                }
            }
        case .video:
            AVCaptureDevice.requestAccess(for: .video) { (granted) in
                if granted {
                    complete(.authorized)
                } else {
                    complete(.denied)
                }
            }
        case .photoLibrary:
            PHPhotoLibrary.requestAuthorization { (status) in
                switch status {
                case .notDetermined:
                    complete(.notDetermined)
                case .restricted:
                    complete(.restricted)
                case .denied:
                    complete(.denied)
                case .authorized:
                    complete(.authorized)
                @unknown default:
                    complete(.authorized)
                }
            }
        case .GPS:
            CLLocationManager().requestWhenInUseAuthorization()
            CLLocationManager().requestAlwaysAuthorization()
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.checkPermission(type: HDPermissionType.GPS, complete: complete)
            }
        case .notification:
            UNUserNotificationCenter.current().requestAuthorization(options: UNAuthorizationOptions(rawValue: UNAuthorizationOptions.alert.rawValue | UNAuthorizationOptions.sound.rawValue | UNAuthorizationOptions.badge.rawValue)) { (granted, error) in
                if granted {
                    complete(.authorized)
                } else {
                    complete(.denied)
                }
            }
        }
    }
    
    ///检测权限
    func checkPermission(type: HDPermissionType, complete: @escaping ((HDPermissionStatus) -> Void)) -> Void {
        switch type {
        case .audio:
            let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.audio)
            switch status {
            case .notDetermined:
                complete(.notDetermined)
            case .restricted:
                complete(.restricted)
            case .denied:
                complete(.denied)
            case .authorized:
                complete(.authorized)
            @unknown default:
                complete(.authorized)
            }
        case .video:
            let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
            switch status {
            case .notDetermined:
                complete(.notDetermined)
            case .restricted:
                complete(.restricted)
            case .denied:
                complete(.denied)
            case .authorized:
                complete(.authorized)
            @unknown default:
                complete(.authorized)
            }
        case .photoLibrary:
            let status = PHPhotoLibrary.authorizationStatus()
            switch status {
            case .notDetermined:
                complete(.notDetermined)
            case .restricted:
                complete(.restricted)
            case .denied:
                complete(.denied)
            case .authorized:
                complete(.authorized)
            @unknown default:
                complete(.authorized)
            }
        case .GPS:
            if CLLocationManager.locationServicesEnabled() && CLLocationManager.authorizationStatus() == .authorizedAlways || CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
                complete(.authorized)
            } else if CLLocationManager.authorizationStatus() == .notDetermined {
                complete(.notDetermined)
            } else if CLLocationManager.authorizationStatus() == .restricted {
                complete(.restricted)
            } else if CLLocationManager.authorizationStatus() == .denied {
                complete(.denied)
            }
        case .notification:
            UNUserNotificationCenter.current().getNotificationSettings { (notificationSettings) in
                switch notificationSettings.authorizationStatus {
                case .notDetermined:
                    complete(.notDetermined)
                case .denied:
                    complete(.denied)
                case .authorized:
                    complete(.authorized)
                case .provisional:
                    complete (.authorized)
                @unknown default:
                    complete(.authorized)
                }
            }
        }
    }
}
