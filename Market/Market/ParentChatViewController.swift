//
//  ParentChatViewController.swift
//  Market
//
//  Created by Ngo Thanh Tai on 12/21/15.
//  Copyright © 2015 MDT Group. All rights reserved.
//

import UIKit
import MBProgressHUD
import Parse

class ParentChatViewController: UIViewController {
    
    @IBOutlet weak var itemImageView: UIImageView!
    @IBOutlet weak var itemNameLabel: UILabel!
    @IBOutlet weak var timeAgoLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var sellerLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var newTagImageView: UIImageView!
    @IBOutlet weak var postView: UIView!
    @IBOutlet weak var profileView: UIView!
    @IBOutlet weak var postContentView: UIView!
    
    static var openDirectly = false
    
    var tapGesture: UITapGestureRecognizer!
    var conversation: Conversation!
    
    func initControls() {
        avatarImageView.layer.cornerRadius = 10
        avatarImageView.clipsToBounds = true
        itemImageView.layer.cornerRadius = 8
        itemImageView.clipsToBounds = true
        
        let tapPostGesture = UITapGestureRecognizer(target: self, action: "onTapPost:")
        postView.addGestureRecognizer(tapPostGesture)
        conversation.post.fetchIfNeededInBackgroundWithBlock { (post, error) -> Void in
            if let post = post as? Post {
                post.user.fetchIfNeededInBackgroundWithBlock { (user, error) -> Void in
                    if let currentUser = User.currentUser(), user = user as? User where user.objectId != currentUser.objectId {
                        let tapProfileGesture = UITapGestureRecognizer(target: self, action: "onTapProfile:")
                        self.profileView.addGestureRecognizer(tapProfileGesture)
                    }
                }
            }
        }
    }
    
    func onTapProfile(gesture: UITapGestureRecognizer) {
        let userTimelineVC = UserTimelineViewController.instantiateViewController
        userTimelineVC.user = conversation.post.user
        presentViewController(userTimelineVC, animated: true, completion: nil)
    }
    
    func onTapPost(gesture: UITapGestureRecognizer) {
        let detailVC = DetailViewController.instantiateViewController
        detailVC.post = conversation.post
        presentViewController(detailVC, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initControls()
        loadPost()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        ParentChatViewController.openDirectly = false
    }
    
    func loadPost() {
        conversation.post.fetchIfNeededInBackgroundWithBlock { (post, error) -> Void in
            if let post = post as? Post {
                self.sellerLabel.text = ""
                post.user.fetchIfNeededInBackgroundWithBlock { (result, error) -> Void in
                    if let avatar = post.user.avatar, url = avatar.url {
                        self.avatarImageView.setImageWithURL(NSURL(string: url)!)
                    } else {
                        self.avatarImageView.noAvatar()
                    }
                    self.sellerLabel.text = post.user.fullName
                }
                
                if post.medias.count > 0 {
                    self.itemImageView.setImageWithURL(NSURL(string: post.medias[0].url!)!)
                }
                
                self.itemNameLabel.text = post.title
                self.timeAgoLabel.text = Helper.timeSinceDateToNow(post.updatedAt!)
                self.priceLabel.text = post.price.formatVND()
                self.newTagImageView.hidden = post.condition > 0
//                if let navController = self.navigationController, messageVC = navController.viewControllers[navController.viewControllers.count - 2] as? MessageViewController {
//                    messageVC.title = post.title
//                }
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let chatVC = segue.destinationViewController as? ChatViewController {
            chatVC.conversation = conversation
        }
    }
    
    override func willMoveToParentViewController(parent: UIViewController?) {
        if parent == nil {
            if let navController = navigationController {
                for vc in navController.viewControllers {
                    if let messageVC = vc as? MessageViewController {
//                        messageVC.title = conversation.post.title
                        messageVC.post = conversation.post
                        
                        break
                    }
                }
            }
        }
    }
}

extension ParentChatViewController {
    static func show(post: Post, fromUser: User, toUser: User) {
        if fromUser.objectId == toUser.objectId {
            print("Cannot chat yourself")
            return
        }
        
        if let tabBarController = UIApplication.sharedApplication().delegate?.window??.rootViewController as? UITabBarController {
            
            var visibleVC: UIViewController?
            var view = tabBarController.view
            if let navController = tabBarController.selectedViewController as? UINavigationController,
                visibleViewController = navController.visibleViewController {
                    visibleVC = visibleViewController
                    view = visibleViewController.view
            }
            // if is curr1ent Chat screen, no need to push
            if let parentChatVC = visibleVC as? ParentChatViewController where parentChatVC.conversation.post.objectId == post.objectId &&
                parentChatVC.conversation.userIds.contains(fromUser.objectId!) &&
                parentChatVC.conversation.userIds.contains(toUser.objectId!) {
                    return
            }
            
            if let messageVC = StoryboardInstance.messages.instantiateViewControllerWithIdentifier(StoryboardID.messageViewController) as? MessageViewController,
                parentChatVC = StoryboardInstance.messages.instantiateViewControllerWithIdentifier(StoryboardID.chatViewController) as? ParentChatViewController {
                    
                    let hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
                    hud.applyCustomTheme("Opening chat...")
                    Conversation.addConversation(fromUser, toUser: toUser, post: post, callback: { (conversation, error) -> Void in
                        guard error == nil else {
                            hud.hide(true)
                            print(error)
                            return
                        }
                        let rootVC = UIApplication.sharedApplication().delegate?.window!!.rootViewController
                        rootVC?.dismissViewControllerAnimated(false, completion: nil)
                        if let conversation = conversation {
                            ParentChatViewController.openDirectly = true
                            tabBarController.selectedIndex = 1
                            messageVC.post = conversation.post
                            parentChatVC.conversation = conversation
                            PFObject.fetchAllIfNeededInBackground([fromUser, toUser, parentChatVC.conversation.post], block: { (users, error) -> Void in
                                guard error == nil else {
                                    print(error)
                                    return
                                }
                                
                                if let currentUser = User.currentUser() where currentUser.objectId == toUser.objectId {
                                    parentChatVC.title = fromUser.fullName
                                }
                                else {
                                    parentChatVC.title = toUser.fullName
                                }
                                
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    hud.hide(true)
                                    if let navController = tabBarController.selectedViewController as? UINavigationController {
                                        navController.popToRootViewControllerAnimated(false)
                                        if parentChatVC.conversation.post.user.objectId == User.currentUser()!.objectId {
                                            navController.pushViewController(messageVC, animated: false)
                                        }
                                        navController.pushViewController(parentChatVC, animated: false)
                                    }
                                })
                            })
                        } else {
                            hud.hide(true)
                        }
                    })
            }
        }
    }
}