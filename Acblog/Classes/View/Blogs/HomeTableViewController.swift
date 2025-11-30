//
//  HomeTableViewController.swift
//  AC博客
//
//  Created by AC on 2022/9/10.
//

import UIKit
import SwiftUI

let StatusCellNormalId = "StatusCellNormalId"
//let StatusCellNormalId2 = "StatusCellNormalId2"
class CustomRefreshView: UIView {
    lazy var pullupView: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.style = .large
        return indicator
    }()
    var refreshAction: ((UIActivityIndicatorView)->())?
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(pullupView)
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture(_:)))
        addGestureRecognizer(gesture)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            // 开始刷新
            pullupView.startAnimating()
            pullupView.snp.makeConstraints { make in
                make.center.equalTo(self.snp.center)
            }
            refreshAction?(pullupView)
        default:
            break
        }
    }
}
class HomeTableViewController: BlogTableViewController {
    lazy var refreshView = CustomRefreshView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 30))
    @objc func refresh(pullup: UIActivityIndicatorView) {
        if pullup.isAnimating {
            // 开始动画
            loadData()
        }
    }
    override func refreshSingleStatus(_ id: Int) {
        self.statusListViewModel.loadSingleStatus(id) { isSuccessful in
            if(isSuccessful) {
                self.tableView.reloadData()
            }
        }
    }
    override func deleteStatusInList(_ id: Int, _ row: Int) {
        NotificationCenter.default.post(name: Notification.Name("BKReloadHomePageDataNotification"), object: id)
    }
    private lazy var composedButton: UIBarButtonItem = {
        if #available(iOS 16.0, *) {
            return UIBarButtonItem(title: NSLocalizedString("写", comment: ""), image: UIImage(systemName: "pencil"), target: self, action: #selector(self.clickComposedButton))
        }
        let but = UIBarButtonItem(image: UIImage(systemName: "pencil"), style: .plain, target: self, action: #selector(self.clickComposedButton))
        but.title = NSLocalizedString("写", comment: "")
        return but
    }()
    
    private func setupComposedButton() {
        composedButton.tintColor = .red
        navigationItem.rightBarButtonItem = composedButton
    }
    @objc private func clickComposedButton() {
        var vc: UIViewController
        if UserAccountViewModel.sharedUserAccount.userLogon {
            vc = ComposeViewController(nil,nil)
        } else {
            vc = OAuthViewController(.登录)
        }
        
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    lazy var liveView = UserCollectionCellView{ viewModel in
        guard let url = (rootHost+"/hls/\(viewModel.user.uid).m3u8").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            showError("似乎出了点问题，请刷新重试")
            return
        }
        guard let urlEncoded = URL(string:url) else {
            showError("似乎出了点问题，请刷新重试")
            return
        }
        self.present(ACWebViewController(url: urlEncoded),animated: true)
    }
    override func prepareTableView() {
        super.prepareTableView()
        refreshControl = ACRefreshControl()
        refreshControl?.addTarget(self, action: #selector(self.loadData), for: .valueChanged)
        refreshView.refreshAction = { pullup in
            // 执行刷新操作
            self.refresh(pullup: pullup)
        }
        tableView.tableFooterView = refreshView
        tableView.tableHeaderView = liveView.userListViewModel.list.isEmpty ? nil : liveView
    }
    @objc override func loadData() {
        if(!self.refreshView.pullupView.isAnimating) {
            self.refreshControl?.beginRefreshing()
        }
        //StatusDAL.clearDataCache()//删除缓存
        statusListViewModel.loadStatus(isPullup: self.refreshView.pullupView.isAnimating) { (isSuccessful) in
            self.refreshView.pullupView.isAnimating ? self.refreshView.pullupView.stopAnimating() : self.refreshControl?.endRefreshing()
            if !isSuccessful {
                showError("加载数据错误，请稍后再试")
                return
            }
            self.showPulldownTip()
            self.tableView.reloadData()
        }
        refreshControl?.beginRefreshing()
        liveView.userListViewModel.loadFLFL(specialClass: .live) { (isSuccessful) in
            Task { @MainActor in
                self.refreshControl?.endRefreshing()
                if !isSuccessful {
                    showError("加载数据错误，请稍后再试")
                    return
                }
                self.liveView.collectionView.reloadData()
            }
        }
        
        self.tableView.tableHeaderView = liveView.userListViewModel.list.isEmpty ? nil : self.liveView
    }
    private lazy var pulldownTipLabel: UILabel = {
        let label = UILabel(title: "", fontSize: 18,color: .white)
        label.backgroundColor = .red
        self.navigationController?.navigationBar.insertSubview(label, at: 0)
        return label
    }()
    private func showPulldownTip() {
        guard let count = statusListViewModel.pulldownCount else {
            return
        }
        pulldownTipLabel.text = (count == 0) ? NSLocalizedString("没有博客", comment: "") : String.localizedStringWithFormat(NSLocalizedString("刷新到%@条博客", comment: ""),"\(count)")
        let height: CGFloat = 44
        let rect = CGRect(x: 0, y: 0, width: view.bounds.width, height: height)
        pulldownTipLabel.frame = CGRectOffset(rect, 0, -2 * height)
        UIView.animate(withDuration: 1.0,animations: {
            self.pulldownTipLabel.frame = CGRectOffset(rect, 0, height)
        }) { _ in
            UIView.animate(withDuration: 1.0) {
                self.pulldownTipLabel.frame = CGRectOffset(rect, 0, -2 * height)
            }
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setupComposedButton()
        NotificationCenter.default.addObserver(forName: Notification.Name("BKReloadHomePageDataNotification"), object: nil, queue: nil) {[weak self] n in
            let object = n.object as? Int
            Task { @MainActor in
                if let id = object {
                    StatusDAL.removeCache(id, .status)
                    if let i = self?.statusListViewModel.statusList.firstIndex(where: { vm in
                        vm.status.id == id
                    }) {
                        self?.statusListViewModel.statusList.remove(at: i)
                        self?.tableView.reloadData()
                    }
                }
            }
        }
    }
    private lazy var photoBrowserAnimator: PhotoBrowserAnimator = PhotoBrowserAnimator()
}
extension HomeTableViewController {
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let vm = statusListViewModel.statusList[indexPath.row]
        let cell = super.tableView(tableView, cellForRowAt: indexPath) as! StatusCell
        cell.bottomView.commentButton.tag = indexPath.row
        cell.bottomView.commentButton.addTarget(self, action: #selector(self.compose(_:)), for: .touchUpInside)
        cell.bottomView.commentButton.setTitle("\(vm.status.comment_count)", for: .normal)
        return cell
    }
    @objc func compose(_ sender: UIButton) {
        guard (statusListViewModel.statusList[sender.tag].status.id > 0) else {
            showError("出错了")
            return
        }
        let nav = ComposeViewController(nil,statusListViewModel.statusList[sender.tag].status.id)
        self.present(UINavigationController(rootViewController: nav), animated: true)
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = CommentTableViewController(statusListViewModel.statusList[indexPath.row])
        let nav = UINavigationController(rootViewController:vc)
        nav.modalPresentationStyle = .custom
        self.present(nav, animated: false)
    }
}
