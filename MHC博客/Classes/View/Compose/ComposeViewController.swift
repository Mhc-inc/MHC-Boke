//
//  ComposeViewController.swift
//  MHC微博
//
//  Created by mhc team on 2022/11/11.
//

import UIKit

class ComposeViewController: UIViewController, UIWebViewDelegate {
    private lazy var picturesPickerController = PicturePickerController()
    var toolbar: UIToolbar = UIToolbar()
    private lazy var textView:UITextView = {
        let tv = UITextView()
        tv.font = UIFont.systemFont(ofSize: 18)
        tv.textColor = .label
        tv.alwaysBounceVertical = true
        tv.keyboardDismissMode = UIScrollView.KeyboardDismissMode.onDrag
        tv.delegate = self
        return tv
    }()
    private func preparePicturePicker() {
        addChild(picturesPickerController)
        view.insertSubview(picturesPickerController.view, belowSubview: toolbar)
        picturesPickerController.view.snp.makeConstraints { make in
            make.bottom.equalTo(view.snp.bottom)
            make.left.equalTo(view.snp.left)
            make.right.equalTo(view.snp.right)
            make.height.equalTo(0)
        }
    }
    private lazy var trendView: TrendCellView = TrendCellView { viewModel in
        self.textView.text.append(contentsOf: "#"+viewModel+"#")
        self.textView.delegate?.textViewDidChange!(self.textView)
    }
    private lazy var emoticonView: EmoticonView = EmoticonView { emoticon in
        self.textView.insertEmoticon(emoticon)
    }
    private lazy var userCollectionView: UserCollectionCellView = UserCollectionCellView { viewModel in
        guard let user = viewModel.user.user else {
            return
        }
        self.textView.text.append(contentsOf: "@"+user)
        self.textView.delegate?.textViewDidChange!(self.textView)
    }
    @objc private func createTrend() {
        let controller = UIAlertController(title: "创建话题", message: "输入你的话题：", preferredStyle: .alert)
        controller.addTextField { textField in
            textField.placeholder = "创建你的话题"
            textField.textColor = .label
        }
        controller.addAction(UIAlertAction(title: "关闭", style: .cancel))
        controller.addAction(UIAlertAction(title: "创建", style: .default) { action in
            guard let fields = controller.textFields else {
                return
            }
            if fields[0].hasText {
                NetworkTools.shared.trend(fields[0].text!) { Result, Error in
                    controller.dismiss(animated: true)
                }
            }
        })
        self.present(controller, animated: true)
    }
    @objc private func selectPicture() {
        textView.resignFirstResponder()
        if picturesPickerController.view.frame.height > 0 {
            return
        }
        picturesPickerController.view.snp.updateConstraints { make in
            make.height.equalTo(view.bounds.height * 0.6)
        }
        textView.snp.remakeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(view.snp.left)
            make.right.equalTo(view.snp.right)
            make.bottom.equalTo(picturesPickerController.view.snp.top)
        }
    }
    @objc private func selectTrend() {
        NetworkTools.shared.trend { result,error in
            guard let Result = result as? [String] else {
                return
            }
            print(Result)
            self.trendView.collectionView.reloadData()
            self.trendView.trendList = Result
        }
        self.trendView.setupUI()
        print(self.trendView.trendList)
        textView.resignFirstResponder()
        textView.inputView = textView.inputView == nil ? self.trendView : nil
        textView.becomeFirstResponder()
    }
    @objc private func selectUser() {
        userCollectionView.friendListViewModel.loadFriend { isSuccessed in
            print(isSuccessed)
            self.userCollectionView.collectionView.reloadData()
        }
        self.userCollectionView.setupUI()
        print(self.userCollectionView.friendListViewModel.friendList)
        textView.resignFirstResponder()
        textView.inputView = textView.inputView == nil ? userCollectionView : nil
        textView.becomeFirstResponder()
    }
    @objc private func selectEmoticon() {
        textView.resignFirstResponder()
        textView.inputView = textView.inputView == nil ? emoticonView : nil
        textView.becomeFirstResponder()
    }
    private lazy var placeHolderLabel: UILabel = UILabel(title: "分享新鲜事...",fontSize: 18,color: UIColor(white: 0.6, alpha: 1.0))
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        textView.becomeFirstResponder()
    }
    override func viewDidAppear(_ animated: Bool) {
        if picturesPickerController.view.frame.height == 0 {
            textView.becomeFirstResponder()
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self,
            selector: #selector(self.keyboardChange(_:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil)
        setupUI()
    }
    @objc private func keyboardChange(_ n: NSNotification) {
        let rect = (n.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let duration = (n.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        let offset = -UIScreen.main.bounds.height + rect.origin.y
        toolbar.snp.updateConstraints { make in
            make.bottom.equalTo(view.snp.bottom).offset(offset)
        }
        let curve = (n.userInfo![UIResponder.keyboardAnimationCurveUserInfoKey] as! NSNumber).intValue
        UIView.animate(withDuration: duration) {
            UIViewPropertyAnimator(duration: duration, curve: UIView.AnimationCurve(rawValue: curve)!).startAnimation()
            self.view.layoutIfNeeded()
        }
    }
}
extension ComposeViewController {
    func setupUI() {
        view.backgroundColor = .systemBackground
        NotificationCenter.default.addObserver(forName: .init("TrendPresentViewControllerNotification"), object: nil, queue: nil) { n in
            if n.object != nil {
                self.present(n.object as! UIAlertController, animated: true)
            }
        }
        //automaticallyAdjustsScrollViewInsets = false
        prepare()
        prepareTool()
        prepareTextView()
        preparePicturePicker()
    }
    private func prepare() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "创建一个话题", style: .plain, target: self, action: #selector(self.createTrend))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "发布", style: .plain, target: self, action: #selector(self.sendStatus))
        navigationItem.leftBarButtonItem?.tintColor = .red
        navigationItem.rightBarButtonItem?.tintColor = .red
        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 36))
        navigationItem.titleView = titleView
        let titleLabel = UILabel(title: "写博客",fontSize: 15)
        let nameLabel = UILabel(title: UserAccountViewModel.sharedUserAccount.account?.user ?? "", fontSize: 13,color: UIColor(white: 0.6, alpha: 1.0))
        titleView.addSubview(titleLabel)
        titleView.addSubview(nameLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalTo(titleView.snp.centerX)
            make.top.equalTo(titleView.snp.top)
        }
        nameLabel.snp.makeConstraints { make in
            make.centerX.equalTo(titleView.snp.centerX)
            make.bottom.equalTo(titleView.snp.bottom)
        }
        navigationItem.rightBarButtonItem?.isEnabled = false
    }
    @objc private func sendStatus() {
        let text = textView.emoticonText
        let image = picturesPickerController.pictures
        SVProgressHUD.show(withStatus: "加载中")
        if image != [] {
            NetworkTools.shared.sendStatus(status: text, image: image) { (Result, Error) -> () in
                SVProgressHUD.dismiss()
                if Error != nil {
                    SVProgressHUD.showInfo(withStatus: "您的网络不给力")
                    return
                }
                self.textView.resignFirstResponder()
                self.dismiss(animated: true,completion: nil)
            }
        } else {
            NetworkTools.shared.sendStatus(status: text, image: nil) { (Result, Error) -> () in
                SVProgressHUD.dismiss()
                if Error != nil {
                    SVProgressHUD.showInfo(withStatus: "您的网络不给力")
                    return
                }
                self.textView.resignFirstResponder()
                self.dismiss(animated: true,completion: nil)
            }
        }
    }
    private func prepareTextView() {
        textView.addSubview(placeHolderLabel)
        placeHolderLabel.snp.makeConstraints { make in
            make.top.equalTo(textView.snp.top).offset(8)
            make.left.equalTo(textView.snp.left).offset(5)
        }
        view.addSubview(textView)
        textView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(view.snp.left)
            make.right.equalTo(view.snp.right)
            make.bottom.equalTo(toolbar.snp.top)
        }
    }
    private func prepareTool() {
        view.addSubview(toolbar)
        toolbar.backgroundColor = .init(white: 0.8, alpha: 1.0)
        toolbar.snp.makeConstraints { make in
            make.bottom.equalTo(view.snp.bottom)
            make.left.equalTo(view.snp.left)
            make.right.equalTo(view.snp.right)
            make.height.equalTo(44)
        }
        let itemSettings = [["imageName": "compose_toolbar_picture", "actionName": "selectPicture"],["imageName": "compose_mentionbutton_background","actionName":"selectUser"], ["imageName":"compose_trendbutton_background","actionName":"selectTrend"],["imageName":"compose_emoticonbutton_background","actionName":"selectEmoticon"],["imageName": "compose_pic_big_add"]]
        var items = [UIBarButtonItem]()
        for dict in itemSettings {
            items.append(UIBarButtonItem(imageName: dict["imageName"]!, target: self, actionName: dict["actionName"]))
            items.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
        }
        items.removeLast()
        toolbar.items = items
    }
}
extension ComposeViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        navigationItem.rightBarButtonItem?.isEnabled = textView.hasText
        placeHolderLabel.isHidden = textView.hasText
    }
}
