//
//  UserAccountViewModel.swift
//  AC博客
//
//  Created by AC on 2022/9/10.
//

import Foundation

class UserAccountViewModel {
    var portraitUrl: URL {
        let 中文转换过的url = account!.portrait?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        return URL(string: 中文转换过的url ?? "")!
    }
    static let sharedUserAccount = UserAccountViewModel()
    var account: UserAccount?
    var userLogon: Bool {
        return account?.access_token != nil
    }
    var accessToken: String? {
        return account?.access_token
    }
    private var accountPath: String {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last!
        return (path as NSString).appendingPathComponent("account.plist")
    }
    private init() {
        do {
            account = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [UserAccount.self, NSString.self, NSNumber.self], from: Data(contentsOf: NSURL(fileURLWithPath: accountPath) as URL)) as? UserAccount
        } catch/*(let e)*/ {
            
        }
    }
}
extension UserAccountViewModel {
    func loadAccessToken(code: String, finished: @escaping (_ isSuccessed: Bool) -> ()) {
        NetworkTools.shared.loadAccessToken(code: code) { (Result, Error) -> () in
            if Error != nil {
                finished(false)
                return
            }
            self.account = UserAccount(dict: Result as! [String: Any])
            self.loadUserInfo(account: self.account!, finished: finished)
        }
    }
    func loadUserInfo(account: UserAccount, finished: @escaping (_ isSuccessed: Bool) -> ()) {
        NetworkTools.shared.loadUserInfo { (Result, Error) -> () in
            if Error != nil {
                finished(false)
                return
            }
            guard let dict = Result as? [String: Any] else {
                finished(false)
                return
            }
            account.user = dict["user"] as? String
            account.portrait = (dict["portrait"] as? String)?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            account.uid = dict["uid"] as? String
            account.saveUserAccount()
            finished(true)
        }
    }
}
