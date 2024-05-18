//
//  UIButton+Extension.swift
//  MHC微博
//
//  Created by Monkey hammer on 2022/9/7.
//

import Foundation
import UIKit
import SwiftUI
struct UserNavigationLinkView: View {
    @State var isShow = false
    @State var isShow2 = false
    var account: UserViewModel?
    var name: String {
        if account == nil {
            return NSLocalizedString("我的博客", comment: "")
        }
        return NSLocalizedString("TA的博客", comment: "")
    }
    var uid: String
    var likeController:LikeStatusTableViewController {
        if let account = account {
            return LikeStatusTableViewController(uid: "\(account.user.uid)")
        }
        return LikeStatusTableViewController(uid: UserAccountViewModel.sharedUserAccount.account?.uid ?? "")
    }
    var commentController : CommentStatusTableViewController {
        if let account = account {
            return CommentStatusTableViewController(uid: "\(account.user.uid)")
        }
        return CommentStatusTableViewController(uid: UserAccountViewModel.sharedUserAccount.account?.uid ?? "")
    }
    var body: some View {
        if #available(iOS 15.0, *) {
            NavigationView {
                List {
                    ImageDetailView(account: account)
                    NavigationLink(destination: MyDetailView (controller: UserAgreementViewController())) {
                        Text("用户协议")
                            .foregroundColor(.orange)
                    }
                    NavigationLink(destination: MyDetailView(controller: ProfileTableViewController(account: account))) {
                        Text("主页")
                            .foregroundColor(.orange)
                    }
                    NavigationLink(destination: MyDetailView(controller: BlogsTableViewController(uid: uid))) {
                        Text(name)
                            .foregroundColor(.orange)
                    }
                    NavigationLink(destination: MyDetailView(controller: likeController)) {
                        Image("timeline_icon_like")
                        Text("点赞过的")
                            .foregroundColor(.orange)
                    }
                    NavigationLink(destination: MyDetailView(controller: commentController)) {
                        Image("timeline_icon_comment")
                        Text("评论过的")
                            .foregroundColor(.orange)
                    }
                    if account == nil {
                        NavigationLink(destination: MyDetailView(controller: BKLiveController())) {
                            Image("live_small_icon")
                                .background(Color.red)
                            Text("开始直播")
                                .foregroundColor(.orange)
                        }
                        NavigationLink(destination: MyDetailView(controller:UINavigationController(rootViewController:logOffController(showing: self.$isShow))), isActive: self.$isShow) {
                            Text("注销账号")
                                .foregroundColor(.orange)
                        }
                        NavigationLink(destination: MyDetailView(controller:UINavigationController(rootViewController:logOutController(showing: self.$isShow2))), isActive: self.$isShow2) {
                            Text("退出登录")
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .refreshable {
                commentController.loadData()
                likeController.loadData()
            }
            .navigationBarTitle("Name: "+(account?.user.user != nil ? "\(account!.user.user ?? "")" : (UserAccountViewModel.sharedUserAccount.account?.user ?? "")))
            .accentColor(.orange)
        } else {
            // Fallback on earlier versions
            NavigationView {
                List {
                    ImageDetailView(account: account)
                    NavigationLink(destination: MyDetailView (controller: UserAgreementViewController())) {
                        Text("用户协议")
                            .foregroundColor(.orange)
                    }
                    NavigationLink(destination: MyDetailView(controller: ProfileTableViewController(account: account))) {
                        Text("主页")
                            .foregroundColor(.orange)
                    }
                    NavigationLink(destination: MyDetailView(controller:  BlogsTableViewController(uid: uid))) {
                        Text(name)
                            .foregroundColor(.orange)
                    }
                    NavigationLink(destination: MyDetailView(controller: likeController)) {
                        Image("timeline_icon_like")
                        Text("点赞过的")
                            .foregroundColor(.orange)
                    }
                    NavigationLink(destination: MyDetailView(controller: commentController)) {
                        Image("timeline_icon_comment")
                        Text("评论过的")
                            .foregroundColor(.orange)
                    }
                    if account == nil {
                        NavigationLink(destination: MyDetailView(controller: BKLiveController())) {
                            Image("live_small_icon")
                                .background(Color.red)
                            Text("开始直播")
                                .foregroundColor(.orange)
                        }
                        NavigationLink(destination: MyDetailView(controller:UINavigationController(rootViewController:logOffController(showing: self.$isShow))), isActive: self.$isShow) {
                            Text("注销账号")
                                .foregroundColor(.orange)
                        }
                        NavigationLink(destination: MyDetailView(controller:UINavigationController(rootViewController:logOutController(showing: self.$isShow2))), isActive: self.$isShow2) {
                            Text("退出登录")
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .navigationBarTitle("Name: "+(account?.user.user != nil ? "\(account!.user.user ?? "")" : (UserAccountViewModel.sharedUserAccount.account?.user ?? "")))
            .accentColor(.orange)
        }
    }
}
struct MyDetailView: UIViewControllerRepresentable {
    var controller: UIViewController
    func makeUIViewController(context: Context) -> UIViewController {
        // 返回你想展示的 UIViewController 实例
        return controller
    }
 
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // 如果需要更新 UIViewController 的状态，可以在这里实现
    }
}

struct ImageDetailView: UIViewRepresentable {
    var account: UserViewModel?
    func makeUIView(context: Context) -> UIView {
        //let view = ProfilePictureView(viewModel: account.portraitUrl)
        let view = UIView()
        let imageView = UIImageView()
        var label: UILabel
        var MIDLabel: UILabel
        if let account = account {
            imageView.sd_setImage(with: account.userProfileUrl, placeholderImage: nil, options: [SDWebImageOptions.retryFailed,SDWebImageOptions.refreshCached])
            label = UILabel(title: "\(account.user.user ?? "")")
            MIDLabel = UILabel(title:"MID: "+"\(account.user.uid)")
        } else {
            imageView.sd_setImage(with: UserAccountViewModel.sharedUserAccount.portraitUrl, placeholderImage: nil, options: [SDWebImageOptions.retryFailed,SDWebImageOptions.refreshCached])
            label = UILabel(title: UserAccountViewModel.sharedUserAccount.account?.user ?? "")
            MIDLabel = UILabel(title:"MID: "+(UserAccountViewModel.sharedUserAccount.account?.uid ?? ""))
        }
        imageView.layer.cornerRadius = 5
        imageView.clipsToBounds = true
        view.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.top.equalTo(view.snp.top)
            make.width.equalTo(35)
            make.height.equalTo(35)
        }
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.top.equalTo(view.snp.top)
            make.left.equalTo(imageView.snp.right).offset(10)
        }
        view.addSubview(MIDLabel)
        MIDLabel.snp.makeConstraints { make in
            make.bottom.equalTo(view.snp.bottom)
            make.left.equalTo(imageView.snp.right).offset(10)
        }
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {
    }
    typealias UIViewType = UIView
}
extension UIButton {
    convenience init(imageName:String,backImageName:String?) {
        self.init()
        setImage(UIImage(named: imageName), for: .normal)
        setImage(UIImage(named: imageName+"_highlighted"), for: .highlighted)
        if let backImageName = backImageName {
            setBackgroundImage(UIImage(named: backImageName), for: .normal)
            setBackgroundImage(UIImage(named: backImageName + "_highlighted"), for: .highlighted)
        }
        sizeToFit()
    }
    convenience init(title: String, color: UIColor, backImageName: String?, backColor: UIColor? = nil) {
        self.init()
        setTitle(title, for: .normal)
        setTitleColor(color, for: .normal)
        if let backImageName = backImageName {
            setBackgroundImage(UIImage(named: backImageName), for: .normal)
        }
        backgroundColor = backColor
        sizeToFit()
    }
    convenience init(title: String, fontSize: CGFloat, color: UIColor, imageName: String?, backColor: UIColor? = nil) {
        self.init()
        setTitle(title, for: UIControl.State())
        setTitleColor(color, for: UIControl.State())
        if let imageName = imageName {
            setImage(UIImage(named: imageName), for: UIControl.State())
        }
        backgroundColor = backColor
        titleLabel?.font = UIFont.systemFont(ofSize: fontSize)
        sizeToFit()
    }
    func setValue(value: String,key: String) {
        objc_setAssociatedObject(self, &(associatedKey.value_list), [key:value], objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    func getValue() -> [[String:String]]{
        return objc_getAssociatedObject(self, &(associatedKey.value_list)) as! [[String:String]]
    }
    struct associatedKey {
        static var value_list: [[String:String]] = []
    }
}
