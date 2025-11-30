//
//  BlogViewController.swift
//  Acblog
//
//  Created by acincor on 2025/8/25.
//

import UIKit
class BlogTableViewController: VisitorTableViewController {
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    init(_ vm: StatusViewModel? = nil) {
        self.vm = vm
        super.init(nibName: nil, bundle: nil)
    }
    func refreshSingleStatus(_ id: Int) {
        loadData()
    }
    func deleteStatusInList(_ id: Int, _ row: Int) {
        loadData()
    }
    lazy var statusListViewModel = StatusListViewModel()
    var vm: StatusViewModel?
    func prepareTableView() {
        tableView.separatorStyle = .none
        tableView.register(StatusNormalCell.self, forCellReuseIdentifier: StatusCellNormalId)
        tableView.estimatedRowHeight = 400
        tableView.rowHeight = 400
    }
    @objc func like(_ sender: UIButton) {
        let svscmd=(sender.vm?.status.comment_id == 0 ? nil : sender.vm?.status.comment_id)
        let vscmd=(vm?.status.comment_id == 0 ? nil : vm?.status.comment_id)
        let comment_id = vm != nil ? (vm?.status.comment_id == 0 ? svscmd : vscmd) : nil
        let quote_id = comment_id != vm?.status.comment_id ? nil : svscmd
        NetworkTools.shared.like(statusListViewModel.statusList[sender.tag].status.id,comment_id: quote_id == 0 ? nil : quote_id,comment_id == 0 ? nil : comment_id) { Result, Error in
            if Error == nil {
                Task { @MainActor in
                    self.refreshSingleStatus(self.statusListViewModel.statusList[sender.tag].status.id)
                }
                if (Result as! [String:Any])["code"] as! String == "add" {
                    showAlert(.timelineIconLike, "你的点赞TA收到了")
                    return
                }
                showAlert(.timelineIconUnlike, "你的取消TA收到了")
                return
            }
            showError("出错了")
            return
        }
    }
    @objc func loadData() {
        self.refreshControl?.beginRefreshing()
        statusListViewModel.loadStatus(id: vm != nil ? (vm?.status.id == 0 ? nil : vm?.status.id) : nil, comment_id: vm != nil ? (vm?.status.comment_id == 0 ? nil : vm?.status.comment_id): nil) { (isSuccessful) in
            self.refreshControl?.endRefreshing()
            if !isSuccessful {
                showError("加载数据错误，请稍后再试")
                return
            }
            self.tableView.reloadData()
        }
    }
    private lazy var photoBrowserAnimator: PhotoBrowserAnimator = PhotoBrowserAnimator()
    override func viewDidLoad() {
        super.viewDidLoad()
        if !userLogon {
            visitorView?.setupInfo(imageName: nil, title: NSLocalizedString("登陆一下，随时随地发现新鲜事", comment: ""))
            return
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("关闭", comment: ""), style: .plain, target: self, action: #selector(self.close))
        navigationItem.rightBarButtonItem?.tintColor = .red
        refreshControl = ACRefreshControl()
        refreshControl?.addTarget(self, action: #selector(loadData), for: .valueChanged)
        NotificationCenter.default.addObserver(forName: Notification.Name(ACStatusSelectedPhotoNotification), object: nil, queue: nil) {[weak self] n in
            guard let indexPath = n.userInfo?[ACStatusSelectedPhotoIndexPathKey] as? IndexPath else {
                return
            }
            guard let urls = n.userInfo?[ACStatusSelectedPhotoURLsKey] as? [URL] else {
                return
            }
            guard let cell = n.object as? PhotoBrowserPresentDelegate else {
                return
            }
            Task { @MainActor in
                let vc = PhotoBrowserViewController(urls: urls, indexPath: indexPath)
                vc.modalPresentationStyle = .custom
                vc.transitioningDelegate = self?.photoBrowserAnimator
                self?.photoBrowserAnimator.setDelegateParams(present: cell, using: indexPath, dimissDelegate: vc)
                self?.present(vc, animated: true,completion: nil)
            }
        }
        prepareTableView()
        loadData()
    }
    
    @objc func close() {
        self.dismiss(animated: true)
    }
    @objc func whenIconViewIsTouched(sender: UITapGestureRecognizer) {
        present(UINavigationController(rootViewController: ProfileTableViewController(account: sender.userViewModel)), animated: true)
    }
}
extension BlogTableViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return statusListViewModel.statusList.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let vm = statusListViewModel.statusList[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: vm.cellId, for: indexPath) as! StatusCell
        // Configure the cell...
        cell.viewModel = vm
        cell.bottomView.deleteButton.vm = vm
        let like_list = vm.status.like_list
        cell.bottomView.likeButton.setImage(.timelineIconUnlike, for: .normal)
        let g = UITapGestureRecognizer(target: self, action: #selector(self.whenIconViewIsTouched(sender:)))
        g.userViewModel = UserViewModel(user: Account(dict: ["user":vm.status.user ?? "","uid": "\(vm.status.comment_uid == 0 ? vm.status.uid : vm.status.comment_uid)", "portrait":vm.userProfileUrl.absoluteString, "isfollowed": vm.status.isfollowed]))
        cell.topView.iconView.addGestureRecognizer(g)
        for s in like_list {
            if s["like_uid"] as! String == UserAccountViewModel.sharedUserAccount.account!.uid! {
                cell.bottomView.likeButton.setImage(.timelineIconLike, for: .normal)
                break
            }
        }
        cell.bottomView.deleteButton.addTarget(self, action: #selector(self.deleteStatus(_:)), for: .touchUpInside)
        cell.bottomView.likeButton.setTitle("\(statusListViewModel.statusList[indexPath.row].status.like_count)", for: .normal)
        cell.bottomView.likeButton.vm = vm
        cell.bottomView.likeButton.tag = indexPath.row
        //like(cell.commentBottomView.likeButton)
        cell.bottomView.likeButton.addTarget(self, action: #selector(self.like(_:)), for: .touchUpInside)
        
        cell.cellDelegate = self
        return cell
    }
    @objc func deleteStatus(_ sender: UIButton) {
        let svscmd=(sender.vm?.status.comment_id == 0 ? nil : sender.vm?.status.comment_id)
        let vscmd=(vm?.status.comment_id == 0 ? nil : vm?.status.comment_id)
        let comment_id = vm != nil ? (vm?.status.comment_id == 0 ? svscmd : vscmd) : nil
        let quote_id = comment_id != vm?.status.comment_id ? nil : svscmd
        NetworkTools.shared.deleteStatus(comment_id, quote_id, sender.vm!.status.id) { Result, Error in
            if Error != nil {
                showError("出错了")
                return
            }
            if (Result as! [String:Any])["error"] != nil {
                showError("出错了")
                return
            }
            showInfo("删除成功")
            Task { @MainActor in
                self.deleteStatusInList(sender.vm!.status.id, sender.tag)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return statusListViewModel.statusList[indexPath.row].rowHeight
    }
}
extension BlogTableViewController: @preconcurrency StatusCellDelegate {
    func statusCellDidClickUrl(url: URL) {
        let vc = ACWebViewController(url: url)
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    func present(_ controller: UIViewController) {
        self.present(controller, animated: true)
    }
}

