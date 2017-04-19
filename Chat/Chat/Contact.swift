//
//  Contact.swift
//  Chat
//
//  Created by Maor Shams on 09/04/2017.
//  Copyright © 2017 Maor Shams. All rights reserved.
//

import Foundation
class Contact{
    
    let name : String
    let id : String
    let email : String
    let imageURL : String
    let status : String
    
    init(id : String, email : String, name : String, imageURL : String, status : String) {
        self.name = name
        self.email = email
        self.id = id
        self.imageURL = imageURL
        self.status = status
    }
    
    
}
