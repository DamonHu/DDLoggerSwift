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

    //插入数据
    func insertLog(log: DDLoggerSwiftItem) {
        let insertRowString = String(format: "insert into hdlog(log, logType, time, debugContent, contentString) values ('%@','%d','%f', '%@', '%@')", log.getFullContentString(), log.mLogItemType.rawValue, Date().timeIntervalSince1970, log.mLogDebugContent, log.getLogContent())
        var insertStatement: OpaquePointer?
        //第一步
        let status = sqlite3_prepare_v2(logDB, insertRowString, -1, &insertStatement, nil)
        if status == SQLITE_OK {
            //第三步
            if sqlite3_step(insertStatement) == SQLITE_DONE {
                //                print("插入数据成功")
                NotificationCenter.default.post(name: .DDLoggerSwiftDBUpdate, object: ["type": "insert", "logType": log.mLogItemType] as [String : Any])
            } else {
                print("DDLoggerSwift_插入数据失败")
            }
        } else {
            print("DDLoggerSwift_插入时打开数据库失败")
        }
        //第四步
        sqlite3_finalize(insertStatement)
    }

    func getAllLog(name: String? = nil, keyword: String? = nil, type: DDLogType? = nil) -> [DDLoggerSwiftItem] {
        let databasePath = self._getDataBasePath(name: name)
        guard FileManager.default.fileExists(atPath: databasePath.path) else {
            //数据库文件不存在
            return []
        }
        let queryDB = self._openDatabase(name: name)
        var queryString = "SELECT * FROM hdlog;"
        if let keyword = keyword, !keyword.isEmpty {
            if let type = type {
                queryString = "SELECT * FROM hdlog WHERE log LIKE '%\(keyword)%' and logType == \(type.rawValue)"
            } else {
                queryString = "SELECT * FROM hdlog WHERE log LIKE '%\(keyword)%'"
            }
        } else if let type = type {
            queryString = "SELECT * FROM hdlog WHERE logType == \(type.rawValue)"
        }
        var queryStatement: OpaquePointer?
        //第一步
        var logList = [DDLoggerSwiftItem]()
        if sqlite3_prepare_v2(queryDB, queryString, -1, &queryStatement, nil) == SQLITE_OK {
            //第二步
            while(sqlite3_step(queryStatement) == SQLITE_ROW) {
                //第三步
                let item = DDLoggerSwiftItem()
                //                item.id = Int(sqlite3_column_int(queryStatement, 0))
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

    func getItemCount(type: DDLogType?) -> Int {
        return self._getItemCount(type: type)
    }

    func deleteLog(timeStamp: Double) {
        self._deleteLog(timeStamp: timeStamp)
    }
}

private extension HDSqliteTools {
    //获取数据库地址
    func _getDataBasePath(name: String? = nil) -> URL {
        let path = self.getDBFolder()
        if let name = name {
            return path.appendingPathComponent(name)
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: Date())
            return path.appendingPathComponent("\(dateString).db")
        }
    }

    //打开数据库
    func _openDatabase(name: String? = nil) -> OpaquePointer? {
        var db: OpaquePointer?
        let dbPath = self._getDataBasePath(name: name)
        if sqlite3_open_v2(dbPath.path, &db, SQLITE_OPEN_READWRITE|SQLITE_OPEN_CREATE|SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK {
            //            print("成功打开数据库\(dbPath.absoluteString)")
            return db
        } else {
            print("DDLoggerSwift_打开数据库失败")
            return nil
        }
    }

    //创建日志表
    func _createTable() {
        let createTableString = "create table if not exists 'hdlog' ('id' integer primary key autoincrement not null,'log' text,'logType' integer,'time' float, 'debugContent' text, 'contentString' text)"
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

    func _getItemCount(type: DDLogType?) -> Int {
        var count = 0
        let databasePath = self._getDataBasePath()
        guard FileManager.default.fileExists(atPath: databasePath.path) else {
            //数据库文件不存在
            return count
        }
        let queryDB = self.logDB
        var queryString = "SELECT COUNT(*) FROM hdlog"
        if let type = type {
            queryString = "SELECT COUNT(*) FROM hdlog WHERE logType == \(type.rawValue)"
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
