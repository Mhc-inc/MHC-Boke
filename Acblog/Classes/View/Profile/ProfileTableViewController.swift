//
//  UserNavigationLinkView.swift
//  Acblog
//
//  Created by acincor on 2025/8/13.
//
import SwiftUI
import Kingfisher
// MARK: - UserProfileViewController
class ProfileTableViewController: VisitorTableViewController {
    
    // MARK: - 模型数据
    var account: UserViewModel?
    var style: User = .Me
    
    // MARK: - 生命周期
    init(account: UserViewModel?) {
        self.account = account
        super.init(nibName: nil, bundle: nil)
        setupStyle()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !userLogon {
            visitorView?.setupInfo(imageName: "visitordiscover_image_profile", title: NSLocalizedString("登陆后，你的个人信息、直播操作、退登注销将会在这里展示", comment: ""))
            return
        }
        setupUI()
        setupTableView()
        setupNavigationBar()
    }
    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        tableView.reloadData()
//    }
    
    // MARK: - 设置方法
    private func setupStyle() {
        if account == nil {
            style = .Me
        } else {
            let accountUID = "\(account?.user.uid ?? 0)"
            let currentUID = UserAccountViewModel.sharedUserAccount.account?.uid ?? ""
            style = accountUID != currentUID ? .SomeBody : .Me
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = navTitle
        navigationController?.navigationBar.tintColor = .orange
    }
    
    private func setupTableView() {
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.backgroundColor = .systemGroupedBackground
        tableView.register(SettingCell.self, forCellReuseIdentifier: "SettingCell")
        tableView.register(ImageDetailCell.self, forCellReuseIdentifier: "ImageDetailCell")
        tableView.register(ActionButtonCell.self, forCellReuseIdentifier: "ActionButtonCell")
        tableView.dataSource = self
        tableView.delegate = self
        
        // 添加下拉刷新
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    private func setupNavigationBar() {
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .systemBackground
            appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
            
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
        }
    }
    
    // MARK: - 辅助属性
    private var navTitle: String {
        let userName = account?.user.user ?? UserAccountViewModel.sharedUserAccount.account?.user ?? ""
        return NSLocalizedString("用户名：",comment: "")+userName
    }
    
    private var currentUserID: String {
        if let account = account {
            return "\(account.user.uid)"
        }
        return UserAccountViewModel.sharedUserAccount.account?.uid ?? ""
    }
    
    private var name: String {
        style == .Me ? "我的博客" : "TA的博客"
    }
    
    // MARK: - 数据加载
    private func makeController(for type: SpecialClass) -> TypeStatusTableViewController {
        return TypeStatusTableViewController(uid: currentUserID, specialClass: type)
    }
    
    @objc private func handleRefresh() {
        // 模拟数据加载
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.refreshControl?.endRefreshing()
            self.tableView.reloadData()
        }
    }
    
    // MARK: - 跳转方法
    private func showUserAgreement() {
        let agreementVC = UserAgreementViewController()
        agreementVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(agreementVC, animated: true)
    }
    
    private func showBlog() {
        let blogVC = makeController(for: .blog)
        blogVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(blogVC, animated: true)
    }
    
    private func showLikedContent() {
        let likedVC = makeController(for: .like)
        likedVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(likedVC, animated: true)
    }
    
    private func showCommentedContent() {
        let commentsVC = makeController(for: .comment)
        commentsVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(commentsVC, animated: true)
    }
    
    private func showLiveStream() {
        let liveVC = BKLiveController()
        liveVC.hidesBottomBarWhenPushed = true
        present(liveVC, animated: true)
    }
    
    private func showLogoutConfirmation() {
        let controller = UIAlertController(title: NSLocalizedString("退出登录", comment: ""), message: NSLocalizedString("确定要退出登录吗",comment: ""), preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: NSLocalizedString("退出登录", comment: ""), style: .default, handler: { n in
            NotificationCenter.default.post(name: .init(rawValue: .init("ACSwitchRootViewControllerLogOutNotification")), object: "logOut")
        }))
        controller.addAction(UIAlertAction(title: NSLocalizedString("取消", comment: ""), style: .cancel))
        self.present(controller, animated: true)
    }
    
    private func showLogoffConfirmation() {
        let controller = UIAlertController(title: NSLocalizedString("注销账号", comment: ""), message: NSLocalizedString("确定注销账号，不陪我一起玩了吗？",comment: ""), preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: NSLocalizedString("注销账号",comment:""), style: .default) {
            _ in
            NotificationCenter.default.post(name: .init(rawValue: .init("ACSwitchRootViewControllerLogOutNotification")), object: nil)
        })
        controller.addAction(UIAlertAction(title: NSLocalizedString("取消",comment:""), style: .cancel))
        self.present(controller, animated: true)
    }
    private func showFollowings() {
        self.present(UserTableViewController(currentUserID), animated: true)
    }
    private func showFans() {
        self.present(FansTableViewController(currentUserID), animated: true)
    }
    private func showRenameAlert() {
        let controller = UIAlertController(title: NSLocalizedString("更改用户名", comment: ""), message: NSLocalizedString("请在输入框内输入您的用户名：", comment: ""), preferredStyle: .alert)
        controller.addTextField { textField in
            textField.placeholder = NSLocalizedString("输入您的用户名", comment: "")
            textField.textColor = .label
        }
        controller.addAction(UIAlertAction(title: NSLocalizedString("关闭", comment: ""), style: .cancel))
        controller.addAction(UIAlertAction(title: NSLocalizedString("更改", comment: ""), style: .default) { action in
            guard let fields = controller.textFields else {
                return
            }
            if fields[0].hasText {
                NetworkTools.shared.rename(rename: fields[0].text!) { Result, Error in
                    if Error != nil {
                        showError("出错了")
                        return
                    }
                    
                    guard let res = Result as? [String:Any] else {
                        let controller = UIAlertController(title: NSLocalizedString("错误", comment: ""), message: NSLocalizedString("加载数据错误，请稍后重试", comment: ""), preferredStyle: .alert)
                        controller.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(controller, animated: true)
                        return
                    }
                    
                    guard res["msg"] is Int else{
                        let controller = UIAlertController(title: NSLocalizedString("错误", comment: ""), message: NSLocalizedString("改名失败", comment: ""), preferredStyle: .alert)
                        controller.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(controller, animated: true)
                        return
                    }
                    UserAccountViewModel.sharedUserAccount.loadUserInfo(account: UserAccountViewModel.sharedUserAccount.account!) { isSuccessful in
                        if isSuccessful {
                            showInfo("改名成功")
                        }
                    }
                }
            }
        })
        self.present(controller, animated: true)
    }
    
    private func showAddFriend() {
        let controller = UIAlertController(title: NSLocalizedString("即将执行此操作", comment: ""), message: NSLocalizedString("确定吗",comment: ""), preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: NSLocalizedString("确定", comment: ""), style: .default, handler: { n in
            NetworkTools.shared.addFriend("\(self.account?.user.uid ?? 0)") { Result, Error in
                if Error != nil {
                    showError("出错了")
                    return
                }
                guard let result = Result as? [String:Any] else {
                    showError("出错了")
                    
                    return
                }
                if (result["error"] != nil) {
                    let err = result["error"] as? String ?? ""
                    showError(err)
                    return
                }
                guard let code = result["code"] as? String else {
                    showError("出错了")
                    
                    return
                }
                if (code != "delete") {
                    showInfo("成功添加好友")
                    return
                }
                showInfo("成功删除好友")
            }
        }))
        controller.addAction(UIAlertAction(title: NSLocalizedString("取消", comment: ""), style: .cancel))
        self.present(controller, animated: true)
    }
}

// MARK: - UITableView 数据源和代理
extension ProfileTableViewController {
    
    // MARK: - 分组设置
    override func numberOfSections(in tableView: UITableView) -> Int {
        return !userLogon ? 0 : 3 // 头像/用户信息, 主要功能, 操作按钮
    }
    // MARK: - 行数设置
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: // 头像和用户名
            return 1
        case 1: // 主要功能
            return account == nil ? 8 : 6 // 查看资料卡少"开始直播"、"修改昵称"
        case 2: // 操作按钮
            if account == nil {
                return 2 // 注销账号, 退出登录
            } else if style == .SomeBody {
                return 1 // 添加好友
            }
            return 0
        default:
            return 0
        }
    }
    
    // MARK: - 单元格配置
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0: // 头像和用户名
            let cell = tableView.dequeueReusableCell(withIdentifier: "ImageDetailCell", for: indexPath) as! ImageDetailCell
            cell.configure(account: account)
            return cell
            
        case 1: // 主要功能
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath) as! SettingCell
            
            switch indexPath.row {
            case 0:
                cell.configure(title: "用户协议", image: UIImage(systemName: "text.page")!, showArrow: true)
            case 1:
                cell.configure(title: name, image: UIImage(systemName: "folder.circle")!, showArrow: true)
                
            case 2:
                cell.configure(title: "点赞过的", image: .timelineIconLike, showArrow: true)
            case 3:
                cell.configure(title: "评论过的", image: .timelineIconComment, showArrow: true)
            case 4:
                cell.configure(title: "粉丝", image: UIImage(systemName: "person")!, showArrow: true)
            case 5:
                cell.configure(title: "关注", image: .add, showArrow: true)
            case 6:
                cell.configure(title: "修改昵称", image: UIImage(systemName: "person.circle")!, showArrow: true)
            case 7: // 查看资料卡
                cell.configure(title: "开始直播", image: .liveSmallIcon, showArrow: true)
           
            default:
                break
            }
            
            return cell
            
        case 2: // 操作按钮
            let cell = tableView.dequeueReusableCell(withIdentifier: "ActionButtonCell", for: indexPath) as! ActionButtonCell
            
            if account == nil {
                cell.configure(title: indexPath.row == 0 ? "注销账号" : "退出登录", color: .orange)
            } else if style == .SomeBody {
                
                cell.configure(title: (account?.user.isfollowed ?? 0 == 0) ? "添加好友" : "删除好友", color: .orange)
            }
            
            return cell
            
        default:
            return UITableViewCell()
        }
    }
    
    // MARK: - 行高设置
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0: // 头像行
            return 80
        default:
            return 60
        }
    }
    
    // MARK: - 分组头部高度
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 0.1 : 12 // 第一个分组不需要头部空间
    }
    
    // MARK: - 分组底部高度
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.1
    }
    
    // MARK: - 单元格点击事件
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 0: // 头像点击
            showUserProfileBrowser()
            
        case 1: // 功能项点击
            switch indexPath.row {
            
            case 0: // 用户协议
                showUserAgreement()
            case 1: // 博客
                showBlog()
            case 2: // 点赞过的
                showLikedContent()
            case 3: // 评论过的
                showCommentedContent()
            case 4: // 粉丝
                showFans()
            case 5: // 关注
                showFollowings()
            case 6: // 开始直播
                showRenameAlert()
            case 7: // 仅未登录时显示
                showLiveStream()
            
            default:
                break
            }
            
        case 2: // 操作按钮点击
            if account == nil {
                if indexPath.row == 0 { // 注销账号
                    showLogoffConfirmation()
                } else { // 退出登录
                    showLogoutConfirmation()
                }
            } else if style == .SomeBody { // 添加好友
                showAddFriend()
            }
            
        default:
            break
        }
    }
    
    // MARK: - 显示头像浏览器
    private func showUserProfileBrowser() {
        let url = account?.userProfileUrl ?? UserAccountViewModel.sharedUserAccount.portraitUrl
        let browserVC = UserProfileBrowserViewController(url: url, style: style)
        browserVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(browserVC, animated: true)
    }
}

// MARK: - 自定义单元格

// 头像和用户信息单元格
class ImageDetailCell: UITableViewCell {
    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let uidLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // 头像设置
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 5
        avatarImageView.clipsToBounds = true
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(avatarImageView)
        
        // 用户名标签
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)
        
        // UID标签
        uidLabel.font = UIFont.systemFont(ofSize: 14)
        uidLabel.textColor = .secondaryLabel
        uidLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(uidLabel)
        
        // 布局约束
        NSLayoutConstraint.activate([
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 50),
            avatarImageView.heightAnchor.constraint(equalToConstant: 50),
            
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: avatarImageView.topAnchor, constant: 5),
            
            uidLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            uidLabel.bottomAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: -5)
        ])
    }
    
    func configure(account: UserViewModel?) {
        if let account = account {
            avatarImageView.kf.setImage(
                with: account.userProfileUrl,
                options: [
                    .retryStrategy(DelayRetryStrategy(maxRetryCount: 12, retryInterval: .seconds(1))),
                    .forceRefresh
                ]
            )
            nameLabel.text = account.user.user
            uidLabel.text = "AID: \(account.user.uid)"
        } else {
            avatarImageView.kf.setImage(
                with: UserAccountViewModel.sharedUserAccount.portraitUrl,
                options: [
                    .retryStrategy(DelayRetryStrategy(maxRetryCount: 12, retryInterval: .seconds(1))),
                    .forceRefresh
                ]
            )
            nameLabel.text = UserAccountViewModel.sharedUserAccount.account?.user
            uidLabel.text = "AID: \(UserAccountViewModel.sharedUserAccount.account?.uid ?? "")"
        }
    }
}

// 设置项单元格
class SettingCell: UITableViewCell {
    private let titleLabel = UILabel()
    private let arrowImageView = UIImageView()
    private let systemImageView = UIImageView(image: UIImage(systemName: "medal"))
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        systemImageView.tintColor = .systemGray
        systemImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(systemImageView)
        // 标题标签
        titleLabel.textColor = .orange
        titleLabel.font = UIFont.systemFont(ofSize: 17)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // 箭头图标
        arrowImageView.image = UIImage(systemName: "chevron.right")
        arrowImageView.tintColor = .systemGray
        arrowImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(arrowImageView)
        systemImageView.snp.makeConstraints { make in
            make.left.equalTo(contentView.snp.left).offset(14)
            make.centerY.equalTo(contentView.snp.centerY)
        }
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(systemImageView.snp.right).offset(14)
            make.centerY.equalTo(contentView.snp.centerY)
        }
        arrowImageView.snp.makeConstraints { make in
            make.right.equalTo(contentView.snp.right).inset(14)
            make.centerY.equalTo(contentView.snp.centerY)
        }
    }
    
    func configure(title: String, image: UIImage, showArrow: Bool = true) {
        systemImageView.image = image
        //systemImageView.sizeToFit()
        titleLabel.text = NSLocalizedString(title, comment: "")
        arrowImageView.isHidden = !showArrow
        accessoryType = .none
    }
}

// 操作按钮单元格
class ActionButtonCell: UITableViewCell {
    private let actionButton = UIButton(type: .system)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // 按钮设置
        actionButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(actionButton)
        
        // 布局约束
        NSLayoutConstraint.activate([
            actionButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            actionButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func configure(title: String, color: UIColor) {
        actionButton.setTitle(NSLocalizedString(title, comment: ""), for: .normal)
        actionButton.setTitleColor(color, for: .normal)
    }
}
