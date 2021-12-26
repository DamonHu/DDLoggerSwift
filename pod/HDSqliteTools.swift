//
//  HDSqliteTools.swift
//  ZXKitLogger
//
//  Created by Damon on 2021/2/18.
//  Copyright © 2021 Damon. All rights reserved.
//

#if canImport(WCDBSwift)
import WCDBSwift
#elseif canImport(SQLite3)
import SQLite3
#else
//
#endif
import ZXKitUtil

class HDSqliteTools {
    static let shared = HDSqliteTools()

    private var logDB: OpaquePointer?
    private var indexDB: OpaquePointer?
    
    init() {
        //开始新的数据
        self.logDB = self._openDatabase()
        self.indexDB = self._openVirtualDatabase()
        self._createTable()
    }
    
    //获取数据库文件夹
    func getDBFolder() -> URL {
        let dbFolder = ZXKitLogger.userID.zx.hashString(hashType: .md5) ?? "ZXKitLog"
        let path = ZXKitUtil.shared.createFileDirectory(in: .documents, directoryName: dbFolder)
        return path
    }

    //插入数据
    func insertLog(log: ZXKitLoggerItem) {
        let insertRowString = String(format: "insert into hdlog(log,logType,time) values ('%@','%d','%f')", log.getFullContentString(), log.mLogItemType.rawValue, Date().timeIntervalSince1970)
        var insertStatement: OpaquePointer?
        //第一步
        let status = sqlite3_prepare_v2(logDB, insertRowString, -1, &insertStatement, nil)
        if status == SQLITE_OK {
            //第三步
            if sqlite3_step(insertStatement) == SQLITE_DONE {
//                print("插入数据成功")
            } else {
                print("插入数据失败")
            }
        } else {
            print("插入时打开数据库失败")
        }
        //第四步
        sqlite3_finalize(insertStatement)
        //插入数据
        self._insertVirtualLog(log: log)
    }

    func getAllLog(name: String? = nil) -> [String] {
        let databasePath = self._getDataBasePath(name: name)
        guard FileManager.default.fileExists(atPath: databasePath.path) else {
            //数据库文件不存在
            return [String]()
        }
        let queryDB = self._openDatabase(name: name)
        let queryString = "SELECT * FROM hdlog;"
        var queryStatement: OpaquePointer?
        //第一步
        var logList = [String]()
        if sqlite3_prepare_v2(queryDB, queryString, -1, &queryStatement, nil) == SQLITE_OK {
            //第二步
            while(sqlite3_step(queryStatement) == SQLITE_ROW) {
                //第三步
//                let id = sqlite3_column_int(queryStatement, 0)
                let log = sqlite3_column_text(queryStatement, 1)
//                let logType = sqlite3_column_int(queryStatement, 2)
//                let time = sqlite3_column_double(queryStatement, 3)
                if let log = log {
                    logList.append("\(String(cString: log))")
                }
            }
        }
        //第四步
        sqlite3_finalize(queryStatement)
        return logList
    }
    
    func searchLog(keyword: String) -> [String] {
        return self._searchLog(keyword: keyword)
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
            print("打开数据库失败")
            return nil
        }
    }

    //创建日志表
    func _createTable() {
        let createTableString = "create table if not exists 'hdlog' ('id' integer primary key autoincrement not null,'log' text,'logType' integer,'time' float)"
        var createTableStatement: OpaquePointer?
        if sqlite3_prepare_v2(logDB, createTableString, -1, &createTableStatement, nil) == SQLITE_OK {
            // 第二步
            if sqlite3_step(createTableStatement) == SQLITE_DONE {
//                print("成功创建表")
            } else {
                print("未成功创建表")
            }
        } else {

        }
        //第三步
        sqlite3_finalize(createTableStatement)
        //创建虚拟表
        self._createVirtualTable()
    }
}

//MARK: - 全文搜索相关
private extension HDSqliteTools {
    //获取数据库地址
    func _getDataVirtualBasePath() -> URL {
        let path = self.getDBFolder()
        return path.appendingPathComponent("totalIndex.db")
    }

    //打开数据库
    func _openVirtualDatabase() -> OpaquePointer? {
        var db: OpaquePointer?
        let dbPath = self._getDataVirtualBasePath()
        if sqlite3_open_v2(dbPath.path, &db, SQLITE_OPEN_READWRITE|SQLITE_OPEN_CREATE|SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK {
//            print("成功打开数据库\(dbPath.absoluteString)")
            return db
        } else {
            print("打开数据库失败")
            return nil
        }
    }
    //创建索引虚拟表
    func _createVirtualTable() {
        let createTableString = "CREATE VIRTUAL TABLE IF NOT EXISTS logindex USING fts4(log, logType, time, tokenize=unicode61);"
        var createTableStatement: OpaquePointer?
        if sqlite3_prepare_v2(self.indexDB, createTableString, -1, &createTableStatement, nil) == SQLITE_OK {
            // 第二步
            if sqlite3_step(createTableStatement) == SQLITE_DONE {
//                print("成功创建虚拟表")
            } else {
                print("未成功创建虚拟表")
            }
        } else {
            print("创建虚拟表sssssss", sqlite3_prepare_v2(self.indexDB, createTableString, -1, &createTableStatement, nil), SQLITE_OK, SQLITE_BUSY, SQLITE_ERROR)
        }
        //第三步
        sqlite3_finalize(createTableStatement)
    }
    
    //插入数据
    func _insertVirtualLog(log: ZXKitLoggerItem) {
        let insertRowString = String(format: "INSERT OR REPLACE INTO logindex(log,logType,time) VALUES ('%@','%d','%f')", log.getFullContentString(), log.mLogItemType.rawValue, Date().timeIntervalSince1970)
        var insertStatement: OpaquePointer?
        //第一步
        let status = sqlite3_prepare_v2(self.indexDB, insertRowString, -1, &insertStatement, nil)
        if status == SQLITE_OK {
            //第三步
            if sqlite3_step(insertStatement) == SQLITE_DONE {
//                print("虚拟库插入数据成功")
            } else {
                print("插入数据失败")
            }
        } else {
            print("插入时打开虚拟数据库失败")
        }
        //第四步
        sqlite3_finalize(insertStatement)
    }
    
    func _searchLog(keyword: String) -> [String] {
        let databasePath = self._getDataBasePath()
        guard FileManager.default.fileExists(atPath: databasePath.path) else {
            //数据库文件不存在
            return [String]()
        }
        let queryDB = self.indexDB
        //TODO: 虚拟表全文查询需要分词，所以使用LIKE
//        var queryString = "SELECT * FROM logindex WHERE log MATCH '\(keyword)*'"
        var queryString = "SELECT * FROM logindex WHERE log LIKE '%\(keyword)%'"
        if keyword.isEmpty {
            queryString = "SELECT * FROM logindex"
        }
        var queryStatement: OpaquePointer?
        //第一步
        var logList = [String]()
        if sqlite3_prepare_v2(queryDB, queryString, Int32(strlen(queryString)), &queryStatement, nil) == SQLITE_OK {
            //第二步
            while(sqlite3_step(queryStatement) == SQLITE_ROW) {
                //第三步
                //虚拟表中未存储id
                let log = sqlite3_column_text(queryStatement, 0)
//                let logType = sqlite3_column_int(queryStatement, 1)
//                let time = sqlite3_column_double(queryStatement, 2)
                if let log = log {
                    logList.append("\(String(cString: log))")
                }
            }
        }
        //第四步
        sqlite3_finalize(queryStatement)
        return logList
    }
    
    func _deleteLog(timeStamp: Double) {
        print(timeStamp)
        let insertRowString = "DELETE FROM logindex WHERE time < \(timeStamp) "
        var insertStatement: OpaquePointer?
        //第一步
        let status = sqlite3_prepare_v2(self.indexDB, insertRowString, -1, &insertStatement, nil)
        if status == SQLITE_OK {
            //第三步
            if sqlite3_step(insertStatement) == SQLITE_DONE {
//                print("删除过期数据成功")
            } else {
                print("删除过期数据失败")
            }
        } else {
            print("删除时打开虚拟数据库失败")
        }
        //第四步
        sqlite3_finalize(insertStatement)
    }
}
