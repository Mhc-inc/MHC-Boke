//
//  SQLiteManager.swift
//  fmdb演练
//
//  Created by AC on 2022/12/2.

import Foundation
import FMDB
private let dbName = "readme.db"
class SQLiteManager: @unchecked Sendable {
    static let shared = SQLiteManager()
    let queue: FMDatabaseQueue
    init() {
        var path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last!
        path = (path as NSString).appendingPathComponent(dbName)
        queue = FMDatabaseQueue(path: path)!
        print(path)
        createTable()
    }
    private func createTable() {
        let path = Bundle.main.path(forResource: "db.sql", ofType: nil)!
        let sql = try! String(contentsOfFile: path,encoding: .utf8)
        queue.inDatabase { db in
            if db.executeStatements(sql) == true {
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
}
