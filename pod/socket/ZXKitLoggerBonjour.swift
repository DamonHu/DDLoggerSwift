//
//  ZXKitLoggerBonjour.swift
//  ZXKitLogger
//
//  Created by Damon on 2022/8/2.
//  Copyright © 2022 Damon. All rights reserved.
//

import Foundation
import Network
import UIKit

class ZXKitLoggerBonjour: NSObject {
    static let shared = ZXKitLoggerBonjour()

    lazy var mService: NetService = {
        let type = ZXKitLogger.isTCP ? "_tcp" : "_udp"
        let service = NetService(domain: "\(ZXKitLogger.socketDomain).", type: "\(ZXKitLogger.socketType).\(type)", name: ZXKitLogger.userID + "-" + UIDevice.current.name, port: Int32(ZXKitLogger.socketPort))
        service.schedule(in: .current, forMode: .common)
        service.includesPeerToPeer = true
        service.delegate = self
        return service
    }()

}

extension ZXKitLoggerBonjour {
    func start() {
        if let data = "ZXKitLoggerBonjour".data(using: .utf8) {
            let sendData = NetService.data(fromTXTRecord: ["node" : data])
            self.mService.setTXTRecord(sendData)
            self.mService.publish()
        }
    }
}

extension ZXKitLoggerBonjour: NetServiceDelegate {
    func netServiceWillPublish(_ sender: NetService) {
        print("ZXKitLogger_netServiceWillPublish")
    }
    func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        print("ZXKitLogger_didNotPublish", errorDict)
    }

    func netServiceDidResolveAddress(_ sender: NetService) {
//        print("----netService didResolveAddress", sender.name, sender.addresses, sender.hostName, sender.addresses?.first)
//        let data = sender.txtRecordData()
//        let dict = NetService.dictionary(fromTXTRecord: data!)
//        let info = String.init(data: dict["node"]!, encoding: String.Encoding.utf8)
    }
}
