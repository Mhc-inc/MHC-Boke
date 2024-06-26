//
//  OAuthTableViewController.swift
//  MHC微博
//
//  Created by Monkey hammer on 2022/9/6.
//

import UIKit
@preconcurrency import WebKit
class OAuthViewController: UIViewController,WKNavigationDelegate {
    private lazy var webView = WKWebView()
    @objc private func close() {
        dismiss(animated: true,completion: nil)
    }
    @objc private func closeUserAgreement() {
        controller.dismiss(animated: true,completion: nil)
    }
#if os(visionOS)
override var preferredContainerBackgroundStyle: UIContainerBackgroundStyle {
    return .glass
}
#endif
    let controller = UIViewController()
    @objc private func userAgreement() {
        let textView = UITextView(frame: UIScreen.main.bounds)
        guard let userAgreement = Bundle.main.path(forResource: "用户协议", ofType: "txt") else {
            SVProgressHUD.showInfo(withStatus: NSLocalizedString("似乎找不到目录", comment: ""))
            return
        }
        do{
            let readStr:NSString=try NSString(contentsOfFile: userAgreement, encoding: String.Encoding.utf8.rawValue)
            textView.text = readStr as String
            textView.isEditable = false
            controller.view = textView
            controller.title = NSLocalizedString("用户协议",comment: "")
            controller.navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("关闭",comment: ""), style: .plain, target: self, action: #selector(OAuthViewController.closeUserAgreement))
            controller.navigationItem.leftBarButtonItem?.tintColor = .red
            present(UINavigationController(rootViewController: controller), animated: true)
        }catch _ {
        }
    }
    
    override func loadView() {
        view = webView
        webView.uiDelegate = self
        webView.navigationDelegate = self
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("关闭",comment: ""), style: .plain, target: self, action: #selector(OAuthViewController.close))
        navigationItem.leftBarButtonItem?.tintColor = .red
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("用户协议",comment: ""), style: .plain, target: self, action: #selector(OAuthViewController.userAgreement))
        navigationItem.rightBarButtonItem?.tintColor = .red
    }
    
    enum 登录方式: String {
        case 注册 = "注册"
        case 登录 = "登录"
    }
    convenience init(_ 方式: 登录方式) {
        self.init()
        if 方式.rawValue == "注册" {
            oauthURL = URL(string: NetworkTools.OAuthURL.注册.rawValue)
            title = NSLocalizedString("注册Mhc博客", comment: "")
        } else {
            oauthURL = URL(string: NetworkTools.OAuthURL.登陆.rawValue)
            title = NSLocalizedString("登录Mhc博客", comment: "")
        }
    }
    //默认注册
    var oauthURL = URL(string: rootHost+"/api/register.html"/*可以先提供一个错误的url，测试请使用http://localhost:9002/resource/register.html */)
    override func viewDidLoad() {
        super.viewDidLoad()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        webView.load(URLRequest(url: oauthURL!))
    }
    
    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
extension OAuthViewController {
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse) async -> WKNavigationResponsePolicy {
        guard let url = webView.url, url.host(percentEncoded: false) == "mhcincapi.top" else {
            print("problem1")
            return .allow
        }
        print("query",url.query)
        guard let query = url.query,query.contains("code=") else {
            print("problem2")
            return .allow
        }
        let code = String(query["code=".endIndex...])
        UserAccountViewModel.sharedUserAccount.loadAccessToken(code: code) { (isSuccessed) -> () in
            if !isSuccessed {
                return
            }
            self.dismiss(animated: false) {
                NotificationCenter.default.post(name: .init(rawValue: WBSwitchRootViewControllerNotification), object: "welcome")
            }
        }
        return .cancel
    }
}
extension OAuthViewController : WKUIDelegate{
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                    completionHandler()
                }))
                present(alertController, animated: true, completion: nil)
                print("dsf")
    }
}
