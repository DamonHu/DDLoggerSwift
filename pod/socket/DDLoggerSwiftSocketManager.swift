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


@available(iOS 13.0, *)
class DDLoggerSwiftSocketManager: NSObject {
    public static let shared = DDLoggerSwiftSocketManager()
    private var netService: NetService? //发布bonjour服务
    var listener: NWListener?           //监听连接
    //socket
    var webSocketTaskList: [URLSessionWebSocketTask] = []
    let session = URLSession(configuration: .default)
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
    }
    
    func startWebSocketServer() {
        print("sssss", self.getLocalIPAddress())
        let url = URL(string: "ws://\(getLocalIPAddress()):\(DDLoggerSwift.socketPort)")! // 监听所有 IP
        let webSocketTask = session.webSocketTask(with: url)
        self.webSocketTaskList.append(webSocketTask)
        // 启动 WebSocket 任务
        webSocketTask.resume()
        // 接收消息
        self.receiveMessage(webSocketTask)
    }
    
    func getLocalIPAddress() -> String {
        var address: String = "127.0.0.1"
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
            
            if getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr {
                var ptr = firstAddr
                while ptr.pointee.ifa_next != nil {
                    defer { ptr = ptr.pointee.ifa_next! }
                    let interface = ptr.pointee
                    let addrFamily = interface.ifa_addr.pointee.sa_family
                    
                    if addrFamily == AF_INET { // 仅获取 IPv4 地址
                        let name = String(cString: interface.ifa_name)
                        if name == "en0" { // en0 代表 Wi-Fi 适配器
                            var addr = interface.ifa_addr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }
                            address = String(cString: inet_ntoa(addr.sin_addr))
                            break
                        }
                    }
                }
                freeifaddrs(ifaddr)
            }
            return address
    }
    
    private func receiveMessage(_ websocket: URLSessionWebSocketTask) {
            websocket.receive { [weak self] result in
                switch result {
                case .success(let message):
                    switch message {
                    case .string(let text):
                        print("Received message: \(text)")
                    case .data(let data):
                        if let logMessage = String(data: data, encoding: .utf8) {
                            print("Received log message: \(logMessage)")
                            if (logMessage == "DDLoggerClient_tcp_auth") {
                                //发送历史消息
                                print("sssss", DDLoggerSwift.getAllLog().count)
                                for loggerItem in DDLoggerSwift.getAllLog() {
                                    self?.send(loggerItem: loggerItem)
                                }
                            }
                        }
                    @unknown default:
                        break
                    }
                    // 继续接收下一条消息
                    self?.receiveMessage(websocket)
                case .failure(let error):
                    print("Error receiving message: \(error)")
                    if let index = self?.webSocketTaskList.firstIndex(of: websocket) {
                        self?.webSocketTaskList.remove(at: index)
                    }
                }
            }
        }
    
    func send(loggerItem: DDLoggerSwiftItem) {
        guard let data = "\(loggerItem.mLogItemType.rawValue)#\(loggerItem.mLogDebugContent)#\(loggerItem.mCreateDate.timeIntervalSince1970)#\(loggerItem.getLogContent())".data(using: .utf8) else { return
        }
        
        for task in self.webSocketTaskList {
            task.send(URLSessionWebSocketTask.Message.data(data)) { error in
                if let error = error {
                    print("Failed to send data: \(error)")
                } else {
                    print("Message sent successfully.")
                }
            }
        }
    }
    
    func stop() {
        
    }
}


@available(iOS 13.0, *)
extension DDLoggerSwiftSocketManager: NetServiceDelegate {
    func netServiceDidPublish(_ sender: NetService) {
            print("Bonjour service published successfully")
            print("Service name: \(sender.name)")
            print("Service type: \(sender.type)")
            print("Service port: \(sender.port)")
        
        self.startWebSocketServer()
        }
        
        func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
            print("Failed to publish service: \(errorDict)")
        }
}
