//
//  UserAccount.swift
//  AC博客
//
//  Created by AC on 2022/9/10.
//

import UIKit

/// 用户账户模型
class UserAccount: NSObject,NSCoding,NSSecureCoding,@unchecked Sendable {
    
    static var supportsSecureCoding: Bool {
        return true
    }
    
    /// 用于调用access_token，接口获取授权后的access token
    @objc var access_token: String?
    /// 过期时间
    @objc var expires_in: Int = 0
    /// 当前授权用户的UID
    @objc var uid: String?
    /// 用户昵称
    @objc var user: String?
    /// 用户头像地址（大图），180×180像素
    @objc var portrait: String?
    init(dict: [String: Any]) {
        super.init()
        setValuesForKeys(dict)
    }
    
    override func setValue(_ value: Any?, forUndefinedKey key: String) {}
    
    override var description: String {
        let keys = ["access_token", "uid", "user", "portrait"]
        return dictionaryWithValues(forKeys: keys).description
    }
    
    // MARK: - `键值`归档和解档
    /// 归档 - 在把当前对象保存到磁盘前，将对象编码成二进制数据
    ///
    /// - parameter coder: 编码器
    func encode(with coder: NSCoder) {
        coder.encode(access_token, forKey: "access_token")
        coder.encode(uid, forKey: "uid")
        coder.encode(user, forKey: "user")
        coder.encode(portrait, forKey: "portrait")
    }
    
    ///解档 - 从磁盘加载二进制文件，转换成对象时调用
    /// - parameter coder: 解码器
    ///
    /// - returns: 当前对象
    required init?(coder: NSCoder) {
        access_token = coder.decodeObject(forKey: "access_token") as? String
        uid = coder.decodeObject(forKey: "uid") as? String
        user = coder.decodeObject(forKey: "user") as? String
        portrait = coder.decodeObject(forKey: "portrait") as? String
    }
    func saveUserAccount() {
        var path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last!
        path = (path as NSString).appendingPathComponent("account.plist")
        /*
         //deprecated
         NSKeyedArchiver.archiveRootObject(self, toFile: path)
         */
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: true)
            try data.write(to: NSURL(fileURLWithPath: path) as URL)
        } catch {
            showError("出错了")
        }
    }
}
