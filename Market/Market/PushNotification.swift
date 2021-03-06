//
//  PushNotification.swift
//  Market
//
//  Created by Ngo Thanh Tai on 12/23/15.
//  Copyright © 2015 MDT Group. All rights reserved.
//

import Foundation
import MBProgressHUD

class PushNotification {
    static func handlePayload(application: UIApplication, userInfo: [NSObject : AnyObject]) {
        // Notifications
        let rootViewController = application.delegate?.window??.rootViewController
        if let postId = userInfo["postId"] as? String {
            if application.applicationState == .Inactive {
                let hud = MBProgressHUD.showHUDAddedTo(rootViewController?.view, animated: true)
                hud.applyCustomTheme("Loading post...")
                let post = Post(withoutDataWithObjectId: postId)
                
                post.fetchInBackgroundWithBlock({ (result, error) -> Void in
                    hud.hide(true)
                    guard error == nil else {
                        print(error)
                        return
                    }
                    if let result = result as? Post {
                        let vc = DetailViewController.instantiateViewController
                        vc.post = result
                        rootViewController?.presentViewController(vc, animated: true, completion: nil)
                        
                        if let notificationId = userInfo["notificationId"] as? String {
                            Notification.markRead(notificationId)
                        }
                    }
                })
            } else {
                NSNotificationCenter.defaultCenter().postNotificationName(TabBarController.newNotification, object: nil)
            }
        // Messages
        } else if let messageInfo = userInfo["message"] as? NSDictionary,
            postId = messageInfo["postId"] as? String,
            fromUserId = messageInfo["fromUserId"] as? String,
            toUserId = messageInfo["toUserId"] as? String {
            if application.applicationState == .Inactive {
                let hud = MBProgressHUD.showHUDAddedTo(rootViewController?.view, animated: true)
                hud.applyCustomTheme("Opening chat...")
                
                let post = Post(withoutDataWithObjectId: postId)
                post.fetchInBackgroundWithBlock({ (post, error) -> Void in
                    hud.hide(true)
                    guard error == nil else {
                        print(error)
                        return
                    }
                    if let post = post as? Post {
                        let fromUser = User(withoutDataWithObjectId: fromUserId)
                        let toUser = User(withoutDataWithObjectId: toUserId)
                       
                        ParentChatViewController.show(post, fromUser: fromUser, toUser: toUser)
                    }
                })
            } else {
                NSNotificationCenter.defaultCenter().postNotificationName(TabBarController.newMessage, object: nil)
            }
        }
    }
}