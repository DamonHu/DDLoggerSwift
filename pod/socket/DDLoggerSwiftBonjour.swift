//
//  DDLoggerSwiftBonjour.swift
//  DDLoggerSwift
//
//  Created by Damon on 2022/8/2.
//  Copyright © 2022 Damon. All rights reserved.
//

import Foundation
import Network
import UIKit

class DDLoggerSwiftBonjour: NSObject {
    static let shared = DDLoggerSwiftBonjour()

    lazy var mService: NetService = {
        let type = DDLoggerSwift.isTCP ? "_tcp" : "_udp"
        let service = NetService(domain: "\(DDLoggerSwift.socketDomain).", type: "\(DDLoggerSwift.socketType).\(type)", name: DDLoggerSwift.userID + "-" + UIDevice.current.name, port: Int32(DDLoggerSwift.socketPort))
        service.schedule(in: .current, forMode: .common)
        service.includesPeerToPeer = true
        service.delegate = self
        return service
    }()

}

extension DDLoggerSwiftBonjour {
    func start() {
        if let data = "DDLoggerSwiftBonjour".data(using: .utf8) {
            let sendData = NetService.data(fromTXTRecord: ["node" : data])
            self.mService.setTXTRecord(sendData)
            self.mService.publish()
        }
    }
}

extension DDLoggerSwiftBonjour: NetServiceDelegate {
    func netServiceWillPublish(_ sender: NetService) {
        print("DDLoggerSwift_netServiceWillPublish")
    }
    func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        print("DDLoggerSwift_didNotPublish", errorDict)
    }

    func netServiceDidResolveAddress(_ sender: NetService) {
//        print("----netService didResolveAddress", sender.name, sender.addresses, sender.hostName, sender.addresses?.first)
//        let data = sender.txtRecordData()
//        let dict = NetService.dictionary(fromTXTRecord: data!)
//        let info = String.init(data: dict["node"]!, encoding: String.Encoding.utf8)
    }
}
