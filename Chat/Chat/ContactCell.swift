//
//  ContactCell.swift
//  Chat
//
//  Created by Maor Shams on 12/04/2017.
//  Copyright © 2017 Maor Shams. All rights reserved.
//

import UIKit
import Kingfisher

class ContactCell: UITableViewCell {
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userStatus: UILabel!
    
    func configure(with contact : Contact){
        // set labels
        userNameLabel.text = contact.name
        userStatus.text = contact.status
        
        // corner radius
        profileImageView.layer.cornerRadius = (profileImageView.frame.width) / 2
        profileImageView.clipsToBounds = true
        
        // if contact heve no picture
        if contact.imageURL.isEmpty{
            profileImageView.image = #imageLiteral(resourceName: "image_avatar")
        }else if let url = URL(string: contact.imageURL){
            // Download and save in cache, the key is the id
            let resource = ImageResource(downloadURL: url, cacheKey: contact.id)
            profileImageView.kf.setImage(with: resource)
        }
    }
}
