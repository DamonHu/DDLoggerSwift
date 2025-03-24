//
//  DDLoggerSwiftTCPSocketManager.swift
//  DDLoggerSwift
//
//  Created by Damon on 2022/8/2.
//  Copyright © 2022 Damon. All rights reserved.
//

import Foundation
import Network
import UIKit
import CommonCrypto
import DDUtils


@available(iOS 13.0, *)
class DDLoggerSwiftSocketManager: NSObject {
    public static let shared = DDLoggerSwiftSocketManager()
    private var netService: NetService? //发布bonjour服务
    var listener: NWListener?           //监听连接
    var connectList: [NWConnection] = []
}

@available(iOS 13.0, *)
extension DDLoggerSwiftSocketManager {
    func start() {
        
        // 创建并发布Bonjour服务
        netService = NetService(domain: "local.",
                                type: "\(DDLoggerSwift.socketType)._tcp.",
                                name: "DDLoggerSwift-Server",
                                port: DDLoggerSwift.socketPort)
        netService?.delegate = self
        netService?.publish()
        self.httpListener()
    }
    
    func httpListener() {
        let parameters = NWParameters.tcp
        parameters.includePeerToPeer = true
        do {
            listener = try NWListener(using: parameters, on: NWEndpoint.Port("\(DDLoggerSwift.socketPort)") ?? 0) // 任意端口
            listener?.service = NWListener.Service (name: DDLoggerSwift.userID + "-" + UIDevice.current.name, type: "\(DDLoggerSwift.socketType)._tcp", domain: "local.")
            listener?.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    print("Service is ready.")
                case .failed(let error):
                    print("Service failed with error: \(error)")
                default:
                    break
                }
            }
            
            listener?.newConnectionHandler = { [weak self] newConnection in
                print("New connection from \(newConnection.endpoint)")
                guard let self = self else { return }
                self.handleNewConnection(newConnection)
            }
            listener?.start(queue: .global())
        } catch {
            print("DDLoggerSwift_accept error", error)
        }
    }
    
    // 处理新连接
    func handleNewConnection(_ connection: NWConnection) {
        connection.start(queue: .global())
        self.connectList.append(connection)
//        self.receiveLogMessages(from: connection)
        performWebSocketHandshake(connection)
    }
    
    private func performWebSocketHandshake(_ connection: NWConnection) {
            connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { data, _, _, error in
                if let data = data, let request = String(data: data, encoding: .utf8) {
                    print("📩 收到握手请求:\n\(request)")

                    if request.contains("Upgrade: websocket") {
                        let response = """
                        HTTP/1.1 101 Switching Protocols\r
                        Upgrade: websocket\r
                        Connection: Upgrade\r
                        Sec-WebSocket-Accept: \(self.generateWebSocketAcceptKey(request))\r
                        \r
                        """
                        connection.send(content: response.data(using: .utf8), completion: .contentProcessed({ error in
                            if let error = error {
                                print("❌ 握手失败: \(error)")
                            } else {
                                print("✅ WebSocket 握手成功!")
                                self.send(loggerItem: DDLoggerSwiftItem())
                                self.receiveLogMessages(from: connection)
                            }
                        }))
                    }
                }
            }
        }

        private func generateWebSocketAcceptKey(_ request: String) -> String {
            let keyPrefix = "Sec-WebSocket-Key: "
            guard let keyRange = request.range(of: keyPrefix) else { return "" }
            let keyLine = request[keyRange.upperBound...].split(separator: "\r").first ?? ""
            let key = String(keyLine).trimmingCharacters(in: .whitespaces)
            let magicString = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
            let hash = (key + magicString).dd.hashString(hashType: .sha1)?.data(using: .utf8)
            return hash!.base64EncodedString()
        }
    
    func send(loggerItem: DDLoggerSwiftItem) {
        guard let data = "\(loggerItem.mLogItemType.rawValue)#\(loggerItem.mLogDebugContent)#\(loggerItem.mCreateDate.timeIntervalSince1970)#\(loggerItem.getLogContent())".data(using: .utf8) else { return
        }
        let frameHeader = Data([0x81])  // WebSocket 控制字节，用于文本帧
                let messageLength = Data([UInt8(data.count)])

                var dataToSend = frameHeader
                dataToSend.append(messageLength)
                dataToSend.append(data)
        for connection in self.connectList {
            connection.send(content: dataToSend, completion: .contentProcessed { error in
                if let error = error {
                    print("❌ 发送消息失败: \(error)")
                } else {
                    print("📤 发送消息成功")
                }
            })
        }
    }
    
    
    
    // 接收日志
    func receiveLogMessages(from connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { [weak self] data, context, isComplete, error in
            if let error = error {
                print("Receive error: \(error)")
                return
            }
            if let data = data, let logMessage = String(data: data, encoding: .utf8), logMessage == "DDLoggerClient_tcp_auth" {
                print("Received log message: \(logMessage)")
                //发送历史消息
                print("sssss", DDLoggerSwift.getAllLog().count)
                for loggerItem in DDLoggerSwift.getAllLog() {
                    self?.send(loggerItem: loggerItem)
                }
            }
            // 继续接收数据
            self?.receiveLogMessages(from: connection)
        }
    }
    
    func stop() {
        listener?.cancel()  // 取消监听
        listener = nil
        
    }
    
    
}


@available(iOS 13.0, *)
extension DDLoggerSwiftSocketManager: NetServiceDelegate {
    func netServiceDidPublish(_ sender: NetService) {
            print("Bonjour service published successfully")
            print("Service name: \(sender.name)")
            print("Service type: \(sender.type)")
            print("Service port: \(sender.port)")
        }
        
        func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
            print("Failed to publish service: \(errorDict)")
        }
}
