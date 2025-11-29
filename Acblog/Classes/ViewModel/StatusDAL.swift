//
//  StatusDAL.swift
//  AC博客
//
//  Created by AC on 2022/12/3.
//

import Foundation
private let maxCacheDateTime: TimeInterval = 60
class StatusDAL {
    class func clearDataCache(type: type?) {
        let date = Date(timeIntervalSinceNow: -maxCacheDateTime)
        let df = DateFormatter()
        df.locale = Locale(identifier: "en")
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateStr = df.string(from: date)
        var sql = "DELETE FROM T_Status WHERE createtime < '?'"
        if let t = type {
            sql.append("    AND type = '\(t.rawValue)'")
        }
        SQLiteManager.shared.queue.inDatabase { db in
            try? db.executeUpdate(sql, values: [dateStr])
        }
    }
    class func removeCache(_ statusId: Int,_ type: type) {
        let sql = "DELETE FROM T_Status WHERE statusId = \(statusId) AND type = '\(type.rawValue)'"
        SQLiteManager.shared.queue.inDatabase { db in
            try? db.executeUpdate(sql, values: nil)
        }
    }     
    // 检查随机生成的ID是否唯一
    class func loadStatus(since_id: Int, max_id: Int, type: type, to_uid: Int?, finished: @escaping @Sendable @MainActor (_ array: [[String:Any]]?) -> ()) {
        let array = StatusDAL.checkCacheData(since_id: since_id, max_id: max_id,to_uid: to_uid, type: type)
        if type == .msg {
            Task{@MainActor in
                finished(array!)
            }
            return
        }
        if array!.count > 0{
            Task{@MainActor in
                finished(array!)
            }
            return
        }
        NetworkTools.shared.loadStatus(max_id: max_id, since_id: since_id) { (Result, Error) -> () in
            if Error != nil {
                finished(nil)
                return
            }
            guard let array = Result as? [[String: Any]] else {
                finished(nil)
                return
            }
            StatusDAL.saveCache(array: array, type: type)
            finished(array)
        }
    }
    class func loadSingleStatus(_ id: Int, finished: @escaping @Sendable @MainActor (_ array: [String:Any]?) -> ()) {
        
        NetworkTools.shared.loadOneStatus(id: id) { (Result, Error) -> () in
            if Error != nil {
                finished(nil)
                return
            }
            guard let arr = Result as? [String: Any] else {
                finished(nil)
                return
            }
            var sql = "SELECT * FROM T_Status \n"
            sql += "WHERE statusId = \(id) \n    AND type = '"+type.status.rawValue+"' \n"
            let array = SQLiteManager.shared.execRecordSet(sql: sql)
            if array.count == 1 {
                sql = "UPDATE T_Status \nSET status = ?\nWHERE statusId = \(id)"
                SQLiteManager.shared.queue.inTransaction { (db, rollback) -> Void in
                    do {
                        try db.executeUpdate(sql, values: [try JSONSerialization.data(withJSONObject: arr,options: [])])
                        finished(arr)
                        guard db.changes > 0 else {
                            return
                        }
                    } catch {
                        finished(nil)
                    }
                }
            }
            finished(nil)
        }
        Task{@MainActor in
            finished(nil)
        }
    }
    enum type: String{
        case status = "status"
        case msg = "msg"
    }
    class func checkCacheData(since_id: Int, max_id: Int, to_uid: Int? = nil, type: type) -> [[String:Any]]? {
        guard let userId = UserAccountViewModel.sharedUserAccount.account?.uid else {
            return nil
        }
        var sql = "SELECT statusId, status, userId FROM T_Status \n"
        sql += "WHERE userId = \(userId) \n    AND type = '"+type.rawValue+"' \n"
        let sinceCreateTime = SQLiteManager.shared.execRecordSet(sql: "SELECT create_at FROM T_Status \nWHERE statusId = \(since_id)    AND type = '"+type.rawValue+"';")
        if sinceCreateTime.count != 0 && since_id > 0{
            //博客没被删除
            sql += "    AND create_at > '\(sinceCreateTime[0]["create_at"] as! String)' \n"
        }
        // 上拉刷新
        let maxCreateTime = SQLiteManager.shared.execRecordSet(sql: "SELECT create_at FROM T_Status \nWHERE statusId = \(max_id)    AND type = '"+type.rawValue+"';")
        if maxCreateTime.count != 0 && max_id > 0{
            //博客没被删除
            sql += "    AND create_at < '\(maxCreateTime[0]["create_at"] as! String)' \n"
        }
        if let td = to_uid {
            sql += "    AND (to_uid = '\(td)' OR to_uid = '\(userId)') \n"
        }
        sql += "ORDER BY create_at DESC LIMIT 10;"
        let array = SQLiteManager.shared.execRecordSet(sql: sql)
        var arrayM = [[String:Any]]()
        for dict in array {
            let jsonData = dict["status"] as! Data
            let result = try! JSONSerialization.jsonObject(with: jsonData,options: [])
            arrayM.append(result as! [String:Any])
        }
        return arrayM
    }
    class func saveCache(array data: [[String:Any]], type: type) {
        guard let userId = UserAccountViewModel.sharedUserAccount.account?.uid else {
            return
        }
        let sql = "INSERT OR REPLACE INTO T_Status(statusId, status, userId, create_at, type) VALUES (?, ?, ?, ?, ?);"
        
        // 3. 遍历数组 - 如果不能确认数据插入的消耗时间，可以在实际开发中写测试代码
        SQLiteManager.shared.queue.inTransaction { (db, rollback) -> Void in
            
            for dict in data {
                // 微博id
                let statusId = dict["id"] as! Int
                let create_at = dict["create_at"] as! String
                let type = type.rawValue
                let json = try! JSONSerialization.data(withJSONObject: dict,options: [])
                // 插入数据
                do {
                    try db.executeUpdate(sql, values: [statusId, json, userId, create_at, type])
                    guard db.changes > 0 else {
                        return
                    }
                } catch {
                    
                }
            }
        }
    }
    class func saveChatSingleCache(array dict: [String:Any]) {
        guard let userId = UserAccountViewModel.sharedUserAccount.account?.uid else {
            return
        }
        let sql = "INSERT INTO T_Status(statusId, status, userId, to_uid, create_at, type) VALUES (?, ?, ?, ?, ?, ?);"
        
        // 3. 遍历数组 - 如果不能确认数据插入的消耗时间，可以在实际开发中写测试代码
        SQLiteManager.shared.queue.inTransaction { (db, rollback) -> Void in
            
            let statusId = dict["id"] as! Int
            let to_uid = dict["to_uid"] as! String
            let create_at = (dict["create_at"] as! String)
            let type = type.msg.rawValue
            let json = try! JSONSerialization.data(withJSONObject: dict,options: [])
            // 插入数据
            do {
                try db.executeUpdate(sql, values: [statusId, json, userId, to_uid, create_at, type])
                guard db.changes > 0 else {
                    return
                }
            } catch {
            }
        }
    }
}
