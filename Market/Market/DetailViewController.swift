//
//  DetailViewController.swift
//  Market
//
//  Created by Dave Vo on 12/10/15.
//  Copyright © 2015 DaveVo. All rights reserved.
//

import UIKit
import AFNetworking
import AVKit
import AVFoundation

class DetailViewController: UIViewController {
    
    @IBOutlet weak var buttonsView: UIView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var voteButton: UIButton!
    @IBOutlet weak var chatButton: UIButton!
    @IBOutlet weak var voteButtonWidth: NSLayoutConstraint!
    @IBOutlet weak var chatButtonWidth: NSLayoutConstraint!
    
    @IBOutlet weak var dimmingView: UIView!
    @IBOutlet weak var dimmingViewHeight: NSLayoutConstraint!
    @IBOutlet weak var descriptionText: UITextView!
    @IBOutlet weak var textHeight: NSLayoutConstraint!
    @IBOutlet weak var descTextGap: NSLayoutConstraint!
    @IBOutlet weak var buttonsViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var sellerLabel: UILabel!
    @IBOutlet weak var updatedAtLabel: UILabel!
    @IBOutlet weak var itemNameLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var markerIcon: UIImageView!
    
    @IBOutlet weak var scrollCircle1: UIImageView!
    @IBOutlet weak var scrollCircle2: UIImageView!
    @IBOutlet weak var scrollCircle3: UIImageView!
    @IBOutlet weak var closeButton: UIButton!
    
    @IBOutlet weak var voteCountLabel: UILabel!
    @IBOutlet weak var voteLabel: UILabel!
    @IBOutlet var panGesture: UIPanGestureRecognizer!
    @IBOutlet var pinchGesture: UIPinchGestureRecognizer!
    @IBOutlet weak var titleView: UIView!
    @IBOutlet weak var soldView: UIView!
    @IBOutlet weak var newView: UIView!
    
    var post: Post!
    var isReadingFullDescription: Bool!
    var tapGesture: UITapGestureRecognizer!
    var selectedImage = 1
    var nImages: Int = 1
    var tempImageViews: [UIImageView]!
    var videoUrls = [NSURL?]()
    var playButton: UIButton!
    
    var imageOriginalCenter: CGPoint!
    var imageOriginalFrame: CGRect!
    var direction: CGFloat = 1.0
    var screenWidth: CGFloat!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        soldView.layer.cornerRadius = 5
        soldView.clipsToBounds = true
        soldView.hidden = !post.sold
        
        newView.layer.cornerRadius = 5
        newView.clipsToBounds = true
        newView.hidden = post.condition > 0
        
        // Do any additional setup after loading the view.
        itemNameLabel.text = post.title
        descriptionText.text = post.descriptionText
        descriptionText.selectable = false
        priceLabel.text = post.price.formatVND()
        
        if let locationName = post.locationName {
            locationLabel.text = locationName
            markerIcon.hidden = false
        } else {
            locationLabel.text = ""
            markerIcon.hidden = true
        }
        
        voteCountLabel.hidden = true
        voteLabel.hidden = true
        
        let titleTapGesture = UITapGestureRecognizer(target: self, action: "onTapTitle:")
        titleView.addGestureRecognizer(titleTapGesture)
        
        let formatter = NSDateFormatter()
        formatter.timeStyle = NSDateFormatterStyle.ShortStyle
        formatter.dateStyle = NSDateFormatterStyle.MediumStyle
        updatedAtLabel.text = "Posted on \(formatter.stringFromDate(post.createdAt!))"
        
        // Create the "padding" for the text
        descriptionText.textContainerInset = UIEdgeInsetsMake(8, 10, 0, 10)
        isReadingFullDescription = false
        
        // Just set the bg color's alpha
        // Don't set the view's alpha else the subView will inherit it
        buttonsView.layer.borderWidth = 0.5
        buttonsView.layer.borderColor = UIColor.grayColor().CGColor
        dimmingView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.0)
        
        tapGesture = UITapGestureRecognizer(target: self, action: "showMore:")
        view.addGestureRecognizer(tapGesture)
        
        // Load the seller
        post.user.fetchIfNeededInBackgroundWithBlock { (pfObj, error) -> Void in
            guard error == nil else {
                print(error)
                return
            }
            if let user = pfObj as? User {
                self.sellerLabel.text = user.fullName
                if let avatar = user.avatar {
                    self.avatarImageView.setImageWithURL(NSURL(string: avatar.url!)!)
                } else {
                    self.avatarImageView.noAvatar()
                }
            }
        }
        
        avatarImageView.layer.cornerRadius = 18
        avatarImageView.clipsToBounds = true
        closeButton.layer.cornerRadius = 12
        closeButton.clipsToBounds = true
        
        let avatarTapGesture = UITapGestureRecognizer(target: self, action: "tapOnProfile:")
        let sellerTapGesture = UITapGestureRecognizer(target: self, action: "tapOnProfile:")
        avatarImageView.addGestureRecognizer(avatarTapGesture)
        sellerLabel.addGestureRecognizer(sellerTapGesture)
        
        
        // Exclude the thumbnail
        nImages = post.medias.count / 2
        scrollCircle1.hidden = nImages < 2
        scrollCircle2.hidden = nImages < 2
        scrollCircle3.hidden = nImages < 3
        
        videoUrls = []
        for _ in 0..<nImages {
            videoUrls.append(nil)
        }
        
        // Load the thumbnail first for user to see while waiting for loading the full image
        imageView.loadThumbnailThenOriginal(post.medias[0].url!, originalURL: post.medias[1].url!)
        
        // Load images while user still reading 1st page
        tempImageViews = []
        // Refresh the layout before assign anything
        view.layoutIfNeeded()
        
        for i in 0..<nImages {
            let originalURL = post.medias[(i * 2) + 1].url!
            let thumbnailURL = post.medias[i * 2].url!
            let iv = UIImageView()
            iv.frame = imageView.frame
            // Add 20px for the status bar, if not show status bar, comment next 2 lines
            //iv.frame.origin.y += 20
            //iv.frame.size.height -= 20
            
            iv.center.x -= imageView.frame.width
            iv.contentMode = .ScaleAspectFit
            iv.clipsToBounds = true
            
            tempImageViews.append(iv)
            
            if (originalURL.rangeOfString("video.mov") != nil) {
                tempImageViews[i].setImageWithURL(NSURL(string: thumbnailURL)!)
                videoUrls[i] = NSURL(string: originalURL)
            } else {
                tempImageViews[i].loadThumbnailThenOriginal(thumbnailURL, originalURL: originalURL)
            }
            
            view.insertSubview(tempImageViews[i], aboveSubview: imageView)
        }
        
        // Set the buttons width equally
        screenWidth = UIScreen.mainScreen().bounds.width
        voteButtonWidth.constant = screenWidth / 3
        chatButtonWidth.constant = screenWidth / 3
        
        // Create shadow for text for easy reading
        descriptionText.layer.shadowColor = UIColor.blackColor().CGColor
        descriptionText.layer.shadowOffset = CGSizeMake(1.0, 1.0)
        descriptionText.layer.shadowOpacity = 1.0
        descriptionText.layer.shadowRadius = 1.0
        showDescription(UIScreen.mainScreen().bounds.height - 140, bgAlpha: 0.0, showFull: false)
        
        // Set the images scroll indicator
        setImageScroll(1)
        
        // Any posibility if will be nil here?
        if post.iSaveIt == nil {
            post.savedPostCurrentUser({ (saved, error) -> Void in
                self.post.iSaveIt = saved
                self.setSaveLabel(self.post.iSaveIt!)
            })
        } else {
            setSaveLabel(post.iSaveIt!)
        }
        if post.iVoteIt == nil {
            post.votedPostCurrentUser({ (voted, error) -> Void in
                self.post.iVoteIt = voted
                self.setVoteCountLabel(self.post.voteCounter, voted: self.post.iVoteIt!)
            })
        } else {
            setVoteCountLabel(post.voteCounter, voted: post.iVoteIt!)
        }
        // If this is my post then not allow to vote/chat/save
        buttonsView.hidden = post.user.objectId == User.currentUser()?.objectId
        
        addPlayButton()
    }
    
    func onTapTitle(gesture: UITapGestureRecognizer) {
        onCancel(nil)
        
    }
    
    func tapOnProfile(gesture: UITapGestureRecognizer) {
        if let currentUser = User.currentUser() where currentUser.objectId != post.user.objectId {
            let profileVC = UserTimelineViewController.instantiateViewController
            profileVC.user = post.user
            presentViewController(profileVC, animated: true, completion: nil)
        }
    }
    
    func addPlayButton() {
        playButton = UIButton(frame: CGRect(x: (imageView.frame.size.width - 50) / 2, y: (imageView.frame.size.height - 50) / 2, width: 50, height: 50))
        playButton.layer.backgroundColor = UIColor.clearColor().CGColor
        playButton.setImage(UIImage(named: "play"), forState: UIControlState.Normal)
        playButton.addTarget(self, action: "showVideoPlayer", forControlEvents: UIControlEvents.TouchUpInside)
        // If video is at first, show the playButton immediatelly
        playButton.hidden = videoUrls[0] == nil
        imageView.addSubview(playButton)
    }
    
    func showVideoPlayer() {
        performSegueWithIdentifier("videoSegue", sender: self)
    }
    
    func setImageScroll(selected: Int) {
        scrollCircle1.layer.cornerRadius = 4
        scrollCircle1.clipsToBounds = true
        scrollCircle2.layer.cornerRadius = 4
        scrollCircle2.clipsToBounds = true
        scrollCircle3.layer.cornerRadius = 4
        scrollCircle3.clipsToBounds = true
        
        switch selected {
        case 1:
            scrollCircle1.backgroundColor = MyColors.bluesky
            scrollCircle2.backgroundColor = UIColor.lightGrayColor()
            scrollCircle3.backgroundColor = UIColor.lightGrayColor()
        case 2:
            scrollCircle1.backgroundColor = UIColor.lightGrayColor()
            scrollCircle2.backgroundColor = MyColors.bluesky
            scrollCircle3.backgroundColor = UIColor.lightGrayColor()
        case 3:
            scrollCircle1.backgroundColor = UIColor.lightGrayColor()
            scrollCircle2.backgroundColor = UIColor.lightGrayColor()
            scrollCircle3.backgroundColor = MyColors.bluesky
        default:
            break
        }
    }
    
    func showMore(gesture: UITapGestureRecognizer) {
        if gesture.state == UIGestureRecognizerState.Ended {
            let tapLocation = gesture.locationInView(self.view)
            if (tapLocation.y >= dimmingView.frame.origin.y) && (tapLocation.y <= buttonsView.frame.origin.y) {
                if !isReadingFullDescription {
                    isReadingFullDescription = true
                    //descTextGap.constant = 25
                    showDescription(54, bgAlpha: 0.9, showFull: true)
                    
                } else {
                    isReadingFullDescription = false
                    //descTextGap.constant = 5
                    showDescription(UIScreen.mainScreen().bounds.height - 140, bgAlpha: 0.0, showFull: false)
                }
            }
        }
    }
    
    @IBAction func onPanImage(sender: UIPanGestureRecognizer) {
        let translation = sender.translationInView(view)
        let point = sender.locationInView(imageView)
        
        if sender.state == .Began {
            imageOriginalCenter = imageView.center
            imageOriginalFrame = imageView.frame
            direction = point.y > imageView.frame.height/2 ? -0.15 : 0.15
            //            print("image view frame", imageView.frame)
            
        } else if sender.state == .Changed {
            imageView.center = CGPoint(x: imageOriginalCenter.x + translation.x, y: imageOriginalCenter.y + translation.y)
            imageView.transform = CGAffineTransformMakeRotation((direction * translation.x * CGFloat(M_PI)) / 180.0)
            
        } else if sender.state == .Ended {
            if translation.y > 100 || translation.y < -100 {
                dismissViewControllerAnimated(true, completion: nil)
            } else {
                // If only 1 image then return it to original position
                if nImages < 2 {
                    UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 10, options: [], animations: { () -> Void in
                        self.imageView.center = self.imageOriginalCenter
                        self.imageView.transform = CGAffineTransformMakeRotation(0)
                        }, completion: nil)
                } else {
                    if translation.x > 80 {
                        selectedImage -= 1
                        if selectedImage < 1 {
                            selectedImage = nImages
                        }
                        //print("loading image \(selectedImage)")
                        tempImageViews[selectedImage-1].alpha = 0
                        tempImageViews[selectedImage-1].center.x = -imageOriginalCenter.x
                        
                        UIView.animateWithDuration(0.5, animations: { () -> Void in
                            self.imageView.alpha = 0
                            self.tempImageViews[self.selectedImage-1].alpha = 1
                            self.imageView.center.x += self.imageView.frame.width
                            self.tempImageViews[self.selectedImage-1].center = self.imageOriginalCenter
                            }, completion: { (finished) -> Void in
                                self.imageView.alpha = 1
                                self.imageView.center = self.imageOriginalCenter
                                self.imageView.transform = CGAffineTransformMakeRotation(0)
                                self.setImageScroll(self.selectedImage)
                                self.imageView.image = self.tempImageViews[self.selectedImage-1].image
                                self.tempImageViews[self.selectedImage-1].center.x = -self.imageOriginalCenter.x
                                
                                self.playButton.hidden = self.videoUrls[self.selectedImage - 1] == nil
                        })
                        
                    } else if translation.x < -80 {
                        selectedImage += 1
                        if selectedImage > nImages {
                            selectedImage = 1
                        }
                        print("loading image \(selectedImage)")
                        tempImageViews[selectedImage-1].alpha = 0
                        tempImageViews[selectedImage-1].center.x = imageView.frame.width + imageOriginalCenter.x
                        
                        UIView.animateWithDuration(0.5, animations: { () -> Void in
                            self.imageView.alpha = 0
                            self.tempImageViews[self.selectedImage-1].alpha = 1
                            self.imageView.center.x -= self.imageView.frame.width
                            self.tempImageViews[self.selectedImage-1].center = self.imageOriginalCenter
                            }, completion: { (finished) -> Void in
                                self.imageView.alpha = 1
                                self.imageView.center = self.imageOriginalCenter
                                self.imageView.transform = CGAffineTransformMakeRotation(0)
                                self.setImageScroll(self.selectedImage)
                                self.imageView.image = self.tempImageViews[self.selectedImage-1].image
                                self.tempImageViews[self.selectedImage-1].center.x = self.imageView.frame.width + self.imageOriginalCenter.x
                                
                                self.playButton.hidden = self.videoUrls[self.selectedImage - 1] == nil
                        })
                        
                    } else {
                        UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 10, options: [], animations: { () -> Void in
                            self.imageView.center = self.imageOriginalCenter
                            self.imageView.transform = CGAffineTransformMakeRotation(0)
                            }, completion: nil)
                    }
                }
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if let nextVC = segue.destinationViewController as? VideoViewController {
            nextVC.videoUrl = videoUrls[selectedImage - 1]
        } else if let nextVC = segue.destinationViewController as? FullImageViewController {
            let data = sender as! UIImage
            nextVC.image = data
        }
    }
    
    @IBAction func onZoomImage(sender: UIPinchGestureRecognizer) {
        if sender.state == .Began {
            
        } else if sender.state == .Changed {
            
        } else if sender.state == .Ended {
            
        }
    }
    
    @IBAction func onDoubleTap(sender: UITapGestureRecognizer) {
        if let videoURL = videoUrls[selectedImage - 1] {
            performSegueWithIdentifier("videoSegue", sender: videoURL)
        } else {
            performSegueWithIdentifier("fullImageSegue", sender: imageView.image)
        }
        
    }
    
    func showDescription(y: CGFloat, bgAlpha: CGFloat, showFull: Bool) {
        let dimmingHeight = UIScreen.mainScreen().bounds.height - y - 40
        if showFull {
            dimmingViewHeight.constant = dimmingHeight
            view.layoutIfNeeded()
        }
        
        // The size of the textView to fit its content
        let newSize = descriptionText.sizeThatFits(CGSize(width: screenWidth - 20, height: CGFloat.max))
        //        print(newSize)
        
        textHeight.constant = min(dimmingHeight - 8, newSize.height)
        descTextGap.constant = showFull ? 25 : 5
        
        UIView.animateWithDuration(0.4, animations: { () -> Void in
            self.avatarImageView.alpha = bgAlpha
            self.sellerLabel.alpha = bgAlpha
            self.updatedAtLabel.alpha = bgAlpha
            self.dimmingView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: bgAlpha)
            self.view.layoutIfNeeded()
            
            }) { (finished) -> Void in
                // If not showing full description, only reduce the size of dimming view after change the alpha
                if !showFull {
                    self.dimmingViewHeight.constant = dimmingHeight
                    self.view.layoutIfNeeded()
                }
        }
    }
    
    @IBAction func onCancel(sender: UIButton?) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func onSaveTapped(sender: UIButton) {
        if sender.imageView?.image == UIImage(named: "save_on") {
            // Un-save it
            setSaveLabel(false)
            post.save(false) { (successful: Bool, error: NSError?) -> Void in
                if successful {
                    print("unsaved")
                    self.post.iSaveIt = false
                } else {
                    print("failed to unsave")
                    self.setSaveLabel(true)
                }
            }
            
        } else {
            // Save it
            setSaveLabel(true)
            post.save(true) { (successful: Bool, error: NSError?) -> Void in
                if successful {
                    print("saved")
                    self.post.iSaveIt = true
                } else {
                    print("failed to save")
                    self.setSaveLabel(false)
                }
            }
        }
    }
    
    @IBAction func onVoteTapped(sender: UIButton) {
        if sender.imageView?.image == UIImage(named: "thumb_on") {
            // Un-vote it
            let count = Int(self.voteCountLabel.text!)! - 1
            setVoteCountLabel(count, voted: false)
            post.vote(false) { (successful: Bool, error: NSError?) -> Void in
                if successful {
                    print("unvoted")
                    self.post.iVoteIt = false
                } else {
                    print("failed to unvote")
                    self.setVoteCountLabel(count + 1, voted: true)
                }
            }
            
        } else {
            // Vote it
            let count = Int(self.voteCountLabel.text!)! + 1
            setVoteCountLabel(count, voted: true)
            post.vote(true) { (successful: Bool, error: NSError?) -> Void in
                if successful {
                    print("voted")
                    self.post.iVoteIt = true
                } else {
                    print("failed to vote")
                    self.setVoteCountLabel(count - 1, voted: false)
                }
            }
        }
    }
    
    @IBAction func onMessage(sender: UIButton) {
        ParentChatViewController.show(self.post, fromUser: User.currentUser()!, toUser: self.post.user)
    }
}

extension DetailViewController {
    func setSaveLabel(saved: Bool) {
        if saved {
            saveButton.setImage(UIImage(named: "save_on"), forState: .Normal)
            saveButton.setTitleColor(MyColors.green, forState: .Normal)
        } else {
            saveButton.setImage(UIImage(named: "save_white"), forState: .Normal)
            saveButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        }
    }
    
    func setVoteCountLabel(count: Int, voted: Bool) {
        if voted {
            voteButton.setImage(UIImage(named: "thumb_on"), forState: .Normal)
            voteButton.setTitleColor(MyColors.green, forState: .Normal)
        } else {
            voteButton.setImage(UIImage(named: "thumb_white"), forState: .Normal)
            voteButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        }
        voteCountLabel.text = "\(count)"
        voteCountLabel.hidden = !(count > 0)
        voteLabel.hidden = !(count > 0)
    }
}

// MARK: Show view from anywhere
extension DetailViewController {
    static var instantiateViewController: DetailViewController {
        return StoryboardInstance.home.instantiateViewControllerWithIdentifier(StoryboardID.postDetail) as! DetailViewController
    }
}