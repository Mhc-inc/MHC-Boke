//
//  MessageMainTableViewController.swift
//  MHC微博
//
//  Created by Monkey hammer on 2022/9/6.
//

import UIKit

//var live_to_user: String?
let LiveNormalCellMargin = 1.5
var liveListViewModel = LiveListViewModel()
class LiveTableView: UICollectionView{
    /*
    private lazy var pullupView: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .whiteLarge)
        indicator.color = .white
        return indicator
    }()
     */
    @objc func loadData() {
        refreshControl?.beginRefreshing()
        liveListViewModel.loadLive { (isSuccessed) in
            self.refreshControl?.endRefreshing()
            if !isSuccessed {
                SVProgressHUD.showInfo(withStatus: "加载数据错误，请稍后再试")
                return
            }
            self.reloadData()
        }
        /*
        liveListViewModel.liveList = [UserViewModel(user: Account(dict: ["user":"Mhc-inc","portrait":"https://mhc.lmyz6.cn/resource/465651082032/portrait/KdsFei1FClof.png","uid":465651082032])),UserViewModel(user: Account(dict: ["user":"Mhc-inc","portrait":"https://mhc.lmyz6.cn/resource/465651082032/portrait/KdsFei1FClof.png","uid":465651082032])),UserViewModel(user: Account(dict: ["user":"Mhc-inc","portrait":"https://mhc.lmyz6.cn/resource/465651082032/portrait/KdsFei1FClof.png","uid":465651082032])),UserViewModel(user: Account(dict: ["user":"Mhc-inc","portrait":"https://mhc.lmyz6.cn/resource/465651082032/portrait/KdsFei1FClof.png","uid":465651082032])),UserViewModel(user: Account(dict: ["user":"Mhc-inc","portrait":"https://mhc.lmyz6.cn/resource/465651082032/portrait/KdsFei1FClof.png","uid":465651082032])),UserViewModel(user: Account(dict: ["user":"Mhc-inc","portrait":"https://mhc.lmyz6.cn/resource/465651082032/portrait/KdsFei1FClof.png","uid":465651082032])),UserViewModel(user: Account(dict: ["user":"Mhc-inc","portrait":"https://mhc.lmyz6.cn/resource/465651082032/portrait/KdsFei1FClof.png","uid":465651082032]))]
         */
    }
    init() {
        let flt = UICollectionViewFlowLayout()
        flt.minimumLineSpacing = 0
        flt.minimumInteritemSpacing = 0
        flt.scrollDirection = .horizontal
        super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 80), collectionViewLayout: flt)
        bounces = false
        isPagingEnabled = true
        showsHorizontalScrollIndicator = false
        register(UserCollectionCell.self, forCellWithReuseIdentifier: LiveCellNormalId)
        if UserAccountViewModel.sharedUserAccount.userLogon {
            self.loadData()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

