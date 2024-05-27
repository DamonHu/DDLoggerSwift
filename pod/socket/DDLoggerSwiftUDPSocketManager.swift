//
//  ZXLogger+socket.swift
//  DDLoggerSwift
//
//  Created by Damon on 2022/8/1.
//  Copyright © 2022 Damon. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

class DDLoggerSwiftUDPSocketManager: NSObject {
    public static let shared = DDLoggerSwiftUDPSocketManager()

    private lazy var serverSocket: GCDAsyncUdpSocket = {
        let queue = DispatchQueue.init(label: "DDLoggerSwift_socket")
        let socket = GCDAsyncUdpSocket(delegate: self, delegateQueue: queue, socketQueue: queue)
        return socket
    }()

    //client address
    private var addressList: [Data] = []
}

extension DDLoggerSwiftUDPSocketManager {
    func start() {
        if serverSocket.isConnected() {
            print("isConnected")
            return
        }
        do {
            try serverSocket.bind(toPort: DDLoggerSwift.socketPort)
        } catch {
            printError("socket.bind error: \(error.localizedDescription)")
        }
        do {
            try serverSocket.beginReceiving()
        } catch {
            printError("socket.beginReceiving error: \(error.localizedDescription)")
        }
    }
    func send(loggerItem: DDLoggerSwiftItem) {
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

extension DDLoggerSwiftUDPSocketManager: GCDAsyncUdpSocketDelegate {
    func udpSocket(_ sock: GCDAsyncUdpSocket, didConnectToAddress address: Data) {
        print("address")
    }
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotConnect error: Error?) {
        print("didNotConnect", error)
    }
    func udpSocket(_ sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
        print("didSend")
    }
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: Error?) {
        print("didNotSendDataWithTag", error)
    }

    func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
        print("udpSocketDidClose", error)
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        printLog("didReceive", String(data: data, encoding: .utf8), GCDAsyncUdpSocket.host(fromAddress: address), GCDAsyncUdpSocket.port(fromAddress: address))
        //接受到需要log传输的消息，记录
        guard let receiveMsg = String(data: data, encoding: .utf8), receiveMsg == "DDLoggerSwift_auth" else {
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
