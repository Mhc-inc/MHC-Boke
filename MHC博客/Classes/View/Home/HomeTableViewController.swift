//
//  HomeTableViewController.swift
//  MHC微博
//
//  Created by Monkey hammer on 2022/9/10.
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
class HomeTableViewController: VisitorTableViewController,UICollectionViewDelegate, UICollectionViewDataSource {
    lazy var refreshView = CustomRefreshView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 30))
    @objc func refresh(pullup: UIActivityIndicatorView) {
        if listViewModel.statusList.count >= 10{
            if pullup.isAnimating {
                // 开始动画
                loadData()
                pullup.stopAnimating()
            }//十条刷新一次
        }
    }
    private lazy var composedButton: UIBarButtonItem = UIBarButtonItem(title: NSLocalizedString("写", comment: ""), image: UIImage(systemName: "pencil"), target: self, action: #selector(self.clickComposedButton))
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
    let liveView = LiveTableView()
    private func prepareTableView() {
        tableView.separatorStyle = .none
        tableView.register(StatusNormalCell.self, forCellReuseIdentifier: StatusCellNormalId)
        tableView.estimatedRowHeight = 400
        tableView.rowHeight = 400
        refreshControl = WBRefreshControl()
        refreshControl?.addTarget(self, action: #selector(self.loadData), for: .valueChanged)
        refreshView.refreshAction = { pullup in
                    // 执行刷新操作
            self.refresh(pullup: pullup)
        }
        tableView.tableFooterView = refreshView
        liveView.delegate = self
        liveView.dataSource = self
        tableView.tableHeaderView = liveListViewModel.list.isEmpty ? nil : liveView
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return liveListViewModel.list.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let vm = liveListViewModel.list[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LiveCellNormalId, for: indexPath) as! UserCollectionCell
        cell.viewModel = vm
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let vm = liveListViewModel.list[indexPath.row]
        guard let url = ("http://mhcincapi.top/hls/\(vm.user.uid).m3u8").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            SVProgressHUD.showInfo(withStatus: NSLocalizedString("似乎出了点问题，请刷新重试",comment: ""))
            return
        }
        print(url)
        guard let urlEncoded = URL(string:url) else {
            SVProgressHUD.showInfo(withStatus: NSLocalizedString("似乎出了点问题，请刷新重试",comment: ""))
            return
        }
        present(HomeWebViewController(url: urlEncoded),animated: true)
    }
    @objc func loadData() {
        self.refreshControl?.beginRefreshing()
        //StatusDAL.clearDataCache()//删除缓存
        listViewModel.loadStatus(isPullup: self.refreshView.pullupView.isAnimating) { (isSuccessed) in
            self.refreshControl?.endRefreshing()
            self.refreshView.pullupView.stopAnimating()
            if !isSuccessed {
                SVProgressHUD.showInfo(withStatus: NSLocalizedString("加载数据错误，请稍后再试",comment: ""))
                return
            }
            self.showPulldownTip()
            self.tableView.reloadData()
        }
            self.liveView.loadData()
            self.liveView.reloadData()
            self.tableView.tableHeaderView = liveListViewModel.list.isEmpty ? nil : self.liveView
    }
    private lazy var pulldownTipLabel: UILabel = {
        let label = UILabel(title: "", fontSize: 18,color: .white)
        label.backgroundColor = .red
        self.navigationController?.navigationBar.insertSubview(label, at: 0)
        return label
    }()
    private func showPulldownTip() {
        guard let count = listViewModel.pulldownCount else {
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
        if !UserAccountViewModel.sharedUserAccount.userLogon {
            visitorView?.setupInfo(imageName: nil, title: NSLocalizedString("登陆一下，随时随地发现新鲜事", comment: ""))
            return
        }
        prepareTableView()
        NotificationCenter.default.addObserver(forName: Notification.Name(WBStatusSelectedPhotoNotification), object: nil, queue: nil) {[weak self] n in
            guard let indexPath = n.userInfo?[WBStatusSelectedPhotoIndexPathKey] as? IndexPath else {
                return
            }
            guard let urls = n.userInfo?[WBStatusSelectedPhotoURLsKey] as? [URL] else {
                return
            }
            guard let cell = n.object as? PhotoBrowserPresentDelegate else {
                return
            }
            let vc = PhotoBrowserViewController(urls: urls, indexPath: indexPath)
            vc.modalPresentationStyle = .custom
            vc.transitioningDelegate = self?.photoBrowserAnimator
            self?.photoBrowserAnimator.setDelegateParams(present: cell, using: indexPath, dimissDelegate: vc)
            self?.present(vc, animated: true,completion: nil)
        }
        NotificationCenter.default.addObserver(forName: Notification.Name("BKReloadHomePageDataNotification"), object: nil, queue: nil) { n in
            self.tableView.reloadData()
        }
        self.loadData()
    }
    @objc func action(sender: UITapGestureRecognizer) {
        let dict = ["portrait": sender.sender3, "user": sender.sender2, "uid": sender.sender]
        let uvm = UserViewModel(user: Account(dict: dict))
        present(UINavigationController(rootViewController: UIHostingController(rootView: UserNavigationLinkView(account: uvm, uid: sender.sender))), animated: true)
        }

    var cell: StatusCell?
    private lazy var photoBrowserAnimator: PhotoBrowserAnimator = PhotoBrowserAnimator()
}
extension HomeTableViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listViewModel.statusList.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let vm = listViewModel.statusList[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: vm.cellId, for: indexPath) as! StatusCell
        // Configure the cell...
        cell.viewModel = vm
        cell.bottomView.deleteButton.tag = indexPath.row
        cell.bottomView.deleteButton.addTarget(self, action: #selector(self.action1(_:)), for: .touchUpInside)
        let g = UITapGestureRecognizer(target: self, action: #selector(self.action(sender:)))
        guard let viewModel = cell.topView.viewModel as? StatusViewModel else {
            return cell
        }
        g.sender = "\(viewModel.status.uid)"
        g.sender2 = "\(viewModel.status.user ?? "")"
        g.sender3 = "\(viewModel.status.portrait ?? "")"
        cell.topView.iconView.addGestureRecognizer(g)
        cell.bottomView.commentButton.tag = indexPath.row
        cell.bottomView.commentButton.addTarget(self, action: #selector(self.action3(_:)), for: .touchUpInside)
        let result = ["id":"\(listViewModel.statusList[indexPath.row].status.id)","like_uid":UserAccountViewModel.sharedUserAccount.account!.uid!] as [String:Any]
        cell.bottomView.likeButton.setTitle("\(listViewModel.statusList[indexPath.row].status.like_count)", for: .normal)
        NetworkTools.shared.loadOneStatus(id: listViewModel.statusList[indexPath.row].status.id) { res, error in
            if error != nil {
                return
            }
            guard let list = res as? [String:Any] else {
                return
            }
            cell.bottomView.commentButton.setTitle(list["comment_count"] as? String, for: .normal)
            cell.bottomView.likeButton.setTitle(list["like_count"] as? String, for: .normal)
            guard let like_list = list["like_list"] as? [[String:Any]] else {
                return
            }
            for s in like_list {
                if result["like_uid"] as? String == s["like_uid"] as? String {
                    
                    cell.bottomView.likeButton.setImage(UIImage(named:"timeline_icon_like"), for: .normal)
                    break
                } else {
                    cell.bottomView.likeButton.setImage(UIImage(named:"timeline_icon_unlike"), for: .normal)
                }
            }
            if like_list.isEmpty {
                cell.bottomView.likeButton.setImage(UIImage(named:"timeline_icon_unlike"), for: .normal)
            }
        }
        //cell = self.cell!
        cell.bottomView.likeButton.tag = indexPath.row
        cell.bottomView.likeButton.addTarget(self, action: #selector(self.action4(_:)), for: .touchUpInside)
        cell.cellDelegate = self
        return cell
    }
    @objc func action1(_ sender: UIButton) {
        print(listViewModel.statusList[sender.tag].status.id)
        NetworkTools.shared.deleteStatus(nil, nil, listViewModel.statusList[sender.tag].status.id) { Result, Error in
            if Error != nil {
                SVProgressHUD.showInfo(withStatus: NSLocalizedString("出错了",comment:""))
                return
            }
            if (Result as! [String:Any])["error"] != nil {
                SVProgressHUD.showInfo(withStatus: NSLocalizedString("不能删除别人的博客哦", comment: ""))
                return
            }
            SVProgressHUD.showInfo(withStatus: NSLocalizedString("删除成功", comment: ""))
            StatusDAL.removeCache(listViewModel.statusList[sender.tag].status.id)
            listViewModel.statusList.remove(at: sender.tag)
            self.tableView.reloadData()
        }
    }
    @objc func action3(_ sender: UIButton) {
        guard (listViewModel.statusList[sender.tag].status.id > 0) else {
            SVProgressHUD.showInfo(withStatus: NSLocalizedString("出错了", comment: ""))
            return
        }
        let nav = ComposeViewController(nil,listViewModel.statusList[sender.tag].status.id)
        self.present(UINavigationController(rootViewController: nav), animated: true)
    }
    @objc func action4(_ sender: UIButton) {
        NetworkTools.shared.like(listViewModel.statusList[sender.tag].status.id) { Result, Error in
            if Error == nil {
                if (Result as! [String:Any])["code"] as! String == "add" {
                    SVProgressHUD.show(UIImage(named: "timeline_icon_like")!, status: NSLocalizedString("你的点赞TA收到了", comment: ""))
                } else {
                    SVProgressHUD.show(UIImage(named: "timeline_icon_unlike")!, status: NSLocalizedString("你的取消TA收到了", comment: ""))
                }
                self.tableView.reloadData()
                DispatchQueue.main.asyncAfter(deadline: .now()+1){
                    SVProgressHUD.dismiss()
                }
                return
            }
            SVProgressHUD.showInfo(withStatus: NSLocalizedString("出错了", comment: ""))
            return
        }
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return listViewModel.statusList[indexPath.row].rowHeight
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = CommentTableViewController(viewModel: listViewModel.statusList[indexPath.row])
        let nav = UINavigationController(rootViewController:vc)
        nav.modalPresentationStyle = .custom
        self.present(nav, animated: false)
    }
}
extension HomeTableViewController: StatusCellDelegate {
    func statusCellDidClickUrl(url: URL) {
        let vc = HomeWebViewController(url: url)
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    func present(_ controller: UIViewController) {
        self.present(controller, animated: true)
    }
}
extension Dictionary where Key: Equatable {
    func isEqualTo(_ dictionary: Dictionary, excluding: [Key] = []) -> Bool {
      let left = filter({ !excluding.contains($0.key) })
      let right = dictionary.filter({ !excluding.contains($0.key) })
      return NSDictionary(dictionary: left).isEqual(to: right)
    }
}
extension UITextField {
    private struct AssociatedKey {
        static var identifier = String()
    }
    /*
    var identifier: String {
        get {
            return objc_getAssociatedObject(self, &AssociatedKey.identifier) as? String ?? ""
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKey.identifier, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
     */
}
extension UIButton {
    private struct AssociatedKey {
        static var nav: ComposeViewController = ComposeViewController(nil,nil)
        static var vm: StatusViewModel? = TypeNeedCacheListViewModel(clas: .comment).statusList.first
        static var vm2: StatusViewModel? = TypeNeedCacheListViewModel(clas: .quote).statusList.first
       }
    var vm: StatusViewModel? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKey.vm) as? StatusViewModel
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKey.vm, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    var vm2: StatusViewModel? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKey.vm2) as? StatusViewModel
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKey.vm2, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    var nav: ComposeViewController {
        get {
            return objc_getAssociatedObject(self, &AssociatedKey.nav) as? ComposeViewController ?? ComposeViewController(nil,nil)
        }
        
        set {
            objc_setAssociatedObject(self, &AssociatedKey.nav, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
extension UIBarButtonItem {
    private struct AssociatedKey {
        static var nav = ComposeViewController(nil, nil)
        static var vm: StatusViewModel?
    }
    var nav: ComposeViewController {
        get {
            return objc_getAssociatedObject(self, &AssociatedKey.nav) as? ComposeViewController ?? ComposeViewController(nil,nil)
        }
        
        set {
            objc_setAssociatedObject(self, &AssociatedKey.nav, newValue as ComposeViewController?, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    var vm: StatusViewModel? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKey.vm) as? StatusViewModel
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKey.vm, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
