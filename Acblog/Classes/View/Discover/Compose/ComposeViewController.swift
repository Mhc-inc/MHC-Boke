//
//  ComposeViewController.swift
//  AC博客
//
//  Created by AC on 2022/11/11.
//

import UIKit

class ComposeViewController: UIViewController /*,UIWebViewDelegate*/ {
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
    var comment_id: Int?
    var id: Int?
    init(_ comment_id: Int?, _ id: Int?,_ chat: Bool? = nil) {
        self.comment_id = comment_id
        self.id = id
        self.chat = chat
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    var finished: ((String,[UIImage])->())?
#if os(visionOS)
    override var preferredContainerBackgroundStyle: UIContainerBackgroundStyle {
        return .glass
    }
#endif
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
    var chat: Bool? = false
    private lazy var trendView: TrendCellView = TrendCellView { viewModel in
        self.textView.insertText("#"+viewModel+"#")
        self.textView.delegate?.textViewDidChange!(self.textView)
    }
    private lazy var emoticonView: EmoticonView = EmoticonView(selectedEmoticon: { emoticon in
        self.textView.insertEmoticon(emoticon)
    }) {
        self.textView.deleteBackward()
    }
    private lazy var userCollectionView: UserCollectionCellView = UserCollectionCellView { viewModel in
        self.textView.text.append(contentsOf: "@\(viewModel.user.uid)")
        self.textView.delegate?.textViewDidChange!(self.textView)
    }
    @objc private func createTrend() {
        let controller = UIAlertController(title: NSLocalizedString("创建话题", comment: ""), message: NSLocalizedString("输入你的话题：", comment: ""), preferredStyle: .alert)
        controller.addTextField { textField in
            textField.placeholder = NSLocalizedString("创建你的话题", comment: "")
            textField.textColor = .label
        }
        controller.addAction(UIAlertAction(title: NSLocalizedString("关闭", comment: ""), style: .cancel))
        controller.addAction(UIAlertAction(title: NSLocalizedString("创建", comment: ""), style: .default) { action in
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
            self.trendView.trendList = Result
            self.trendView.collectionView.reloadData()
        }
        self.trendView.setupUI()
        textView.resignFirstResponder()
        textView.inputView = textView.inputView == nil ? self.trendView : nil
        textView.becomeFirstResponder()
    }
    @objc private func selectUser() {
        userCollectionView.userListViewModel.loadFLFL(specialClass: .follow) { isSuccessful in
            Task { @MainActor in
                self.userCollectionView.collectionView.reloadData()
            }
        }
        self.userCollectionView.setupUI()
        textView.resignFirstResponder()
        textView.inputView = textView.inputView == nil ? userCollectionView : nil
        textView.becomeFirstResponder()
    }
    @objc private func selectEmoticon() {
        textView.resignFirstResponder()
        textView.inputView = textView.inputView == nil ? emoticonView : nil
        textView.becomeFirstResponder()
    }
    private lazy var placeHolderLabel: UILabel = UILabel(title: NSLocalizedString("分享新鲜事...", comment: ""),fontSize: 18,color: UIColor(white: 0.6, alpha: 1.0))
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
                guard let o = n.object as? UIAlertController else {
                    return
                }
                Task{@MainActor in
                    self.present(o, animated: true)
                }
            }
        }
        //automaticallyAdjustsScrollViewInsets = false
        prepare()
        prepareTool()
        prepareTextView()
        preparePicturePicker()
    }
    
    private func prepare() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("创建一个话题", comment: ""), style: .plain, target: self, action: #selector(self.createTrend))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("发布", comment: ""), style: .plain, target: self, action: #selector(self.sendStatus))
        navigationItem.leftBarButtonItem?.tintColor = .red
        navigationItem.rightBarButtonItem?.tintColor = .red
        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 36))
        navigationItem.titleView = titleView
        let titleLabel = UILabel(title: NSLocalizedString("写博客", comment: ""),fontSize: 15)
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
    @objc private func sendStatus(){
        let text = textView.emoticonText
        let image = picturesPickerController.pictures
        showInfo("加载中")
        if chat ?? false {
            finished?(text,image)
            self.dismiss(animated: true)
            return
        }
        NetworkTools.shared.sendStatus(status: text, comment_id: comment_id, id: id, image: image) { (Result, Error) -> () in
            if Error != nil {
                showError("您的网络不给力")
                return
            }
            self.textView.resignFirstResponder()
            self.dismiss(animated: true,completion: nil)
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
