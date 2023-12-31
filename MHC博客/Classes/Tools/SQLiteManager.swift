//
//  SQLiteManager.swift
//  fmdb演练
//
//  Created by mhc team on 2022/12/2.

import Foundation
private let dbName = "readme.db"
private let chatName = "chat.db"
class SQLiteManager {
    static let shared = SQLiteManager()
    let queue: FMDatabaseQueue
    let chatQueue: FMDatabaseQueue
    init() {
        var path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last!
        path = (path as NSString).appendingPathComponent(dbName)
        queue = FMDatabaseQueue(path: path)!
        path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last!
        path = (path as NSString).appendingPathComponent(chatName)
        chatQueue = FMDatabaseQueue(path: path)!
        createTable()
    }
    private func createTable() {
        let path = Bundle.main.path(forResource: "db.sql", ofType: nil)!
        let sql = try! String(contentsOfFile: path)
        queue.inDatabase { db in
            if db.executeStatements(sql) == true {
            } else {
            }
        }
        let chatPath = Bundle.main.path(forResource: "chat.sql", ofType: nil)!
        let chatSql = try! String(contentsOfFile: chatPath)
        chatQueue.inDatabase { db in
            if db.executeStatements(chatSql) == true {
            } else {
            }
        }
    }
    func execRecordSet(sql: String) -> [[String:Any]] {
        var result = [[String:Any]]()
        SQLiteManager.shared.queue.inDatabase { db in
            guard let rs = try? db.executeQuery(sql,values: nil) else {
                return
            }
            while rs.next() {
                let colCount = rs.columnCount
                var dict = [String:Any]()
                for col in 0..<colCount {
                    let name = rs.columnName(for: col)
                    let obj = rs.object(forColumnIndex: col)
                    dict[name!] = obj
                }
                result.append(dict)
            }
        }
        return result
    }
    func chatExecRecordSet(sql: String) -> [[String:Any]] {
        var result = [[String:Any]]()
        SQLiteManager.shared.chatQueue.inDatabase { db in
            guard let rs = try? db.executeQuery(sql,values: nil) else {
                return
            }
            while rs.next() {
                let colCount = rs.columnCount
                var dict = [String:Any]()
                for col in 0..<colCount {
                    let name = rs.columnName(for: col)
                    let obj = rs.object(forColumnIndex: col)
                    dict[name!] = obj
                }
                result.append(dict)
            }
        }
        return result
    }
}
