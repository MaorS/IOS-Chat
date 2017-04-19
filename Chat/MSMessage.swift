//
//  MMessage.swift
//  Chat
//
//  Created by Maor Shams on 12/04/2017.
//  Copyright © 2017 Maor Shams. All rights reserved.
//

import UIKit
import JSQMessagesViewController

class MSMessage : JSQMessage {
    
    
    var messageID : String
    var receiverID : String
    var mediaURL : URL? = nil
    var fileName : String? = nil
    
    // new TEXT MESSAGES init with messageID
    init(senderId: String!, senderDisplayName: String!, date: Date!, text: String!,receiverID : String, messageID : String) {
        
        self.messageID = messageID
        self.receiverID = receiverID
        
        super.init(senderId: senderId, senderDisplayName: senderDisplayName, date: date, text: text)
    }
    
    
    // new MEDIA init with messageID
    
    init(senderId: String, displayName: String, media: JSQMessageMediaData,
         date: Date, receiverID : String, messageID : String,  mediaURL : URL,
         fileName : String) {
        
        self.messageID = messageID
        self.receiverID = receiverID
        self.mediaURL = mediaURL
        self.fileName = fileName
        
        super.init(senderId: senderId, senderDisplayName: displayName, date: date, media: media)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
