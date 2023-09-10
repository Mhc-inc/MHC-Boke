# MHC博客————一个简单的博客
# 1.0版本
**
首先这是一个运用了很多OC库的应用
所以导致Objective-C占比较多
也可以说基本全是Objective-C写的
（😁我写的占18.0%不到，因为还有SnapKit）
首先我们用SnapKit做出来了四个页面为登陆前的样子
配合资源，再加上SnapKit的约束，让画面非常好
但是听说上下转左右底下的TabBar会出现错误，
看有时间再改改吧
更新：曾经除了首页都不能刷新，现在都可以了
然后我做了一个"首页"的界面，可以自如刷新博客
而且之前的评论界面可以刷新并且显示，评论区或回复区可查看回复的博客或回复的评论
接着我做了一个"发现"的界面，可以自如刷新博客（之前发现了一个bug，点赞评不能显示，现在可以了）并搜索
接下来我做了一个"我"的界面，暂时只能显示一点，现在能改名啦，可以刷新
最后我做了一个"伙伴"的界面，可以自如刷新，点击头像可以添加好友，但也可以不经过对方同意，但也发不了消息，所以问题挺多的，我不准备做"发消息"的功能。
**

# 1.1版本

**
我们新更新了现象级的几个功能（将会商业化），
那就是我们的注册和登录分离了，
之前虽然也有注册，
但仔细点可以发现，
注册和登录用的是同一个页面
现在我们是分离的，并且注册和登录如果有冲突会被告知，
还有就是“我”界面可以看用户协议，开始直播，账号也支持退登，
直播列表则是在首页，
我们未测试多个人直播，
直播列表会产生什么效果我们暂不知道，
如有这bug可以叫我们修复
最后我做了一个"伙伴"的界面，可以自如刷新，点击头像可以添加好友，1.0版本对方看不到，但现在可以了，和1.0一样也可以不经过对方同意，但也发不了消息，所以问题挺多的，准备做"发消息"的功能，这几天在配置wss。
**
# 1.2版本

**
感觉会有挺多问题，因为服务端是将addLike和deleteLike给合并了，并且将提前做好的数组算法全删了，改成了创建表格与数据库，不过这样的话like使用起来还更方便了，如果有问题请提交到issue里，希望大家能够支持，博客现在点击头像不是添加好友了，是弹出资料卡也是一重点
webSocket交互可以成功了
可支持在线发消息，如发现按钮没反应说明对方不在线，离线发消息待更新
博客注销账号时可以将博客也给删除（您注销账号的所有博客）
**
# 1.3版本
**
修改了许多1.2版本更改api后的bug，例如评论区的like无法正常点击，并且全部视图改成了暗夜模式
1.4版本已定档，暂未更新超话
**
# 1.4版本
**
1.4使用小妙招：头像点击之后可以大图查看，添加好友单独成行
可查看别人点赞与评论过和自己点赞与评论过的博客（分别查看），但是目前暂不支持查看评论！
退出一秒后可查看最新微博，但是得刷新，会以通知形式出现
重归原始！（有点微博G3质感）目前一般暗夜模式开没开都是白昼模式，所以建议不要开，因为可能会看到奇怪的配色界面！！！
**
# 1.5版本
**
头像点击之后可以更换头像，要退出并删除后台哦
1.4的通知需要注册会员才可查看，没有的话可以运行时自行删除！！！
支持下拉刷新（之前超过十条博客将不会更新，如今是可以的，也就是下拉）
**
# 最后支持的点个Star，交流群vx加17758917010，记住备注（看得懂就行）
# 1.6版本
**
直播功能已经修复（升级面板丢失配置，所以是部署问题），聊天功能也修复了，这个版本也是一个大更新，修复了许多旧bug，例如我们的like多个博客点击会出现在不同博客上的点赞这种低级错误，目前也已修复，代码也开始学会了重用
以及点赞的时候不会刷新（大家都知道刷新有可能会出现新的博客，导致点赞的博客消失，特别是没点赞的，如果取消了点赞便不会找到，点赞的话至少能在“点赞过的博客”中找得到，还有评论或删除评论刷新之前也有可能会出现新的博客，导致评论的博客消失，特别是没评论的，如果删除了评论便不会找到，评论的话至少能在“评论过的博客”中找得到
“我”界面重新更新，以UINavigationLink为主，主页博客也少去了多余装饰，不用通知来获取点赞数可能会有点延迟，不过不用在意，并且发现界面之前被发现刚进去点击时会闪退，现在是没有的了！！！
**
# 1.7版本
**
解决了数据库部分更新的bug，并且更新了资源，若删除的话，会出现删除特效哦
**
# 最后支持的点个Star，交流群vx加17758917010，记住备注（看得懂就行）
# 1.8版本
**
解决了博客刷新的bug，比如在不同客户端上容易出现刷新多出好几个博客的问题，现在已解决，但是暂时还不能判断有没有人删除博客，退出之后会自动删除缓存。
并且现在可以有@列表与话题列表，创建话题等等，如要退出写博客界面，现在改成下拉即可退出！！！
**
# 1.8.2版本
**
其实还是1.8版本，但是之前是有问题的，就是不是自己的话题也可以删除，现在不可以了！
**
# 最后支持的点个Star，交流群vx加17758917010，记住备注（看得懂就行）
