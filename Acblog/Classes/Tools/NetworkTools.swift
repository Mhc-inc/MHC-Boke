//
//  NetworkTools.swift
//  AC博客
//
//  Created by AC on 2022/9/8.
//

import Foundation
import UIKit

final class NetworkTools: Sendable{
    private let networkQueue = DispatchQueue(label: "com.ACInc.network", qos: .default)
    static let shared: NetworkTools = {
        let tools = NetworkTools()
        return tools
    }()
    var tokenDict: [String: Any]? {
        if let token = UserAccountViewModel.sharedUserAccount.accessToken {
            return ["access_token": token]
        }
        return nil
    }
    enum HMRequestMethod: String {
        case GET = "GET"
        case POST = "POST"
    }
    typealias HMRequestCallBack = @Sendable @MainActor (_ Result: Any?, _ Error: Error?) -> ()
}
extension NetworkTools {
    func request(_ method: HMRequestMethod, _ URLString: String, _ parameters: [String: Any]?, finished: @escaping HMRequestCallBack) {
        guard let parameters = parameters else {
            Task{@MainActor in
                finished(nil, NSError(domain: "com.ACInc", code: 1, userInfo: ["error": "your parameters were nil"]))
            }
            return
        }
        let parameterString = parameters.map { (key, value) -> String in
            return "\(key)=\(value)"
        }.joined(separator: "&")
        networkQueue.async {
            
            var str = URLString
            if method.rawValue == "GET" {
                str += "?" + parameterString
            }
            guard let url = URL(string: str) else {
                Task {@MainActor in
                    finished(nil, NSError(domain: "com.ACInc", code: 1, userInfo: ["error": "your url cannot be found"]))
                }
                return
            }
            var request = URLRequest(url: url)
            if method.rawValue == "POST" {
                let jsonData = parameterString.data(using: .utf8)
                request.httpBody = jsonData  // 设置HTTPBody
            }
            request.httpMethod = method.rawValue
            let completion = { @Sendable @MainActor (data: Data?, res: URLResponse?, error: (any Error)?)->Void in
                if let any = try? JSONSerialization.jsonObject(with: data ?? Data(), options: .allowFragments) {
                    if let dict = any as? NSArray {
                        finished(dict,error)
                    }
                    if let dict = any as? [String: Any] {
                        finished(dict,error)
                    }
                    return
                }
                finished(data,error)
            }
            let task = URLSession.shared.dataTask(with: request) { data, request, error in
                Task{@MainActor in
                    completion(data,request,error)
                }
            }
            task.resume()
        }
    }
    func loadAccessToken(code: String, finished: @escaping HMRequestCallBack) {
        let urlString = rootHost+"/api/accessToken.php"
        let params = ["code":code]
        request(.POST, urlString, params, finished: finished)
    }
    func isLived(finished: @escaping HMRequestCallBack) {
        let urlString = rootHost+"/api/isLived.php"
        tokenRequest(.POST, urlString, nil, finished: finished)
    }
}
extension NetworkTools {
    func loadUserInfo(finished: @escaping HMRequestCallBack) {
        let urlString = rootHost+"/api/getUser.php"
        tokenRequest(.POST, urlString, nil, finished: finished)
    }
    func loadUserInfo(uid:Int, finished: @escaping HMRequestCallBack) {
        let params = ["uid":uid]
        let urlString = rootHost+"/api/getUserUid.php"
        request(.POST, urlString, params, finished: finished)
    }
    func trend(_ trend:String? = nil, finished: @escaping HMRequestCallBack) {
        var params = [String:Any]()
        let urlString = rootHost+"/api/trend.php"
        guard let trend = trend else {
            //print(params)
            tokenRequest(.GET, urlString, params, finished: finished)
            return
        }
        params["trend"] = trend
        tokenRequest(.GET, urlString, params, finished: finished)
    }
    func deleteTrend(_ trend:String, finished: @escaping HMRequestCallBack) {
        let params = ["trend":trend]
        let urlString = rootHost+"/api/deleteTrend.php"
        tokenRequest(.GET, urlString, params as [String : Any], finished: finished)
    }
    func search(status:String, finished: @escaping HMRequestCallBack) {
        let params = ["status":status]
        let urlString = rootHost+"/api/search.php"
        tokenRequest(.POST, urlString, params, finished: finished)
    }
}
extension NetworkTools {
    func loadStatus(max_id: Int,since_id:Int,finished: @escaping HMRequestCallBack) {
        let urlString = rootHost+"/api/loadBlog.php"
        var params = [String:Any]()
        if since_id > 0{
            params["since_id"] = since_id
        } else if max_id > 0{
            params["max_id"] = max_id
        }
        tokenRequest(.GET, urlString, params, finished: finished)
    }
    func profile(uid: String,finished: @escaping HMRequestCallBack) {
        let urlString = rootHost+"/api/profileBlog.php"
        let params = ["uid":uid]
        request(.GET, urlString, params, finished: finished)
    }
    func loadOneStatus(id: Int,finished: @escaping HMRequestCallBack) {
        let urlString = rootHost+"/api/loadBlogOfId.php"
        let params = ["id":id]
        tokenRequest(.POST, urlString, params, finished: finished)
    }
    func loadHotStatus(finished: @escaping HMRequestCallBack) {
        let urlString = rootHost+"/api/loadHotBlog.php"
        tokenRequest(.POST, urlString,nil, finished: finished)
    }
    func loadLikeStatus(_ uid: String,finished: @escaping HMRequestCallBack) {
        let urlString = rootHost+"/api/loadLikeBlog.php"
        var params = [String:Any]()
        params["uid"] = uid
        request(.POST, urlString, params, finished: finished)
    }
    func loadCommentStatus(_ uid: String,finished: @escaping HMRequestCallBack) {
        let urlString = rootHost+"/api/loadCommentBlog.php"
        var params = [String:Any]()
        params["uid"] = uid
        request(.POST, urlString, params, finished: finished)
    }
    func loadFLFL(finished: @escaping HMRequestCallBack, _ uid: String? = nil, specialClass: SpecialClass) {
        var urlString = rootHost+"/api/"
        var type: HMRequestMethod = .POST
        if specialClass == .friend {
            urlString += "friends"
        } else if specialClass == .fans {
            urlString += "fans"
        } else if specialClass == .follow {
            urlString += "follow"
        } else if specialClass == .live {
            urlString += "loadLive"
            type = .GET
        }
        urlString += ".php"
        tokenRequest(type, urlString, uid != nil ? ["uid": uid!] : nil, finished: finished)
    }
    func rename(rename: String,finished: @escaping HMRequestCallBack) {
        var params = [String: Any]()
        params["rename"] = rename
        let urlString = rootHost+"/api/rename.php"
        tokenRequest(.POST, urlString, params, finished: finished)
    }
    func tokenIsExpires(finished: @escaping HMRequestCallBack) {
        let urlString = rootHost+"/api/accessTokenIsExpires.php"
        tokenRequest(.POST, urlString, nil, finished: finished)
    }
    func ExpiresTheToken(finished: @escaping HMRequestCallBack) {
        let urlString = rootHost+"/api/expiresToken.php"
        tokenRequest(.POST, urlString, nil, finished: finished)
    }
    func logOff(finished: @escaping HMRequestCallBack) {
        let urlString = rootHost+"/api/logOff.php"
        tokenRequest(.POST, urlString, nil, finished: finished)
    }
    func addFriend(_ to_uid: String,finished: @escaping HMRequestCallBack) {
        var params = [String: Any]()
        params["to_uid"] = to_uid
        let urlString = rootHost+"/api/addFriend.php"
        tokenRequest(.POST, urlString, params, finished: finished)
    }
    func deleteStatus(_ comment_id: Int?,_ comment_comment_id: Int?,_ id: Int,finished: @escaping HMRequestCallBack) {
        var params: [String: Any] = ["id": id]
        if(comment_id != nil) {
            params["comment_id"] = comment_id
            if comment_comment_id != nil {
                params["to_comment_id"] = comment_id
                params["comment_id"] = comment_comment_id
            }
        }
        let urlString = rootHost+"/api/deleteBlog.php"
        tokenRequest(.POST, urlString, params, finished: finished)
    }
    func like(_ id: Int,comment_id comment_comment_id: Int? = nil,_ comment_id: Int? = nil,_ finished: @escaping HMRequestCallBack) {
        var params: [String: Any] = ["id": id]
        params["like_uid"] = UserAccountViewModel.sharedUserAccount.account!.uid!
        if comment_id != nil {
            params["like_comment_id"] = comment_id
        }
        if comment_comment_id != nil {
            params["to_comment_id"] = comment_comment_id
        }
        let urlString = rootHost+"/api/like.php"
        tokenRequest(.POST, urlString, params, finished: finished)
    }
    func tokenRequest(_ method: HMRequestMethod, _ URLString: String, _ parameters: [String: Any]?, finished: @escaping HMRequestCallBack) {
        guard let params = tokenDict else {
            Task {@MainActor in
                finished(nil, NSError(domain: "cn.itcast.error", code: -1001, userInfo: ["message": "token为空"]))
            }
            return
        }
        var parameters = parameters
        if parameters == nil {
            parameters = [String: Any]()
        }
        parameters!["access_token"] = params["access_token"]
        request(method, URLString, parameters, finished: finished)
    }
}
extension NetworkTools {
    func sendStatus(status: String,comment_id: Int?,id: Int?,image: [UIImage], finished: @escaping HMRequestCallBack) {
        // 1. 创建参数字典
        var params = [String: Any]()
        // 2. 设置参数
        let urlString = rootHost+"/api/upload.php"
        if let id = id{
            if comment_id != nil {
                params["comment_id"] = comment_id
            }
            params["id"] = id
            params["comment"] = status
        } else {
            params["status"] = status
        }
        var data: [Data] = []
        for i in image {
            data.append(i.data()!)
        }
        upload(urlString, data, params,finished: finished)
    }
    func sendPortrait(image: UIImage?, finished: @escaping HMRequestCallBack) {
        // 2. 设置参数
        let urlString = rootHost+"/api/portrait.php"
        uploadImage(urlString, ["pic": image!.jpegData(compressionQuality: 0.8)!], nil, finished: finished)
    }
    private func upload(_ URLString: String, _ data: [Data], _ parameters: [String:Any]?, finished: @escaping HMRequestCallBack) {
        var datas = [String: Data]()
        for d in 0..<data.count {
            let filename = "pic{number}".replacingOccurrences(of: "{number}", with: String(d))
            datas[filename] = data[d]
        }
        uploadImage(URLString, datas, parameters, finished: finished)
    }
    func uploadImage(_ URLString: String, _ data: [String: Data], _ parameters: [String: Any]?, finished: @escaping HMRequestCallBack) {
        guard let params = tokenDict, let url = URL(string:URLString) else {
            Task {@MainActor in
                finished(nil, NSError(domain: "cn.itcast.error", code: -1001, userInfo: ["message": "token 为空"]))
            }
            return
        }
        var parameters = parameters
        if parameters == nil {
            parameters = [String:Any]()
        }
        parameters!["access_token"] = params["access_token"]
        guard let parameters = parameters else {
            return
        }
        let completion =
        { @Sendable (data: Data?, res: URLResponse?, error: (any Error)?)->Void in
            Task { @MainActor in
                finished(data,error)
            }
        }
        var request = URLRequest(url: url)
        var multipartData = Data()
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        for(key,value) in parameters {
            multipartData.append("--\(boundary)\r\n".data(using: .utf8)!)
            multipartData.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            multipartData.append("\(value)".data(using: .utf8)!)
            multipartData.append("\r\n".data(using: .utf8)!)
        }
        for (key,value) in data {
            
            let contentType = value.detectImageType().0.rawValue
            // 添加分隔符
            multipartData.append("--\(boundary)\r\n".data(using: .utf8)!)
            // 添加文件头部
            multipartData.append("Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(key)\"\r\n".data(using: .utf8)!)
            multipartData.append("Content-Type: \(contentType)\r\n\r\n".data(using: .utf8)!)
            // 添加文件数据
            multipartData.append(value)
            // 添加新行
            multipartData.append("\r\n".data(using: .utf8)!)
        }
        multipartData.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpMethod = "POST"
        request.httpBody = multipartData
        let task = URLSession.shared.dataTask(with: request, completionHandler: completion)
        task.resume()
    }
}
