//
//  SettingsVC.swift
//  Chat
//
//  Created by Maor Shams on 11/04/2017.
//  Copyright © 2017 Maor Shams. All rights reserved.
//

import UIKit

class SettingsVC:  UITableViewController{
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userStatusLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // corner radius
        profileImageView.layer.cornerRadius = (profileImageView.frame.width) / 2
        profileImageView.clipsToBounds = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // get & set user profile image
        DBManager.manager.getProfileImage(fromCache: true){ [weak self] (image : UIImage) in
            self?.profileImageView.image = image
        }
        
        // set user name
        self.userNameLabel.text = AuthManager.User.name.value
        
        // set user status
        DBManager.manager.getUserStatus(){ [weak self] (status : String) in
            self?.userStatusLabel.text = status
        }
    }
}
