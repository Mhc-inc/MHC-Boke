//
//  StatusListViewModel.swift
//  MHC微博
//
//  Created by Monkey hammer on 2022/9/11.
//

import UIKit

class StatusListViewModel {
    lazy var statusList = [StatusViewModel]()
    var pulldownCount: Int?
    func loadStatus(isPullup: Bool,finished: @escaping (_ isSuccessed: Bool) -> ()) {
        let since_id = isPullup ? 0 : (statusList.first?.status.id ?? 0)
        let max_id = isPullup ? (statusList.last?.status.id ?? 0) : 0
        StatusDAL.loadStatus(since_id: since_id, max_id: max_id) { (array) -> () in
            guard let array = array else {
                finished(false)
                return
            }
            var dataList = [StatusViewModel]()
            for dict in array {
                dataList.append(StatusViewModel(status: Status(dict: dict)))
            }
            self.pulldownCount = (since_id > 0) ? dataList.count : nil
            if max_id > 0 {
                self.statusList += dataList
            } else {
                self.statusList = dataList + self.statusList
            }
            self.cacheSingleImage(dataList: dataList, finished: finished)
        }
    }
    private func cacheSingleImage(dataList: [StatusViewModel],finished: @escaping (_ isSuccessed: Bool) -> ()) {
        let group = DispatchGroup()
        //var dataLength = 0
        for vm in dataList {
            if vm.thumbnailUrls?.count != 1 {
                continue
            }
            let url = vm.thumbnailUrls![0]
                group.enter()
            SDWebImageManager.shared.loadImage(with: url, options:[SDWebImageOptions.retryFailed],progress: nil) {
                (image, data, error, type, bool, url) in
                group.leave()
            }
        }
       group.notify(queue: DispatchQueue.main) {
            finished(true)
        }
    }
}
