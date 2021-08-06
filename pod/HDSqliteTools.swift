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
    var db: OpaquePointer?
    static let shared = HDSqliteTools()

    init() {
        self.db = self._openDatabase()
        self._createTable()
    }
    
    //获取数据库文件夹
    func getDBFolder() -> URL {
        let dbFolder = ZXKitLogger.userID.zx.encryptString(encryType: .md5) ?? "ZXKitLog"
        let path = ZXKitUtil.shared.createFileDirectory(in: .documents, directoryName: dbFolder)
        return path
    }

    //插入数据
    func insertLog(log: ZXKitLoggerItem) {
        let insertRowString = String(format: "insert into hdlog(log,logType,time) values ('%@','%d','%f')", log.getFullContentString(), log.mLogItemType.rawValue, Date().timeIntervalSince1970)
        var insertStatement: OpaquePointer?
        //第一步
        let status = sqlite3_prepare_v2(db, insertRowString, -1, &insertStatement, nil)
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
        if sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) == SQLITE_OK {
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
    }
}
