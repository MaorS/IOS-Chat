//
//  MessagesHandler.swift
//  Chat
//
//  Created by Maor Shams on 11/04/2017.
//  Copyright © 2017 Maor Shams. All rights reserved.
//

import UIKit
import FirebaseStorage
import FirebaseDatabase
import JSQMessagesViewController
import Kingfisher

protocol MessageReceivedDelegate : class{
    func mediaReceived(message : MSMessage)
    func messageReceived(message : MSMessage, fromNode : Bool)
    func errorOccurred(description : String)
}

class MessagesManager {
    
    // Initialization
    fileprivate static let _manager = MessagesManager()
    
    fileprivate init(){}
    
    static var manager : MessagesManager{
        return _manager
    }
    weak var delegate : MessageReceivedDelegate?
    
    // MARK: - Send new Message
    func sendMessage(message : MSMessage, senderRef : FIRDatabaseReference,url : String? = nil, fileName : String? = nil){
        DispatchQueue.global().async {
            
            // save reference to get the key of message!
            let receiverRef = DBManager.manager.messagesRef.child(message.receiverID).child(message.senderId).child(senderRef.key)
            
            // build new message dictionary
            let data : Dictionary<String,Any> = [
                Constants.SENDER_ID : message.senderId,
                Constants.SENDER_NAME : message.senderDisplayName,
                Constants.SENDER_TEXT : message.text ?? "",
                Constants.SENT_DATE : Int(message.date.timeIntervalSince1970),
                Constants.RECEIVER_ID : message.receiverID,
                Constants.MEDIA_URL : url ?? "",
                Constants.FILE_NAME : fileName ?? "",
                Constants.MESSAGE_ID : senderRef.key
            ]
            
            // save in Firebase
            senderRef.setValue(data)
            receiverRef.setValue(data)
        }
    }
    // MARK: - Send media message
    func sendMedia(message : MSMessage, senderRef : FIRDatabaseReference,image : Data?, video : URL? ){
        
        if image != nil{
            
            let uniqeID : String = "\(NSUUID().uuidString).jpg"
            
            // save photo in firebase storage
            DBManager.manager.imageStorageRef.child(Constants.USERS_IMAGES_STORAGE)
                .child(message.senderId).child(uniqeID)
                .put(image!, metadata: nil){
                    (metadata : FIRStorageMetadata?, err : Error?) in
                    // problem with upload image
                    if err != nil{ // Error occurred, infrom the user
                        self.delegate?.errorOccurred(description: (err?.localizedDescription)!)
                    }else{// send link to photo in user messages
                        let url = String(describing: metadata!.downloadURL()!)
                        self.sendMessage(message: message, senderRef: senderRef, url : url, fileName : uniqeID)
                    }
            }// dbmanager
        }else{
            let uniqeID : String = NSUUID().uuidString
            
            // save video in firebase storage
            DBManager.manager.videoStorageRef.child(Constants.USERS_VIDEOS_STORAGE)
                .child(message.senderId).child(uniqeID).putFile(video!, metadata : nil ){
                    (metadata : FIRStorageMetadata?, err : Error?) in
                    // problem with upload video
                    if err != nil{ // Error occurred, infrom the user
                        self.delegate?.errorOccurred(description: (err?.localizedDescription)!)
                    }else{// send link to video in user messages
                        let url = String(describing: metadata!.downloadURL()!)
                        self.sendMessage(message: message, senderRef: senderRef, url : url, fileName : uniqeID)
                    }
            }
        }
    }
    
    // Just entered the chat, get 5 last messages
    func firstTimeMessages(of friend : Contact ){
        
        // current user
        let currentUser = AuthManager.User.self

        DispatchQueue.global().async {

            // get 5 last messages
            DBManager.manager.messagesRef.child(currentUser.id.value).child(friend.id)
                .queryLimited(toLast: 5).observeSingleEvent(of: .value, with: { (snapshot) in
                  
                    for child in (snapshot.children)  {
                        let snap = child as! FIRDataSnapshot    // each child is a snapshot
                        self.observeHandler(snapshot: snap)
                    }
                    // when finish observing first messages, start observing 
                    // only to new messages sent
                     self.observeMessages(of: friend)
                })
        }
    }
    
    
    // MARK: - Observe messages
    func observeMessages(of friend : Contact){
        
        DispatchQueue.global().async {
            let currentUser = AuthManager.User.self
            
            // listen for A new child node added.
            DBManager.manager.messagesRef.child(currentUser.id.value).child(friend.id)
                .queryLimited(toLast: 1).queryOrdered(byChild: Constants.SENDER_ID)
                .queryEqual(toValue: friend.id).observe(.childAdded){[weak self] (snapshot : FIRDataSnapshot) in
                    
                    self?.observeHandler(snapshot: snapshot)
            }
        }
    }
    
    // MARK : - Observe Handler
    func observeHandler(snapshot : FIRDataSnapshot) {
        guard let data = snapshot.value as? NSDictionary else{
            return
        }
        
        // check if there is data
        guard let senderID = data[Constants.SENDER_ID] as? String,
            let senderName = data[Constants.SENDER_NAME] as? String,
            let sentDate = data[Constants.SENT_DATE] as? Int,
            let text = data[Constants.SENDER_TEXT] as? String,
            let receiverID = data[Constants.RECEIVER_ID] as? String,
            let fileURL = data[Constants.MEDIA_URL] as? String ,
            let fileName = data[Constants.FILE_NAME] as? String,
            let messageID = data[Constants.MESSAGE_ID] as? String else{
                debugPrint("\(#function ) error return")
                return
        }
        
        if !text.isEmpty{ //Text message
            
            // create new message object
            let newMessage = MSMessage(senderId: senderID,
                                       senderDisplayName: senderName,
                                       date: self.millisToDate(sentDate), text: text,
                                       receiverID : receiverID,
                                       messageID: messageID)
            
            // notify caller
            self.delegate?.messageReceived(message : newMessage, fromNode: false)
            
        }else if !fileURL.isEmpty{ // Media message
            
            guard let mediaURL = URL(string: fileURL) else{
                return
            }
            
            // If the media is Image
            if self.isImage(fileURL){
                self.getImage(mediaURL,senderID,senderName,receiverID,sentDate,messageID, fileName: fileName)
            }else{ // Media is video
                self.getVideo(mediaURL,senderID,senderName,receiverID,sentDate,messageID, fileName: fileName)
            }
        }
    }
    
    // MARK: - Get video
    func getVideo(_ mediaURL : URL,_  senderID : String,_  senderName : String,_ receiverID : String,
                  _  sentDate : Int, _ messageID : String , fileName : String,completion: ((MSMessage)->())? = nil){
        
        DispatchQueue.global().sync {
            
            let video = JSQVideoMediaItem(maskAsOutgoing: senderID == AuthManager.User.id.value ? true : false)
            video?.fileURL = mediaURL
            video?.isReadyToPlay = true
            let newMessage = MSMessage(senderId: senderID,
                                       displayName: senderName,
                                       media: video!,
                                       date: (self.millisToDate(sentDate)),
                                       receiverID: receiverID,
                                       messageID: messageID,
                                       mediaURL : mediaURL,
                                       fileName : fileName)
            
            
            DispatchQueue.main.async {
                if completion != nil{
                    completion!(newMessage)
                }else{
                    self.delegate?.mediaReceived(message: newMessage)
                }
            }
        }
    }
    
    
    
    // MARK: - Get image
    func getImage(_ mediaURL : URL,_  senderID : String,_  senderName : String,_ receiverID : String,
                  _  sentDate : Int, _ messageID : String ,fileName : String,completion: ((MSMessage)->())? = nil){
        
        DispatchQueue.global().async {
            ImageDownloader.default.downloadImage(with: mediaURL, options: [], progressBlock: nil) {
                [weak self] (image, error, url, data) in
                
                let image = JSQPhotoMediaItem(image: image)!
                
                // Apply an outgoing or incoming bubble
                image.appliesMediaViewMaskAsOutgoing = senderID == AuthManager.User.id.value ? true : false
                
                let newMessage = MSMessage(senderId: senderID,
                                           displayName: senderName,
                                           media: image,
                                           date: (self?.millisToDate(sentDate))!,
                                           receiverID: receiverID,
                                           messageID: messageID,
                                           mediaURL : mediaURL,
                                           fileName : fileName)
                
                if completion != nil{
                    completion!(newMessage)
                    
                }else{
                    self?.delegate?.mediaReceived(message: newMessage)
                    
                }
                
            }
        }
    }
    
    // MARK: - Fetch more messages (old messages)
    func fetchMore(of friend : Contact,currentMessages : [MSMessage],fetchMoreCounter : Int, history completion : @escaping ((_ : [MSMessage]?) -> Void )){
        
        let currentUser = AuthManager.User.self
        let firstMessage = currentMessages.first?.date ?? Date()
        
        
        // listen for a single event, get the messages from yesterday until the first
        // message in current device
        
        DispatchQueue.global().sync {
            DBManager.manager.messagesRef.child(currentUser.id.value).child(friend.id)
                .queryOrdered(byChild: Constants.SENT_DATE).queryLimited(toLast: 5)
                .queryEnding(atValue: Int(firstMessage.timeIntervalSince1970))
                .observeSingleEvent(of: .value, with: { (snapshot) in
                    
                    var historyMSGS = [MSMessage]()
                    
                    snapshotLoop : for child in (snapshot.children)  {
                        
                        let snap = child as! FIRDataSnapshot    // each child is a snapshot
                        let data = snap.value as! [String: Any] // the value is a dict
                        
                        
                        guard let messageID = data[Constants.MESSAGE_ID] as? String else{
                            continue snapshotLoop
                        }
                        
                        // If current messages contains one of new messages continue
                        currentMessagesLoop : for currentMessage in currentMessages{
                            if messageID == currentMessage.messageID{
                                continue snapshotLoop
                            }
                        }
                        
                        
                        // check if there is data
                        guard let senderID = data[Constants.SENDER_ID] as? String,
                            let senderName = data[Constants.SENDER_NAME] as? String,
                            let text = data[Constants.SENDER_TEXT] as? String,
                            let receiverID = data[Constants.RECEIVER_ID] as? String,
                            let fileURL = data[Constants.MEDIA_URL] as? String ,
                            let sentDate = data[Constants.SENT_DATE] as? Int,
                            let fileName = data[Constants.FILE_NAME] as? String else{
                                debugPrint("\(#function ) error return")
                                continue
                        }
                        
                        if !text.isEmpty{ // Text message
                            
                            // create new message object
                            let newMessage = MSMessage(senderId: senderID,
                                                       senderDisplayName: senderName,
                                                       date: self.millisToDate(sentDate), text: text,
                                                       receiverID : receiverID,
                                                       messageID: messageID)
                            
                            historyMSGS.append(newMessage)
                            
                        }else if !fileURL.isEmpty{ // Media message
                            
                            guard let mediaURL = URL(string: fileURL) else{
                                return
                            }
                            
                            // If the media is Image
                            if self.isImage(fileURL){
                                
                                self.getImage(mediaURL,senderID,senderName,receiverID,sentDate,messageID, fileName: fileName){ (newMessage) in
                                    historyMSGS = [MSMessage]()
                                    historyMSGS.append(newMessage)
                                    completion(historyMSGS)
                                }
                                
                                // Media is video
                            }else{
                                
                                self.getVideo(mediaURL,senderID,senderName,receiverID,sentDate,messageID, fileName: fileName){(newMessage) in
                                    historyMSGS = [MSMessage]()
                                    historyMSGS.append(newMessage)
                                    completion(historyMSGS)
                                }
                            }
                        }
                        
                    }
                    
                    completion(historyMSGS)
                    
                }) { (error) in // Notify user
                    self.delegate?.errorOccurred(description: error.localizedDescription)
            }
        }
    }
    
    
    
    // MARK: - Delete message
    func remove(message : MSMessage){
        DispatchQueue.global().async { [weak self] in
            
            // current user id
            let connectedUserID = AuthManager.User.id.value
            // which path to delete from (currentuser -> refer -> message)
            let refer : String = message.senderId == connectedUserID ? message.receiverID : message.senderId
            
            // Delete message from CURRENT USER path
            DBManager.manager.messagesRef.child(connectedUserID).child(refer).child(message.messageID).removeValue()
            
            // if the message is media
            if let _ = message.mediaURL {
                
                // Check if friend have this image
                DBManager.manager.messagesRef.child(refer).child(connectedUserID).child(message.messageID).observeSingleEvent(of: .value, with : { (snapshot) in
                    if let _ = snapshot.value as? NSDictionary{
                        // Your friend have this image
                    }else{      // Media is image
                        if (self?.isImage(message.fileName!))!{
                            DBManager.manager.imageStorageRef.child(Constants.USERS_IMAGES_STORAGE).child(message.senderId)
                                .child(message.fileName!).delete(completion: nil)
                        }else{  // Media is video
                            DBManager.manager.videoStorageRef.child(Constants.USERS_VIDEOS_STORAGE).child(message.senderId)
                                .child(message.fileName!).delete(completion: nil)
                        }
                    }
                })
            }
        }
    }
    
    // Convert millis To Date
    func millisToDate(_ currentMillis : Int) -> Date {
        return Date(timeIntervalSince1970: Double(currentMillis))
    }
    
    func isImage(_ str : String) -> Bool{
        return str.contains(".jpg") ? true : false
    }
}// class







