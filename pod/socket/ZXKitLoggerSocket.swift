//
//  ZXLogger+socket.swift
//  ZXKitLogger
//
//  Created by Damon on 2022/8/1.
//  Copyright © 2022 Damon. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

class ZXKitLoggerSocket: NSObject {
    public static let shared = ZXKitLoggerSocket()

    private lazy var serverSocket: GCDAsyncUdpSocket = {
        let queue = DispatchQueue.init(label: "zxkitlogger_socket")
        let socket = GCDAsyncUdpSocket(delegate: self, delegateQueue: queue, socketQueue: queue)
        do {
            try socket.bind(toPort: ZXKitLogger.socketPort)
        } catch {
            printError("socket.bind error: \(error.localizedDescription)")
        }
        do {
            try socket.beginReceiving()
        } catch {
            printError("socket.beginReceiving error: \(error.localizedDescription)")
        }
        return socket
    }()

    //client address
    private var addressList: [Data] = []
}

extension ZXKitLoggerSocket {
    func sendMsg(loggerItem: ZXKitLoggerItem) {
        guard !self.addressList.isEmpty else { return }
        //如果有订阅的才发送
        for address in addressList {
            guard let host = GCDAsyncUdpSocket.host(fromAddress: address) else { continue }
            let port = GCDAsyncUdpSocket.port(fromAddress: address)
            if let data = "\(loggerItem.mLogItemType.rawValue)|\(loggerItem.mLogDebugContent)|\(loggerItem.mCreateDate.timeIntervalSince1970)|\(loggerItem.getLogContent())".data(using: .utf8) {
                serverSocket.send(data, toHost: host, port: port, withTimeout: 60, tag: Int(loggerItem.mCreateDate.timeIntervalSince1970))
            }
        }
    }
}

extension ZXKitLoggerSocket: GCDAsyncUdpSocketDelegate {
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        //接受到需要log传输的消息，记录
        guard let receiveMsg = String(data: data, encoding: .utf8), receiveMsg == "ZXKitLogger_auth" else {
            return
        }
        //添加到address，重复的ip不添加
        if self.addressList.contains(where: { data in
            GCDAsyncUdpSocket.host(fromAddress: data) ==  GCDAsyncUdpSocket.host(fromAddress: address)
        }) {
            return
        }
        self.addressList.append(address)
    }
}
