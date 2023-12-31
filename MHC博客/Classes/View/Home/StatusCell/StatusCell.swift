//
//  StatusCell.swift
//  MHC微博
//
//  Created by Monkey hammer on 2022/9/11.
//

import UIKit

let StatusCellMargin: CGFloat = 12
let StatusCellIconWidth: CGFloat = 35
protocol StatusCellDelegate: NSObjectProtocol {
    func statusCellDidClickUrl(url:URL)
}
class StatusCell: UITableViewCell {
    weak var cellDelegate: StatusCellDelegate?
    lazy var pictureView: StatusPictureView = StatusPictureView()
    var viewModel: StatusViewModel? {
        didSet {
            let text = viewModel?.status.status ?? ""
            contentLabel.attributedText = EmoticonManager.sharedManager.emoticonText(string: text, font: contentLabel.font)
            topView.viewModel = viewModel
            pictureView.backgroundColor = .systemBackground
            pictureView.viewModel = viewModel
            pictureView.snp.updateConstraints { make in
                make.height.equalTo(pictureView.bounds.height)
                make.width.equalTo(pictureView.bounds.width)
            }
        }
    }
    lazy var topView: StatusCellTopView = StatusCellTopView()
    lazy var contentLabel: FFLabel = FFLabel(title: "微博正文", fontSize: 15, color: .label, screenInset: StatusCellMargin)
    lazy var bottomView: StatusCellBottomView = StatusCellBottomView()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        contentView.addSubview(bottomView)
        bottomView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(pictureView.snp.bottom).offset(StatusCellMargin)
            make.left.equalTo(contentView.snp.left)
            make.right.equalTo(contentView.snp.right)
            make.height.equalTo(44)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func rowHeight(_ vm: StatusViewModel) -> CGFloat {
        viewModel = vm
        contentView.layoutIfNeeded()
        return bottomView.frame.maxY
    }
}
extension StatusCell {
    @objc func setupUI() {
        contentView.addSubview(topView)
        contentView.addSubview(contentLabel)
        contentView.addSubview(pictureView)
        topView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(contentView.snp.top)
            make.left.equalTo(contentView.snp.left)
            make.right.equalTo(contentView.snp.right)
            make.height.equalTo(2 * StatusCellMargin + StatusCellIconWidth)
        }
        contentLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(topView.snp.bottom).offset(StatusCellMargin)
            make.left.equalTo(contentView.snp.left).offset(StatusCellMargin)
        }
        //pictureView.snp.makeConstraints { (make) -> Void in
            //make.top.equalTo(contentLabel.snp.bottom).offset(StatusCellMargin)
            //make.left.equalTo(contentLabel.snp.left)
            //make.width.equalTo(300)
            //make.height.equalTo(90)
        //}
        
        contentLabel.labelDelegate = self
    }
}
extension StatusCell: FFLabelDelegate {
    func labelDidSelectedLinkText(label: FFLabel, text: String) {
        if text.hasPrefix("http://") {
            guard let url = URL(string: text) else {
                return
            }
            cellDelegate?.statusCellDidClickUrl(url: url)
        }
        if text.hasPrefix("https://") {
            guard let url = URL(string: text) else {
                return
            }
            cellDelegate?.statusCellDidClickUrl(url: url)
        }
    }
}
