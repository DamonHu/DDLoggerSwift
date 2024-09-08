//
//  HDSqliteTools.swift
//  DDLoggerSwift
//
//  Created by Damon on 2021/2/18.
//  Copyright © 2021 Damon. All rights reserved.
//

#if canImport(WCDBSwift)
import WCDBSwift
#else
import SQLite3
#endif
import DDUtils

class HDSqliteTools {
    static let shared = HDSqliteTools()
    private var logDB: OpaquePointer?
    private(set) var currentLogDBFilePath: String?
    init() {
        //开始新的数据
        self.logDB = self._openDatabase()
        self._createTable()
    }
    
    //获取数据库文件夹
    func getDBFolder() -> URL {
        let dbFolder = DDLoggerSwift.userID.dd.hashString(hashType: .md5) ?? "DDLoggerSwift"
        //创建文件夹
        let manager = FileManager.default
        let superDirectory = DDLoggerSwift.DBParentFolder
        
        let newFolder = superDirectory.appendingPathComponent(dbFolder, isDirectory: true)
        
        var isDirectory: ObjCBool = false
        let isDirExist = manager.fileExists(atPath: newFolder.path, isDirectory: &isDirectory)
        if !isDirectory.boolValue || !isDirExist {
            do {
                try manager.createDirectory(at: newFolder, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("创建目录失败\(error)")
                return newFolder
            }
        }
        return newFolder
    }
    
    //批量插入数据
    func insert(logs: [DDLoggerSwiftItem]) {
        if (logs.isEmpty) {
            return
        }
        if (logs.count == 1) {
            self._insert(log: logs.first!)
            return
        }
        //批量插入
        let insertRowString = "INSERT INTO hdlog(log, logType, time, debugContent, contentString) VALUES (?, ?, ?, ?, ?)"
        var insertStatement: OpaquePointer?
        // 开启事务
        if sqlite3_exec(logDB, "BEGIN TRANSACTION", nil, nil, nil) == SQLITE_OK {
            for log in logs {
                if sqlite3_prepare_v2(logDB, insertRowString, -1, &insertStatement, nil) == SQLITE_OK {
                    // 绑定每个字段的值
                    sqlite3_bind_text(insertStatement, 1, log.getFullContentString(), -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                    sqlite3_bind_int(insertStatement, 2, Int32(log.mLogItemType.rawValue))
                    sqlite3_bind_double(insertStatement, 3, Date().timeIntervalSince1970)
                    sqlite3_bind_text(insertStatement, 4, log.mLogDebugContent, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                    sqlite3_bind_text(insertStatement, 5, log.getLogContent(), -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                    if sqlite3_step(insertStatement) != SQLITE_DONE {
                        print("Insert failed: \(String(cString: sqlite3_errmsg(logDB)))")
                    }
                    // 重置语句以便于下一次使用
                    sqlite3_reset(insertStatement)
                } else {
                    print("Prepare failed: \(String(cString: sqlite3_errmsg(logDB)))")
                }
            }
            
            // 提交事务
            if sqlite3_exec(logDB, "COMMIT", nil, nil, nil) == SQLITE_OK {
                print("Transaction committed successfully")
            } else {
                print("Commit failed: \(String(cString: sqlite3_errmsg(logDB)))")
                // 如果提交失败，可以选择回滚事务
                sqlite3_exec(logDB, "ROLLBACK", nil, nil, nil)
            }
            sqlite3_finalize(insertStatement)
        } else {
            print("Begin transaction failed: \(String(cString: sqlite3_errmsg(logDB)))")
        }
    }
    
    /// 获取数据库日志
    /// - Parameters:
    ///   - name: 数据库名称，格式 2022-01-01，默认为当天日志
    ///   - keyword: 指定关键字
    ///   - type: 过滤消息类型
    ///   - pagination: 分页数据，page为页码，size为每页数量
    /// - Returns: 获取的日志
    func getLogs(name: String? = nil, keyword: String? = nil, type: DDLogType? = nil, pagination: (page: Int, size:Int)? = nil) -> [DDLoggerSwiftItem] {
        let databasePath = self._getDataBasePath(name: name)
        guard FileManager.default.fileExists(atPath: databasePath.path) else {
            //数据库文件不存在
            return []
        }
        let queryDB = self._openDatabase(name: name)
        var queryString = "SELECT * FROM hdlog"
        var whereClauses: [String] = []
        if let keyword = keyword, !keyword.isEmpty {
            whereClauses.append("log LIKE '%\(keyword)%'")
        }
        if let type = type {
            whereClauses.append("logType == \(type.rawValue)")
        }
        // 如果有条件，拼接 WHERE 子句
        if !whereClauses.isEmpty {
            queryString += " WHERE " + whereClauses.joined(separator: " AND ")
        }
        if let pagination = pagination {
            queryString = queryString + " LIMIT \(pagination.size) OFFSET \((pagination.page - 1) * pagination.size)"
        }
        var queryStatement: OpaquePointer?
        //第一步
        var logList = [DDLoggerSwiftItem]()
        if sqlite3_prepare_v2(queryDB, queryString, -1, &queryStatement, nil) == SQLITE_OK {
            //第二步
            while(sqlite3_step(queryStatement) == SQLITE_ROW) {
                //第三步
                let item = DDLoggerSwiftItem()
                item.databaseID = Int(sqlite3_column_int(queryStatement, 0))
                item.mLogItemType = DDLogType.init(rawValue: Int(sqlite3_column_int(queryStatement, 2)))
                item.mLogDebugContent = String(cString: sqlite3_column_text(queryStatement, 4))
                //更新内容
                item.mLogContent = String(cString: sqlite3_column_text(queryStatement, 5))
                //时间
                let time = sqlite3_column_double(queryStatement, 3)
                item.mCreateDate = Date(timeIntervalSince1970: time)
                logList.append(item)
            }
        }
        //第四步
        sqlite3_finalize(queryStatement)
        return logList
    }
    
    func getItemCount(keyword: String? = nil, type: DDLogType? = nil) -> Int {
        return self._getItemCount(keyword: keyword, type: type)
    }
    
    func deleteLog(timeStamp: Double) {
        self._deleteLog(timeStamp: timeStamp)
    }
}

private extension HDSqliteTools {
    //获取数据库地址
    //name格式 2022-01-01
    func _getDataBasePath(name: String? = nil) -> URL {
        let path = self.getDBFolder()
        if let name = name {
            return path.appendingPathComponent(name)
        } else {
            let dateString = DDLoggerSwift.dateFormatter.string(from: Date())
            return path.appendingPathComponent("\(dateString).db")
        }
    }
    
    //打开数据库
    func _openDatabase(name: String? = nil) -> OpaquePointer? {
        var db: OpaquePointer?
        let dbPath = self._getDataBasePath(name: name)
        if sqlite3_open_v2(dbPath.path, &db, SQLITE_OPEN_READWRITE|SQLITE_OPEN_CREATE|SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK {
            //            print("成功打开数据库\(dbPath.absoluteString)")
            self.currentLogDBFilePath = dbPath.path
            return db
        } else {
            self.currentLogDBFilePath = nil
            print("DDLoggerSwift_打开数据库失败")
            return nil
        }
    }
    
    //创建日志表
    func _createTable() {
        let createTableString = "create table if not exists 'hdlog' ('id' integer primary key autoincrement not null,'log' text,'logType' integer,'time' double, 'debugContent' text, 'contentString' text)"
        var createTableStatement: OpaquePointer?
        if sqlite3_prepare_v2(logDB, createTableString, -1, &createTableStatement, nil) == SQLITE_OK {
            // 第二步
            if sqlite3_step(createTableStatement) == SQLITE_DONE {
                //                print("成功创建表")
            } else {
                print("DDLoggerSwift_未成功创建表")
            }
        } else {
            
        }
        //第三步
        sqlite3_finalize(createTableStatement)
    }
    
    func _getItemCount(keyword: String? = nil, type: DDLogType? = nil) -> Int {
        var count = 0
        let databasePath = self._getDataBasePath()
        guard FileManager.default.fileExists(atPath: databasePath.path) else {
            //数据库文件不存在
            return count
        }
        let queryDB = self.logDB
        var queryString = "SELECT COUNT(*) FROM hdlog"
        var whereClauses: [String] = []
        if let keyword = keyword, !keyword.isEmpty {
            whereClauses.append("log LIKE '%\(keyword)%'")
        }
        if let type = type {
            whereClauses.append("logType == \(type.rawValue)")
        }
        // 如果有条件，拼接 WHERE 子句
        if !whereClauses.isEmpty {
            queryString += " WHERE " + whereClauses.joined(separator: " AND ")
        }
        var queryStatement: OpaquePointer?
        //第一步
        if sqlite3_prepare_v2(queryDB, queryString, Int32(strlen(queryString)), &queryStatement, nil) == SQLITE_OK {
            //第二步
            while(sqlite3_step(queryStatement) == SQLITE_ROW) {
                //第三步
                //虚拟表中未存储id
                count = Int(sqlite3_column_int(queryStatement, 0))
            }
        }
        //第四步
        sqlite3_finalize(queryStatement)
        return count
    }
    
    //插入数据
    func _insert(log: DDLoggerSwiftItem) {
        let insertRowString = "INSERT INTO hdlog(log, logType, time, debugContent, contentString) VALUES (?, ?, ?, ?, ?)"
        var insertStatement: OpaquePointer?
        //第一步
        let status = sqlite3_prepare_v2(logDB, insertRowString, -1, &insertStatement, nil)
        if status == SQLITE_OK {
            //绑定
            sqlite3_bind_text(insertStatement, 1, log.getFullContentString(), -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
            sqlite3_bind_int(insertStatement, 2, Int32(log.mLogItemType.rawValue))
            sqlite3_bind_double(insertStatement, 3, Date().timeIntervalSince1970)
            sqlite3_bind_text(insertStatement, 4, log.mLogDebugContent, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
            sqlite3_bind_text(insertStatement, 5, log.getLogContent(), -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
            //第三步
            if sqlite3_step(insertStatement) == SQLITE_DONE {
                //                print("插入数据成功")
                NotificationCenter.default.post(name: .DDLoggerSwiftDBUpdate, object: ["type": "insert", "logType": log.mLogItemType] as [String : Any])
            } else {
                print("Could not insert data: \(String(cString: sqlite3_errmsg(logDB)))")
            }
        } else {
            print("Prepare failed: \(String(cString: sqlite3_errmsg(logDB)))")
        }
        //第四步
        sqlite3_finalize(insertStatement)
    }
    
    func _deleteLog(timeStamp: Double) {
        let insertRowString = "DELETE FROM hdlog WHERE time < \(timeStamp) "
        var insertStatement: OpaquePointer?
        //第一步
        let status = sqlite3_prepare_v2(self.logDB, insertRowString, -1, &insertStatement, nil)
        if status == SQLITE_OK {
            //第三步
            if sqlite3_step(insertStatement) == SQLITE_DONE {
                //                print("删除过期数据成功")
                NotificationCenter.default.post(name: .DDLoggerSwiftDBUpdate, object: ["type": "delete"])
            } else {
                print("DDLoggerSwift_删除过期数据失败")
            }
        } else {
            print("DDLoggerSwift_删除时打开虚拟数据库失败")
        }
        //第四步
        sqlite3_finalize(insertStatement)
    }
}
