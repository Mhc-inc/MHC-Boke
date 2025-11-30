//
//  ElseListViewModel.swift
//  AC博客
//
//  Created by AC on 2022/9/11.
//

import UIKit


class UserListViewModel: @unchecked Sendable {
    lazy var list = [UserViewModel]()
    func loadFLFL(specialClass: SpecialClass, _ uid: String? = nil, finished: @escaping @Sendable (_ isSuccessful: Bool) -> ()) {
        let completion: NetworkTools.HMRequestCallBack = { (array: Any?,error: Error?) -> () in
            NSLog(array.debugDescription)
            guard let array = array else {
                finished(false)
                return
            }
            guard let arr = array as? [[String:Any]] else {
                return
            }
            var dataList = [UserViewModel]()
            for n in 0..<arr.count {
                dataList.append(UserViewModel(user: Account(dict: arr[n])))
            }
            self.list = dataList
            finished(true)
        }
        NetworkTools.shared.loadFLFL(finished: completion, specialClass: specialClass)
    }
}
