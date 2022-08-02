//
//  ZXKitLoggerTCPSocket.swift
//  ZXKitLogger
//
//  Created by Damon on 2022/8/2.
//  Copyright © 2022 Damon. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

class ZXKitLoggerTCPSocket: NSObject {
    public static let shared = ZXKitLoggerTCPSocket()

    private lazy var serverSocket: GCDAsyncSocket = {
        let queue = DispatchQueue.init(label: "zxkitlogger_socket")
        let socket = GCDAsyncSocket(delegate: self, delegateQueue: queue, socketQueue: queue)
        do {
            try socket.accept(onPort: ZXKitLogger.socketPort)
        } catch {
            print("accept error", error)
        }
        return socket
    }()

    private var socketList: [GCDAsyncSocket] = []
}

extension ZXKitLoggerTCPSocket {
//    func start(host: String, port: UInt16) {
//        do {
//            try self.serverSocket.connect(toHost: host, onPort: port, withTimeout: 200)
//        } catch {
//            print("connect error", error)
//        }
//    }

    func send(loggerItem: ZXKitLoggerItem) {
        if self.serverSocket.isConnected, let data = "\(loggerItem.mLogItemType.rawValue)|\(loggerItem.mLogDebugContent)|\(loggerItem.mCreateDate.timeIntervalSince1970)|\(loggerItem.getLogContent())".data(using: .utf8) {
            self.serverSocket.write(data, withTimeout: 20, tag: Int(loggerItem.mCreateDate.timeIntervalSince1970))
        }
    }

}

extension ZXKitLoggerTCPSocket: GCDAsyncSocketDelegate {
    func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        print("didAcceptNewSocket")
        sock.delegate = self
        newSocket.delegate = self
        socketList.append(newSocket)
    }

    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        print("didConnectToHost", host, port)
    }

    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        print("socketDidDisconnect", err)
    }

    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        print("didWriteDataWithTag")
    }

    func socket(_ sock: GCDAsyncSocket, didConnectTo url: URL) {
        print("didConnectTo")
    }

    func socket(_ sock: GCDAsyncSocket, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
        print("didReceive")
    }

    func socket(_ sock: GCDAsyncSocket, didReadPartialDataOfLength partialLength: UInt, tag: Int) {
        print("didReadPartialDataOfLength")
    }

    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        print("didReceive", String(data: data, encoding: .utf8))
    }
}
