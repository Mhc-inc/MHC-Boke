//
//  StatusViewModel.swift
//  MHC微博
//
//  Created by Monkey hammer on 2022/9/11.
//

import UIKit

/// 微博视图模型 - 处理单条微博的业务逻辑
class CommentViewModel: CustomStringConvertible {
    var description: String {
        return "<CommentViewModel>"
    }
    
    
    /// 微博的模型
    var comment: Comment
    
    /// 用户头像 URL
    var userProfileUrl: URL {
        let 中文转换过的url = comment.portrait?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        return URL(string: 中文转换过的url ?? "")!
    }
    
    /// 用户默认头像
    var userDefaultIconView: UIImage {
        return UIImage(named: "avatar_default_big")!
    }
    lazy var rowHeight: CGFloat = {
        
        if self.comment.comment_list != nil {
            var cell = StatusCommentCell(style: .default, reuseIdentifier: CommentCellNormalId)
            return cell.rowHeight(self)
        } else {
            var cell = CommentCommentCell(style: .default, reuseIdentifier: CommentCommentCellNormalId)
            return cell.rowHeight(self)
        }
    }()
    var cellId: String {
        if self.comment.comment_list != nil {
            return CommentCellNormalId
        }
        return CommentCommentCellNormalId
    }
    /// 用户认证图标
    /// 认证类型，-1：没有认证，0，认证用户，2,3,5: 企业认证，220: 达人
    var createAt: String? {
        return Date.sina(comment.create_at ?? "")?.dateDescription
    }
    /// 缩略图URL数组 - 存储型属性 !!!
    
    /// 构造函数
    init(comment: Comment) {
        self.comment = comment
    }
}
