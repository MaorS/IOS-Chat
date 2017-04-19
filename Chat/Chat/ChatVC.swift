//
//  ChatVC.swift
//  Chat
//
//  Created by Maor Shams on 10/04/2017.
//  Copyright © 2017 Maor Shams. All rights reserved.
//

import UIKit
import AVKit
import MobileCoreServices
import JSQMessagesViewController
import Kingfisher

class ChatVC: JSQMessagesViewController, MessageReceivedDelegate {
    
    private var messages: [MSMessage] = [MSMessage]()
    weak var refreshControl : UIRefreshControl?
    var selectedImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // delegate
        MessagesManager.manager.delegate = self
        
        // set id & name for JSQMessagesViewController
        self.senderId = AuthManager.User.id.value
        self.senderDisplayName = AuthManager.User.name.value
        
        
        
        // Add delete UIMenuItem
        JSQMessagesCollectionViewCell.registerMenuAction(#selector(delete(_:)))
        UIMenuController.shared.menuItems = [UIMenuItem.init(title: "Delete", action: Selector(("delete")))]
        
        // refreshControl
        self.collectionView.alwaysBounceVertical = true;
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(loadMore), for: .valueChanged)
        self.collectionView?.addSubview(control)
        self.refreshControl = control
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // get messages
        MessagesManager.manager.firstTimeMessages(of: receiver!)
        view.layoutIfNeeded()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollToBottom(animated: true)
    }
    
    ///------------------
    
    var receiver : Contact?     // friend
    var friendImg : UIImage?    // friend image
    var profileIMG : UIImage?   // current user image
    
    func setup(receiver : Contact){
        self.receiver = receiver
        self.title = receiver.name
        
        // Get friend image
        ImageCache.default.retrieveImage(forKey: receiver.id, options: nil) {
            image, cacheType in
            if let image = image {
                self.friendImg = image
            }
        }
        
        // Get current user image
        ImageCache.default.retrieveImage(forKey: Constants.PROFILE_IMAGE, options: nil) {
            image, cacheType in
            if let image = image {
                self.profileIMG = image
            }
        }
    }
    
    // MARK: - Send new message
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        
        // Create the reference that the message will save at.
        // HERE BECAUSE WE NEED TO GET THE KEY OF THE MESSAGE
        let senderRef = DBManager.manager.messagesRef.child(senderId).child((receiver?.id)!).childByAutoId()
        
        // Create new message object
        let message = MSMessage(senderId: senderId, senderDisplayName: senderDisplayName,
                                date: Date(), text: text, receiverID: (receiver?.id)!, messageID: senderRef.key)
        
        // add to messages array
        messages.append(message)
        // update ui
        finishSendingMessage()
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        // update in server
        MessagesManager.manager.sendMessage(message: message, senderRef: senderRef)
    }
    
    
    // sending buttons functions
    override func didPressAccessoryButton(_ sender: UIButton!) {
        
        // Create the reference that the message will save at.
        // HERE BECAUSE WE NEED TO GET THE KEY OF THE MESSAGE
        let senderRef = DBManager.manager.messagesRef.child(self.senderId).child((self.receiver?.id)!).childByAutoId()
        
        // Create new message object
        // Actionsheet
        let sheet = MSActionSheet.instance
        sheet.showFullActionSheet(on: self) {
            if let image = sheet.getResizedImage(toSize: CGSize(width: 150, height: 150)){
                let data : Data = UIImageJPEGRepresentation(image, 0.5)!
                
                let url = URL(dataRepresentation: data, relativeTo: nil)
                
                let jsqMSG = JSQPhotoMediaItem(maskAsOutgoing: true)
                jsqMSG?.image = image
                
                let newMessage = MSMessage(senderId: self.senderId, displayName: self.senderDisplayName,
                                           media: jsqMSG!, date: Date(),
                                           receiverID: (self.receiver?.id)!, messageID: senderRef.key,
                                           mediaURL: url!, fileName: "")
                self.messages.append(newMessage)
                self.finishSendingMessage()
                
                MessagesManager.manager.sendMedia(message: newMessage, senderRef: senderRef, image: data, video: nil)
            }else if let videoURL = sheet.getVideoURL(){
                
                let video = JSQVideoMediaItem(maskAsOutgoing: true)
                video?.fileURL = videoURL
                video?.isReadyToPlay = true
                let newMessage = MSMessage(senderId: self.senderId, displayName: self.senderDisplayName,
                                           media: video!, date: Date(),
                                           receiverID: (self.receiver?.id)!, messageID: senderRef.key,
                                           mediaURL: videoURL, fileName: "")
                self.messages.append(newMessage)
                self.finishSendingMessage()
                
                MessagesManager.manager.sendMedia(message: newMessage, senderRef: senderRef, image: nil, video: videoURL)
            }
        }
    }
    
    // MARK: - Message Delegation function
    func messageReceived(message: MSMessage, fromNode : Bool) {
        
        for msg in messages{
            if msg.messageID == message.messageID{
                return
            }
        }
        messages.append(message)
        self.finishReceivingMessage()
    }
    
    func mediaReceived(message: MSMessage) {
        
        for msg in messages{
            if msg.messageID == message.messageID{
                return
            }
        }
        
        //  ReceivingMessage()
        self.messages.append(message)
        self.finishReceivingMessage()
    }
    
    
    func errorOccurred(description: String) {
        self.alert( message: description)
    }
    
    /// COLLECTION VIEW FUNCTIONS
    
    // MARK: - Did tap at bubble
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAt indexPath: IndexPath!) {
        // current message
        let msg = messages[indexPath.item]
        
        // check if video / image
        if msg.isMediaMessage{
            if let media = msg.media as? JSQVideoMediaItem{
                let player = AVPlayer(url: media.fileURL)
                let playerController = AVPlayerViewController()
                playerController.player = player
                self.present(playerController, animated: true, completion: nil)
            }else if let image = msg.media as? JSQPhotoMediaItem{
                // store image reference, segue to ImageVC
                self.selectedImage = image.image
                self.performSegue(withIdentifier: Constants.SHOW_IMAGE_SEGUE, sender: indexPath)
            }
        }
    }
    
    
    // MARK: - Bubble color & direction
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let factory = JSQMessagesBubbleImageFactory()
        // get current message
        let message = messages[indexPath.item]
        
        // if current user is the sender
        if message.senderId == self.senderId{
            return factory?.outgoingMessagesBubbleImage(with: UIColor(rgb: 0x24d549))
        }else{
            return factory?.incomingMessagesBubbleImage(with: UIColor(rgb: 0xe5e5ea))
        }
    }
    
    
    // MARK: - Prepare for segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.SHOW_IMAGE_SEGUE {
            if let destination = segue.destination as? ImageVC,
                let indexPath = sender as? IndexPath,
                let img = self.selectedImage{
                destination.setup(image: img, message: messages[indexPath.item])
            }
        }
    }
    
    // MARK: - Avatar image for item
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        // get current message
        let message = messages[indexPath.item]
        var image : UIImage? = nil
        
        // if the friend send the message, set his image
        if message.senderId == receiver?.id{
            image = friendImg
        }else{ // current user image
            image = profileIMG
        }
        // if one of the users have no avatar, default will set
        return JSQMessagesAvatarImageFactory.avatarImage(with: image ?? #imageLiteral(resourceName: "image_avatar"), diameter: 30)
    }
    
    // MARK: - Message data for item
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    // MARK: - Number of items in section
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    // MARK: - Cell for item at
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        
        let message = messages[indexPath.item]
        
        // Current user white, friend black
        cell.textView?.textColor = message.senderId == senderId ? .white : .black
        
        // DISABLE ANNOYING SELECTING OF TEXT
        if cell.textView != nil{
            cell.textView.isSelectable = false
        }
        return cell
    }
    
    
    // MARK: - Perform action
    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
        
        // get the message
        let message = messages[indexPath.item]
        
        func removeMessage(){
            // delete from Firebase
            MessagesManager.manager.remove(message: message)
            // remove from array
            messages.remove(at: indexPath.item)
            // update collection view
            collectionView.deleteItems(at: [indexPath])
            collectionView.reloadData()
        }
        
        func copyMessage(){
            // If trying to copy media
            if let _ = message.mediaURL{
                return
            }
            UIPasteboard.general.string = messages[indexPath.item].text
            
        }
        
        switch action {
        case #selector(copy(_:)) : copyMessage()
        case #selector(delete(_:)) : removeMessage()
        default:  return
        }
        
    }
    
    // For showing menu (delete, copy)
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    
    // Top label text for cell
    override func collectionView(_ collectionView: JSQMessagesCollectionView, attributedTextForCellTopLabelAt indexPath: IndexPath) -> NSAttributedString? {
        
        //Show a timestamp for every 5rd message
        if (indexPath.item % 5 == 0) {
            let message = self.messages[indexPath.item]
            return JSQMessagesTimestampFormatter.shared().attributedTimestamp(for: message.date)
        }
        return nil
    }
    
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath) -> NSAttributedString? {
        let message = messages[indexPath.item]
        
        // Displaying names above messages
        //Mark: Removing Sender Display Name
        /**
         Example on showing or removing senderDisplayName based on user settings.
         This logic should be consistent with what you return from `heightForCellTopLabelAtIndexPath:`
         
         if defaults.bool(forKey: Setting.removeSenderDisplayName.rawValue) {
         return nil
         }
         
         if message.senderId == self.senderId() {
         return nil
         }   */
        
        return NSAttributedString(string: message.senderDisplayName)
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout, heightForCellTopLabelAt indexPath: IndexPath) -> CGFloat {
        /**
         *  Each label in a cell has a `height` delegate method that corresponds to its text dataSource method
         */
        
        /**
         *  This logic should be consistent with what you return from `attributedTextForCellTopLabelAtIndexPath:`
         *  The other label height delegate methods should follow similarly
         *
         *  Show a timestamp for every 5rd message
         */
        if indexPath.item % 5 == 0 {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        
        return 0.0
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout, heightForMessageBubbleTopLabelAt indexPath: IndexPath) -> CGFloat {
        
        /**
         *  Example on showing or removing senderDisplayName based on user settings.
         *  This logic should be consistent with what you return from `attributedTextForCellTopLabelAtIndexPath:`
         
         if defaults.bool(forKey: Setting.removeSenderDisplayName.rawValue) {
         return 0.0
         }*/
        
        let currentMessage = self.messages[indexPath.item]
        /*
         if currentMessage.senderId == self.senderId() {
         return 0.0
         }
         */
        if indexPath.item - 1 > 0 {
            let previousMessage = self.messages[indexPath.item - 1]
            if previousMessage.senderId == currentMessage.senderId {
                return 0.0
            }
        }
        
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    
    
    // MARK : - Fetch / Load more messages
    func loadMore(){
        
        // check if there is no messages
        guard let _ = messages.first?.date else {
            self.refreshControl?.endRefreshing()
            return
        }
        
        MessagesManager.manager.fetchMore(of: receiver!, currentMessages : messages){ (history) in
            
            //Check if nil
            if history != nil && !(history?.isEmpty)! {
                
                //Convert the messages in modelbridge
                var tempMessages = [MSMessage]()
                for historyMSG in history!.reversed(){
                    tempMessages.append(historyMSG)
                }
                
                // No new messages/duplicates
                if tempMessages.isEmpty{
                    // Stop spinner
                    self.refreshControl?.endRefreshing()
                    self.finishReceivingMessage()
                    return
                }
                
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                let oldBottomOffset = self.collectionView.contentSize.height - self.collectionView.contentOffset.y
                self.collectionView.performBatchUpdates({
                    
                    // indexPaths for earlier messages
                    let lastIdx = tempMessages.count - 1
                    var indexPaths: [AnyObject] = []
                    for i in 0 ... lastIdx {
                        indexPaths.append(IndexPath(item: i, section: 0) as AnyObject)
                    }
                    
                    // insert messages and update data source.
                    for message in tempMessages {
                        self.messages.insert(message, at: 0)
                    }
                    self.collectionView.insertItems(at: indexPaths as! [IndexPath])
                    
                    // invalidate layout
                    self.collectionView.collectionViewLayout.invalidateLayout(with: JSQMessagesCollectionViewFlowLayoutInvalidationContext())
                    
                }, completion: {(finished) in
                    
                    //scroll back to current position
                    self.finishReceivingMessage(animated: true)
                    self.collectionView.layoutIfNeeded()
                    self.collectionView.contentOffset = CGPoint(x: 0, y: self.collectionView.contentSize.height - oldBottomOffset)
                    
                    // Stop spinner
                    self.refreshControl?.endRefreshing()
                    self.finishReceivingMessage()

                    CATransaction.commit()
                })
            } else {
                // Stop spinner, no more messages
                self.refreshControl?.endRefreshing()
            }
        }
    }
}
